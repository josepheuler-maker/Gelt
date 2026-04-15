import Foundation

// ═══════════════════════════════════════════════════
//  GELT — Data Models
// ═══════════════════════════════════════════════════

struct GeltData: Codable {
    var settings: Settings
    var categories: [Category]
    var merchants: [Merchant]
    var transactions: [Transaction]
    var recurring: [RecurringItem]
    var accounts: [Account]
    var loans: [Loan]
    var monthlySummaries: [MonthlySummary]
    
    static let `default` = GeltData(
        settings: Settings(),
        categories: Category.defaults,
        merchants: Merchant.defaults,
        transactions: [],
        recurring: [],
        accounts: [
            Account(name: "Trip Fund", type: .trip, balance: 0, icon: "✈️"),
            Account(name: "Emergency", type: .savings, balance: 0, icon: "🛟"),
        ],
        loans: [],
        monthlySummaries: []
    )
}

struct Settings: Codable {
    var primaryBalance: Double = 0
    var surplusCarryover: Double = 0
    var serverURL: String?
}

struct Category: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var limit: Double
    var icon: String
    
    static let defaults: [Category] = [
        .init(name: "Groceries", limit: 400, icon: "🛒"),
        .init(name: "Dining", limit: 200, icon: "🍽️"),
        .init(name: "Gas", limit: 150, icon: "⛽"),
        .init(name: "Rent", limit: 0, icon: "🏠"),
        .init(name: "Utilities", limit: 150, icon: "💡"),
        .init(name: "Phone", limit: 80, icon: "📱"),
        .init(name: "Internet", limit: 70, icon: "🌐"),
        .init(name: "Entertainment", limit: 100, icon: "🎬"),
        .init(name: "Shopping", limit: 150, icon: "🛍️"),
        .init(name: "Health", limit: 100, icon: "🏥"),
        .init(name: "Auto", limit: 100, icon: "🚗"),
        .init(name: "Income", limit: 0, icon: "💰"),
        .init(name: "Misc", limit: 100, icon: "💸"),
    ]
}

struct Merchant: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var category: String
    
    static let defaults: [Merchant] = [
        .init(name: "St. Regis Deer Valley", icon: "🏨", category: "Income"),
        .init(name: "Murray City", icon: "🏛️", category: "Income"),
        .init(name: "Smith's", icon: "🛒", category: "Groceries"),
        .init(name: "Costco", icon: "📦", category: "Groceries"),
        .init(name: "Maverik", icon: "⛽", category: "Gas"),
        .init(name: "Netflix", icon: "📺", category: "Entertainment"),
        .init(name: "Spotify", icon: "🎵", category: "Entertainment"),
        .init(name: "Amazon", icon: "📦", category: "Shopping"),
        .init(name: "Starbucks", icon: "☕", category: "Dining"),
    ]
}

struct Transaction: Codable, Identifiable {
    var id = UUID()
    var date: String // YYYY-MM-DD
    var note: String
    var category: String
    var amount: Double
    var icon: String
    
    var dateObj: Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: date) ?? Date()
    }
}

struct RecurringItem: Codable, Identifiable {
    var id = UUID()
    var icon: String
    var name: String
    var amount: Double
    var isIncome: Bool
    var frequency: Frequency
    var nextDate: String // YYYY-MM-DD
    var category: String
    
    var daysUntil: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: nextDate) else { return 999 }
        return Calendar.current.dateComponents([.day], from: today, to: d).day ?? 999
    }
}

enum Frequency: String, Codable, CaseIterable {
    case weekly, biweekly, monthly, yearly
}

struct Account: Codable, Identifiable {
    var id = UUID()
    var name: String
    var type: AccountType
    var balance: Double
    var icon: String
}

enum AccountType: String, Codable, CaseIterable {
    case savings, checking, trip, emergency
}

struct Loan: Codable, Identifiable {
    var id = UUID()
    var icon: String
    var name: String
    var principal: Double
    var remaining: Double
    var monthlyPayment: Double
    var apr: Double
    var interestPaid: Double = 0
    
    var progressPercent: Double {
        guard principal > 0 else { return 0 }
        return ((principal - remaining) / principal) * 100
    }
    
    var monthsRemaining: Int {
        guard monthlyPayment > 0, remaining > 0 else { return 0 }
        let r = apr / 100 / 12
        if r == 0 { return Int(ceil(remaining / monthlyPayment)) }
        guard let n = Optional(-log(1 - (r * remaining) / monthlyPayment) / log(1 + r)) else { return 999 }
        return n.isFinite ? Int(ceil(n)) : 999
    }
    
    var nextInterest: Double {
        remaining * (apr / 100 / 12)
    }
    
    var nextPrincipal: Double {
        monthlyPayment - nextInterest
    }
}

struct MonthlySummary: Codable, Identifiable {
    var id = UUID()
    var monthKey: String
    var closed: Date
    var spent: Double
    var income: Double
    var surplus: Double
    var savedAmount: Double
    var carriedAmount: Double
    var grade: String
}

// ─── Date Helpers ───────────────────────────────────
extension String {
    var monthKey: String {
        String(prefix(7)) // "2026-04"
    }
}

func todayString() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
}

func advanceDate(_ dateStr: String, by freq: Frequency) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    guard var d = f.date(from: dateStr) else { return dateStr }
    let cal = Calendar.current
    switch freq {
    case .weekly: d = cal.date(byAdding: .day, value: 7, to: d) ?? d
    case .biweekly: d = cal.date(byAdding: .day, value: 14, to: d) ?? d
    case .monthly: d = cal.date(byAdding: .month, value: 1, to: d) ?? d
    case .yearly: d = cal.date(byAdding: .year, value: 1, to: d) ?? d
    }
    return f.string(from: d)
}

func occurrences(of rec: RecurringItem, until endDate: String) -> [String] {
    var results: [String] = []
    var d = rec.nextDate
    while d <= endDate {
        results.append(d)
        d = advanceDate(d, by: rec.frequency)
    }
    return results
}

func monthLabel(for date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMMM yyyy"
    return f.string(from: date)
}

func monthKeyFor(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM"
    return f.string(from: date)
}

func shortMonthFor(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM"
    return f.string(from: date).uppercased()
}

func shortDateLabel(_ dateStr: String) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    guard let d = f.date(from: dateStr) else { return dateStr }
    let out = DateFormatter()
    out.dateFormat = "EEE, MMM d"
    return out.string(from: d)
}

func greeting() -> String {
    let h = Calendar.current.component(.hour, from: Date())
    if h < 12 { return "Good morning" }
    if h < 17 { return "Good afternoon" }
    return ["Shalom", "Good evening", "Welcome back"].randomElement()!
}
