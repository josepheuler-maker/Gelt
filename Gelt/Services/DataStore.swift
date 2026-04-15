import Combine
import Foundation
import SwiftUI

// ═══════════════════════════════════════════════════
//  GELT — Data Store (JSON file + optional server)
// ═══════════════════════════════════════════════════

@MainActor
class DataStore: ObservableObject {
    @Published var data: GeltData
    
    private let fileURL: URL
    private var saveTask: Task<Void, Never>?
    
    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent("gelt.json")
        
        if let loaded = Self.load(from: dir.appendingPathComponent("gelt.json")) {
            self.data = loaded
        } else {
            self.data = .default
        }
    }
    
    // ─── Persistence ────────────────────────────────
    private static func load(from url: URL) -> GeltData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(GeltData.self, from: data)
    }
    
    func save() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            guard let jsonData = try? encoder.encode(data) else { return }
            try? jsonData.write(to: fileURL, options: .atomic)
            
            // Optional server sync
            if let serverURL = data.settings.serverURL, !serverURL.isEmpty {
                await syncToServer(jsonData, url: serverURL)
            }
        }
    }
    
    private func syncToServer(_ jsonData: Data, url: String) async {
        guard let url = URL(string: "\(url)/api/data") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 5
        _ = try? await URLSession.shared.data(for: request)
    }
    
    // ─── Computed Properties ────────────────────────
    var viewMonth: String { monthKeyFor(Date()) }
    
    func transactions(for monthKey: String) -> [Transaction] {
        data.transactions.filter { $0.date.monthKey == monthKey }
    }
    
    func spending(for monthKey: String) -> [Transaction] {
        transactions(for: monthKey).filter { $0.category != "Income" }
    }
    
    func income(for monthKey: String) -> [Transaction] {
        transactions(for: monthKey).filter { $0.category == "Income" }
    }
    
    var totalBudget: Double {
        data.categories.filter { $0.name != "Income" }.reduce(0) { $0 + $1.limit }
    }
    
    func spentByCategory(for monthKey: String) -> [String: Double] {
        var result: [String: Double] = [:]
        for tx in spending(for: monthKey) {
            result[tx.category, default: 0] += tx.amount
        }
        return result
    }
    
    var totalSavings: Double {
        data.accounts.reduce(0) { $0 + $1.balance }
    }
    
    var totalLoanRemaining: Double {
        data.loans.reduce(0) { $0 + $1.remaining }
    }
    
    var totalLoanPrincipal: Double {
        data.loans.reduce(0) { $0 + $1.principal }
    }
    
    var totalInterestPaid: Double {
        data.loans.reduce(0) { $0 + $1.interestPaid }
    }
    
    var netWorth: Double {
        data.settings.primaryBalance + totalSavings - totalLoanRemaining
    }
    
    var weightedAPR: Double {
        guard totalLoanRemaining > 0 else { return 0 }
        return data.loans.reduce(0) { $0 + ($1.apr * ($1.remaining / totalLoanRemaining)) }
    }
    
    var liquidSavings: Double {
        data.settings.primaryBalance + data.accounts.filter { $0.type != .trip }.reduce(0) { $0 + $1.balance }
    }
    
    var billsDueSoon: [RecurringItem] {
        data.recurring.filter { !$0.isIncome && $0.daysUntil >= 0 && $0.daysUntil <= 7 }
            .sorted { $0.daysUntil < $1.daysUntil }
    }
    
    func weeklySpending() -> [(label: String, amount: Double)] {
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
        
        return (0..<7).reversed().map { daysAgo in
            let d = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
            let ds = f.string(from: d)
            let spent = data.transactions
                .filter { $0.date == ds && $0.category != "Income" }
                .reduce(0) { $0 + $1.amount }
            let weekday = cal.component(.weekday, from: d) - 1
            return (dayNames[weekday], spent)
        }
    }
    
    func outlookEvents() -> [(date: String, item: RecurringItem)] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let end = f.string(from: Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
        
        var events: [(String, RecurringItem)] = []
        for rec in data.recurring {
            for d in occurrences(of: rec, until: end) {
                events.append((d, rec))
            }
        }
        return events.sorted { $0.0 < $1.0 }
    }
    
    func coverageMonths() -> Double {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let end = f.string(from: Calendar.current.date(byAdding: .day, value: 92, to: Date())!)
        
        var exp3: Double = 0
        for rec in data.recurring {
            let n = occurrences(of: rec, until: end).count
            if !rec.isIncome { exp3 += rec.amount * Double(n) }
        }
        guard exp3 > 0 else { return 0 }
        return liquidSavings / (exp3 / 3)
    }
    
    // ─── Actions ────────────────────────────────────
    func addTransaction(date: String, note: String, category: String, amount: Double) {
        let match = BrandDetector.detectWithMerchants(note, merchants: data.merchants)
        let cat = category.isEmpty ? (match?.category ?? "Misc") : category
        let icon = match?.icon ?? categoryIcon(cat)
        
        let tx = Transaction(date: date, note: note, category: cat, amount: amount, icon: icon)
        data.transactions.append(tx)
        Haptics.success()
        save()
    }
    
    func deleteTransaction(_ id: UUID) {
        data.transactions.removeAll { $0.id == id }
        save()
    }
    
    func addRecurring(_ item: RecurringItem) {
        data.recurring.append(item)
        save()
    }
    
    func deleteRecurring(_ id: UUID) {
        data.recurring.removeAll { $0.id == id }
        save()
    }
    
    func markPaid(_ rec: RecurringItem) {
        // Create transaction
        let tx = Transaction(
            date: rec.nextDate, note: rec.name,
            category: rec.category.isEmpty ? (rec.isIncome ? "Income" : "Misc") : rec.category,
            amount: rec.amount, icon: rec.icon
        )
        data.transactions.append(tx)
        
        // Adjust balance
        data.settings.primaryBalance += rec.isIncome ? rec.amount : -rec.amount
        
        // Advance date
        if let idx = data.recurring.firstIndex(where: { $0.id == rec.id }) {
            data.recurring[idx].nextDate = advanceDate(rec.nextDate, by: rec.frequency)
        }
        Haptics.success()
        save()
    }
    
    func addAccount(_ account: Account) {
        data.accounts.append(account)
        save()
    }
    
    func updateAccountBalance(_ id: UUID, balance: Double) {
        if let idx = data.accounts.firstIndex(where: { $0.id == id }) {
            data.accounts[idx].balance = balance
            save()
        }
    }
    
    func deleteAccount(_ id: UUID) {
        data.accounts.removeAll { $0.id == id }
        save()
    }
    
    func addLoan(_ loan: Loan) {
        data.loans.append(loan)
        save()
    }
    
    func makeLoanPayment(_ id: UUID) {
        if let idx = data.loans.firstIndex(where: { $0.id == id }) {
            let interest = data.loans[idx].nextInterest
            let principal = data.loans[idx].monthlyPayment - interest
            data.loans[idx].remaining = max(0, data.loans[idx].remaining - principal)
            data.loans[idx].interestPaid += interest
            Haptics.tap()
            save()
        }
    }
    
    func deleteLoan(_ id: UUID) {
        data.loans.removeAll { $0.id == id }
        Haptics.selection()
        save()
    }
    
    func updateBalance(_ amount: Double) {
        data.settings.primaryBalance = amount
        save()
    }
    
    func categoryIcon(_ name: String) -> String {
        data.categories.first { $0.name == name }?.icon ?? "•"
    }
}
