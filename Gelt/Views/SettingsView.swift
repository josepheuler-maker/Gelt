import SwiftUI

// ═══════════════════════════════════════════════════
//  GELT — Settings View (Expanding Boxes)
// ═══════════════════════════════════════════════════

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddTx = false
    @State private var showAddRec = false
    @State private var showAddCat = false
    @State private var showAddMerch = false
    @State private var showCSV = false
    @State private var showBalanceEdit = false
    @State private var newBalance = ""
    
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("SETTINGS")
                        .font(.custom("Cormorant Garamond", size: 9).weight(.semibold))
                        .tracking(3)
                        .foregroundColor(Theme.gold)
                    Text("Configuration")
                        .font(.custom("Cormorant Garamond", size: 28).weight(.bold))
                        .foregroundColor(Theme.cream)
                }
                .padding(.bottom, 8)
                
                // ─── Quick Actions ────────────────
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    QuickAction(icon: "plus", label: "Transaction") { showAddTx = true }
                    QuickAction(icon: "arrow.up.doc", label: "Import CSV") { showCSV = true }
                    QuickAction(icon: "repeat", label: "Recurring") { showAddRec = true }
                    QuickAction(icon: "dollarsign.circle", label: "Balance") {
                        newBalance = String(format: "%.2f", store.data.settings.primaryBalance)
                        showBalanceEdit = true
                    }
                }
                .padding(.bottom, 4)
                
                // ─── Expanding Box Sections ───────
                
                // Recurring
                ExpandingBox(
                    title: "Recurring Items",
                    icon: "repeat",
                    count: store.data.recurring.count,
                    isExpanded: expandedSections.contains("rec"),
                    toggle: { toggleSection("rec") }
                ) {
                    VStack(spacing: 0) {
                        ForEach(store.data.recurring) { rec in
                            HStack(spacing: 8) {
                                Text(rec.icon).font(.system(size: 14))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(rec.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.cream)
                                    DimText(text: "\(rec.frequency.rawValue) · \(rec.isIncome ? "income" : "expense") · \(rec.amount.money)", size: 10)
                                }
                                Spacer()
                                Button {
                                    Haptics.success()
                                    store.markPaid(rec)
                                } label: {
                                    Text("Pay")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Theme.gold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Theme.goldDim)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                Button { store.deleteRecurring(rec.id) } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.faint)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            
                            if rec.id != store.data.recurring.last?.id {
                                Rectangle().fill(Theme.cardBorder.opacity(0.5)).frame(height: 0.5).padding(.leading, 38)
                            }
                        }
                        
                        Button { showAddRec = true } label: {
                            Label("Add Recurring", systemImage: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.gold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                
                // Categories
                ExpandingBox(
                    title: "Categories",
                    icon: "chart.bar",
                    count: store.data.categories.filter { $0.name != "Income" }.count,
                    isExpanded: expandedSections.contains("cat"),
                    toggle: { toggleSection("cat") }
                ) {
                    VStack(spacing: 0) {
                        ForEach(store.data.categories.filter { $0.name != "Income" }) { cat in
                            HStack(spacing: 8) {
                                Text(cat.icon)
                                Text(cat.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.cream)
                                Spacer()
                                Text("\(cat.limit.money)/mo")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Theme.dim)
                                Button {
                                    store.data.categories.removeAll { $0.id == cat.id }
                                    store.save()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.faint)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                        }
                        
                        Button { showAddCat = true } label: {
                            Label("Add Category", systemImage: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.gold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                
                // Merchants
                ExpandingBox(
                    title: "Merchants",
                    icon: "storefront",
                    count: store.data.merchants.count,
                    isExpanded: expandedSections.contains("merch"),
                    toggle: { toggleSection("merch") }
                ) {
                    VStack(spacing: 0) {
                        ForEach(store.data.merchants) { m in
                            HStack(spacing: 8) {
                                Text(m.icon)
                                Text(m.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.cream)
                                Spacer()
                                Pill(text: m.category)
                                Button {
                                    store.data.merchants.removeAll { $0.id == m.id }
                                    store.save()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.faint)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                        }
                        
                        Button { showAddMerch = true } label: {
                            Label("Add Merchant", systemImage: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.gold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                
                // All Transactions
                ExpandingBox(
                    title: "Transactions",
                    icon: "list.bullet",
                    count: store.transactions(for: monthKeyFor(Date())).count,
                    isExpanded: expandedSections.contains("txAll"),
                    toggle: { toggleSection("txAll") }
                ) {
                    VStack(spacing: 0) {
                        let txs = store.transactions(for: monthKeyFor(Date())).sorted { $0.date > $1.date }
                        
                        if txs.isEmpty {
                            Text("No transactions this month")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.faint)
                                .italic()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(txs) { tx in
                                HStack(spacing: 8) {
                                    Text(tx.icon).font(.system(size: 13))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(tx.note.isEmpty ? "—" : tx.note)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Theme.cream)
                                            .lineLimit(1)
                                        DimText(text: String(tx.date.suffix(5)), size: 9)
                                    }
                                    Spacer()
                                    Text(tx.amount.money)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(tx.category == "Income" ? Theme.green : Theme.cream)
                                    Button { store.deleteTransaction(tx.id) } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 10))
                                            .foregroundColor(Theme.faint)
                                    }
                                }
                                .padding(.vertical, 5)
                                .padding(.horizontal, 16)
                                
                                if tx.id != txs.last?.id {
                                    Rectangle().fill(Theme.cardBorder.opacity(0.5)).frame(height: 0.5).padding(.leading, 38)
                                }
                            }
                        }
                    }
                }
                
                // ─── Footer ──────────────────────
                VStack(spacing: 4) {
                    Text("₪ Gelt")
                        .font(.custom("Cormorant Garamond", size: 16).weight(.semibold))
                        .foregroundColor(Theme.gold)
                    DimText(text: "Black & Gold Edition")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showAddTx) { AddTransactionSheet() }
        .sheet(isPresented: $showAddRec) { AddRecurringSheet() }
        .sheet(isPresented: $showAddCat) { AddCategorySheet() }
        .sheet(isPresented: $showAddMerch) { AddMerchantSheet() }
        .sheet(isPresented: $showCSV) { CSVImportSheet() }
        .sheet(isPresented: $showBalanceEdit) {
            EditBalanceSheet(
                accountID: nil,
                initialBalance: newBalance,
                onSave: { val in
                    if let v = Double(val) { store.updateBalance(v) }
                    showBalanceEdit = false
                }
            )
        }
    }
    
    private func toggleSection(_ key: String) {
        Haptics.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if expandedSections.contains(key) {
                expandedSections.remove(key)
            } else {
                expandedSections.insert(key)
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  Expanding Box Component
// ═══════════════════════════════════════════════════

struct ExpandingBox<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    let isExpanded: Bool
    let toggle: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: toggle) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isExpanded ? Theme.gold : Theme.dim)
                        .frame(width: 22)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isExpanded ? Theme.cream : Theme.text)
                    
                    Pill(text: "\(count)", gold: isExpanded)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isExpanded ? Theme.gold : Theme.faint)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                Rectangle()
                    .fill(Theme.cardBorder.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
                
                content
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98, anchor: .top)),
                            removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98, anchor: .top))
                        )
                    )
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isExpanded ? Theme.gold.opacity(0.2) : Theme.cardBorder, lineWidth: 1)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }
}

// ─── Quick Action Button ────────────────────────────
struct QuickAction: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(Theme.dim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.cardBorder, lineWidth: 1))
        }
    }
}
