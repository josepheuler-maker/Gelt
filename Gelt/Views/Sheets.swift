import SwiftUI

// ═══════════════════════════════════════════════════
//  GELT — Form Sheets
// ═══════════════════════════════════════════════════

// ─── Add Transaction ────────────────────────────────
struct AddTransactionSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var date = Date()
    @State private var note = ""
    @State private var category = "Groceries"
    @State private var amount = ""
    
    var body: some View {
        FormSheet(title: "New Transaction") {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(Theme.gold)
            GeltField("Description", text: $note, placeholder: "Where'd it go?")
            GeltPicker("Category", selection: $category, options: store.data.categories.map { ($0.name, "\($0.icon) \($0.name)") })
            GeltField("Amount", text: $amount, placeholder: "0.00", keyboard: .decimalPad)
            
            Button("Add") {
                guard let amt = Double(amount), amt > 0 else { return }
                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                Haptics.success()
                store.addTransaction(date: f.string(from: date), note: note, category: category, amount: amt)
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
        }
    }
}

// ─── Add Recurring ──────────────────────────────────
struct AddRecurringSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var icon = "🏠"
    @State private var name = ""
    @State private var amount = ""
    @State private var isIncome = false
    @State private var frequency: Frequency = .monthly
    @State private var nextDate = Date()
    @State private var category = "Misc"
    
    var body: some View {
        FormSheet(title: "Recurring") {
            HStack(spacing: 8) {
                GeltField("Icon", text: $icon, placeholder: "🏠").frame(width: 60)
                GeltField("Name", text: $name, placeholder: "Name")
            }
            GeltField("Amount", text: $amount, placeholder: "0.00", keyboard: .decimalPad)
            Toggle("Income", isOn: $isIncome).tint(Theme.gold)
            GeltPicker("Frequency", selection: $frequency, options: Frequency.allCases.map { ($0, $0.rawValue.capitalized) })
            DatePicker("Next Date", selection: $nextDate, displayedComponents: .date).tint(Theme.gold)
            GeltPicker("Category", selection: $category, options: store.data.categories.map { ($0.name, "\($0.icon) \($0.name)") })
            
            Button("Save") {
                guard let amt = Double(amount), !name.isEmpty else { return }
                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                Haptics.success()
                store.addRecurring(RecurringItem(icon: icon, name: name, amount: amt, isIncome: isIncome, frequency: frequency, nextDate: f.string(from: nextDate), category: category))
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
        }
    }
}

// ─── Add Account ────────────────────────────────────
struct AddAccountSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var icon = "💰"
    @State private var name = ""
    @State private var type: AccountType = .savings
    @State private var balance = ""
    
    var body: some View {
        FormSheet(title: "New Account") {
            HStack(spacing: 8) {
                GeltField("Icon", text: $icon, placeholder: "✈️").frame(width: 60)
                GeltField("Name", text: $name, placeholder: "Account name")
            }
            GeltPicker("Type", selection: $type, options: AccountType.allCases.map { ($0, $0.rawValue.capitalized) })
            GeltField("Balance", text: $balance, placeholder: "0.00", keyboard: .decimalPad)
            
            Button("Add") {
                guard !name.isEmpty else { return }
                Haptics.success()
                store.addAccount(Account(name: name, type: type, balance: Double(balance) ?? 0, icon: icon))
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
        }
    }
}

// ─── Add Loan ───────────────────────────────────────
struct AddLoanSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var icon = "💳"
    @State private var name = ""
    @State private var principal = ""
    @State private var remaining = ""
    @State private var payment = ""
    @State private var apr = ""
    
    var body: some View {
        FormSheet(title: "New Loan") {
            HStack(spacing: 8) {
                GeltField("Icon", text: $icon, placeholder: "📱").frame(width: 60)
                GeltField("Name", text: $name, placeholder: "e.g. iPhone, Honda")
            }
            GeltField("Original Amount", text: $principal, placeholder: "0.00", keyboard: .decimalPad)
            GeltField("Remaining", text: $remaining, placeholder: "0.00", keyboard: .decimalPad)
            GeltField("Monthly Payment", text: $payment, placeholder: "0.00", keyboard: .decimalPad)
            GeltField("APR %", text: $apr, placeholder: "0", keyboard: .decimalPad)
            
            Button("Add") {
                guard !name.isEmpty, let p = Double(principal), let r = Double(remaining), let mp = Double(payment) else { return }
                Haptics.success()
                store.addLoan(Loan(icon: icon, name: name, principal: p, remaining: r, monthlyPayment: mp, apr: Double(apr) ?? 0))
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
        }
    }
}

// ─── Add Category ───────────────────────────────────
struct AddCategorySheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var icon = "🛒"
    @State private var name = ""
    @State private var limit = ""
    
    var body: some View {
        FormSheet(title: "New Category") {
            HStack(spacing: 8) {
                GeltField("Icon", text: $icon, placeholder: "🛒").frame(width: 60)
                GeltField("Name", text: $name, placeholder: "Category name")
            }
            GeltField("Monthly Limit", text: $limit, placeholder: "0", keyboard: .decimalPad)
            
            Button("Add") {
                guard !name.isEmpty else { return }
                store.data.categories.append(Category(name: name, limit: Double(limit) ?? 0, icon: icon))
                store.save()
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
        }
    }
}

// ─── Add Merchant ───────────────────────────────────
struct AddMerchantSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var icon = "🏪"
    @State private var name = ""
    @State private var category = "Misc"
    
    var body: some View {
        FormSheet(title: "New Merchant") {
            HStack(spacing: 8) {
                GeltField("Icon", text: $icon, placeholder: "🏪").frame(width: 60)
                GeltField("Name", text: $name, placeholder: "Merchant name")
            }
            GeltPicker("Category", selection: $category, options: store.data.categories.map { ($0.name, "\($0.icon) \($0.name)") })
            
            Button("Add") {
                guard !name.isEmpty else { return }
                store.data.merchants.append(Merchant(name: name, icon: icon, category: category))
                store.save()
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
        }
    }
}

// ─── CSV Import ─────────────────────────────────────
struct CSVImportSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var csvText = ""
    @State private var result = ""
    
    var body: some View {
        FormSheet(title: "Import CSV") {
            Text("Paste your bank's CSV export. Auto-detects Date, Description, and Amount columns.")
                .font(.system(size: 12))
                .foregroundColor(Theme.dim)
            
            TextEditor(text: $csvText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Theme.cream)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .padding(10)
                .background(Theme.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))
            
            if !result.isEmpty {
                Text(result)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.gold)
            }
            
            Button("Import") { doImport() }
                .buttonStyle(GoldButtonStyle())
        }
    }
    
    private func doImport() {
        let lines = csvText.components(separatedBy: "\n").map { line in
            line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
        }
        guard lines.count >= 2 else { result = "No data found"; return }
        
        var dc = -1, dsc = -1, ac = -1
        for (i, h) in (lines.first ?? []).enumerated() {
            let hl = h.lowercased()
            if hl.contains("date") && dc < 0 { dc = i }
            else if (hl.contains("desc") || hl.contains("memo") || hl.contains("name")) && dsc < 0 { dsc = i }
            else if hl.contains("amount") && ac < 0 { ac = i }
        }
        guard dc >= 0, ac >= 0 else { result = "Can't detect columns"; return }
        if dsc < 0 { dsc = dc == 0 ? 1 : 0 }
        
        var added = 0
        let dateF = DateFormatter()
        
        for row in lines.dropFirst() {
            let maxIdx = max(dc, dsc, ac)
            guard row.count > maxIdx else { continue }
            
            let dateStr = row[dc]
            let desc = row[dsc]
            let amtStr = row[ac].replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
            guard let amt = Double(amtStr) else { continue }
            
            var parsedDate: String?
            for fmt in ["MM/dd/yyyy", "yyyy-MM-dd", "M/d/yyyy", "M/d/yy"] {
                dateF.dateFormat = fmt
                if let d = dateF.date(from: dateStr) {
                    dateF.dateFormat = "yyyy-MM-dd"
                    parsedDate = dateF.string(from: d)
                    break
                }
            }
            guard let date = parsedDate else { continue }
            
            store.addTransaction(date: date, note: desc, category: "", amount: abs(amt))
            added += 1
        }
        
        result = "\(added) transactions imported"
    }
}

// ─── Edit Balance Sheet ─────────────────────────────
struct EditBalanceSheet: View {
    let accountID: UUID?
    let initialBalance: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var balanceText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Update Balance")
                    .font(.custom("Cormorant Garamond", size: 24).weight(.bold))
                    .foregroundColor(Theme.cream)
                
                TextField("0.00", text: $balanceText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.gold)
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .background(Theme.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.gold.opacity(0.3), lineWidth: 1))
                
                Button("Save") {
                    Haptics.success()
                    onSave(balanceText)
                    dismiss()
                }
                .buttonStyle(GoldButtonStyle())
                
                Spacer()
            }
            .padding(24)
            .background(Theme.bg)
            .onAppear { balanceText = initialBalance }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.dim)
                }
            }
        }
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }
}

// ─── Set PIN Sheet ──────────────────────────────────
struct SetPINSheet: View {
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var pin = ""
    @State private var confirmPIN = ""
    @State private var step = 1
    @State private var error = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Text(step == 1 ? "Choose a 4-digit PIN" : "Confirm your PIN")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.cream)
                
                HStack(spacing: 14) {
                    let current = step == 1 ? pin : confirmPIN
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < current.count ? Theme.gold : Theme.cardBorder)
                            .frame(width: 14, height: 14)
                            .scaleEffect(i < current.count ? 1.1 : 1)
                            .animation(.spring(response: 0.2), value: current.count)
                    }
                }
                
                if !error.isEmpty {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.red)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(72), spacing: 16), count: 3), spacing: 12) {
                    ForEach(1...9, id: \.self) { num in
                        PINPadButton(label: "\(num)") { append("\(num)") }
                    }
                    PINPadButton(label: "", disabled: true) { }
                    PINPadButton(label: "0") { append("0") }
                    PINPadButton(label: "⌫", isDelete: true) { deleteLast() }
                }
                
                Spacer()
            }
            .padding(24)
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.dim)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func append(_ digit: String) {
        if step == 1 {
            guard pin.count < 4 else { return }
            pin += digit
            Haptics.selection()
            if pin.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { step = 2 }
            }
        } else {
            guard confirmPIN.count < 4 else { return }
            confirmPIN += digit
            Haptics.selection()
            if confirmPIN.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if confirmPIN == pin {
                        onSave(pin)
                    } else {
                        error = "PINs don't match"
                        Haptics.error()
                        confirmPIN = ""
                    }
                }
            }
        }
    }
    
    private func deleteLast() {
        if step == 1 && !pin.isEmpty { pin.removeLast() }
        else if step == 2 && !confirmPIN.isEmpty { confirmPIN.removeLast() }
    }
}

// ─── PIN Pad Button (shared by lock screen + set PIN) ─
struct PINPadButton: View {
    let label: String
    var isDelete: Bool = false
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: isDelete ? 18 : 24, weight: .medium))
                .foregroundColor(disabled ? .clear : Theme.cream)
                .frame(width: 72, height: 56)
                .background(disabled ? .clear : Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(disabled ? .clear : Theme.cardBorder, lineWidth: 0.5)
                )
        }
        .disabled(disabled)
    }
}

// ═══ Reusable Form Components ═══════════════════════

struct FormSheet<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.card, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#if !os(iOS)
enum GeltKeyboardType {
    case `default`, decimalPad, numberPad
}
#endif

struct GeltField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    #if os(iOS)
    var keyboard: UIKeyboardType = .default
    
    init(_ label: String, text: Binding<String>, placeholder: String = "", keyboard: UIKeyboardType = .default) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.keyboard = keyboard
    }
    #else
    var keyboard: GeltKeyboardType = .default
    
    init(_ label: String, text: Binding<String>, placeholder: String = "", keyboard: GeltKeyboardType = .default) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.keyboard = keyboard
    }
    #endif
    
    var body: some View {
        TextField(placeholder, text: $text)
            #if os(iOS)
            .keyboardType(keyboard)
            #endif
            .font(.system(size: 16))
            .foregroundColor(Theme.cream)
            .padding(13)
            .background(Theme.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))
    }
}

struct GeltPicker<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [(value: T, label: String)]
    
    init(_ label: String, selection: Binding<T>, options: [(T, String)]) {
        self.label = label
        self._selection = selection
        self.options = options.map { (value: $0.0, label: $0.1) }
    }
    
    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(options, id: \.value) { opt in
                Text(opt.label).tag(opt.value)
            }
        }
        .pickerStyle(.menu)
        .tint(Theme.gold)
        .padding(13)
        .background(Theme.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))
    }
}
