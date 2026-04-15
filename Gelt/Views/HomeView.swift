import SwiftUI

// ═══════════════════════════════════════════════════
//  GELT — Home Dashboard
// ═══════════════════════════════════════════════════

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @State private var viewMonth = Date()
    @State private var showAddTx = false
    @State private var showAllCats = false
    
    private var mk: String { monthKeyFor(viewMonth) }
    private var spent: Double { store.spending(for: mk).reduce(0) { $0 + $1.amount } }
    private var incomeAmt: Double { store.income(for: mk).reduce(0) { $0 + $1.amount } }
    private var budget: Double { store.totalBudget }
    private var remaining: Double { budget - spent }
    private var byCat: [String: Double] { store.spentByCategory(for: mk) }
    
    private var dailyAvg: Double {
        let dom = Calendar.current.component(.day, from: Date())
        return dom > 0 ? spent / Double(dom) : 0
    }
    private var projected: Double {
        let dim = Calendar.current.range(of: .day, in: .month, for: viewMonth)?.count ?? 30
        return dailyAvg * Double(dim)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    // ─── Masthead ─────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting())
                                .font(.custom("Cormorant Garamond", size: 30).weight(.bold))
                                .foregroundColor(Theme.gold)
                            
                            Text(store.data.settings.primaryBalance.money)
                                .font(.custom("Cormorant Garamond", size: 38).weight(.bold))
                                .foregroundColor(Theme.cream)
                                .contentTransition(.numericText())
                            
                            HStack(spacing: 8) {
                                Text("Net worth")
                                    .foregroundColor(Theme.faint)
                                Text(store.netWorth.money)
                                    .fontWeight(.semibold)
                                    .foregroundColor(store.netWorth >= 0 ? Theme.green : Theme.red)
                            }
                            .font(.system(size: 11))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 10) {
                            // Month picker
                            HStack(spacing: 4) {
                                Button { shiftMonth(-1) } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.faint)
                                }
                                Text(shortMonthFor(viewMonth))
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(Theme.dim)
                                    .frame(minWidth: 36)
                                Button { shiftMonth(1) } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.faint)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // ─── Budget Card ─────────────────
                    GeltCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionLabel(text: "MONTHLY BUDGET")
                                Spacer()
                                DimText(text: "\(Int(budget > 0 ? (spent/budget)*100 : 0))% used")
                            }
                            GoldBar(value: spent, max: budget, height: 6)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                                StatTile(label: "Income", value: incomeAmt.money, color: Theme.green)
                                StatTile(label: "Spent", value: spent.money, color: Theme.gold)
                                StatTile(label: "Left", value: remaining.money, color: remaining < 0 ? Theme.red : Theme.cream)
                                StatTile(label: "Projected", value: projected.money, color: projected > budget ? Theme.red : Theme.dim)
                            }
                        }
                    }
                    
                    // ─── Weekly Spark ─────────────────
                    GeltCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SectionLabel(text: "THIS WEEK")
                                Spacer()
                                DimText(text: "\(dailyAvg.money)/day avg")
                            }
                            SparkBars(data: store.weeklySpending())
                        }
                    }
                    
                    // ─── Bills Due ────────────────────
                    if !store.billsDueSoon.isEmpty {
                        GeltCard(gold: true) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.gold)
                                    Text("DUE SOON")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(0.5)
                                        .foregroundColor(Theme.gold)
                                    Pill(text: "\(store.billsDueSoon.count)", gold: true)
                                }
                                
                                ForEach(store.billsDueSoon) { bill in
                                    HStack(spacing: 10) {
                                        Text(bill.icon)
                                            .font(.system(size: 16))
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(bill.name)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(Theme.cream)
                                            Text(bill.daysUntil == 0 ? "Today" : bill.daysUntil == 1 ? "Tomorrow" : "\(bill.daysUntil)d")
                                                .font(.system(size: 11))
                                                .foregroundColor(bill.daysUntil <= 1 ? Theme.red : Theme.dim)
                                        }
                                        Spacer()
                                        GoldLabel(text: bill.amount.money)
                                        Button {
                                            Haptics.success()
                                            store.markPaid(bill)
                                        } label: {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Theme.gold)
                                                .padding(6)
                                                .background(Theme.goldDim)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // ─── Spending by Category ─────────
                    GeltCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionLabel(text: "SPENDING")
                                Spacer()
                                Button { withAnimation { showAllCats.toggle() } } label: {
                                    Text(showAllCats ? "COLLAPSE" : "ALL →")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(0.5)
                                        .foregroundColor(Theme.faint)
                                }
                            }
                            
                            let cats = store.data.categories
                                .filter { $0.name != "Income" && (byCat[$0.name] ?? 0) > 0 }
                                .sorted { (byCat[$0.name] ?? 0) > (byCat[$1.name] ?? 0) }
                            let display = showAllCats ? cats : Array(cats.prefix(4))
                            
                            ForEach(display) { cat in
                                VStack(spacing: 4) {
                                    HStack {
                                        Text("\(cat.icon) \(cat.name)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.text)
                                        Spacer()
                                        HStack(spacing: 0) {
                                            Text((byCat[cat.name] ?? 0).money)
                                                .fontWeight(.semibold)
                                                .foregroundColor(cat.limit > 0 && (byCat[cat.name] ?? 0) > cat.limit ? Theme.red : Theme.cream)
                                            if cat.limit > 0 {
                                                Text(" / \(cat.limit.money)")
                                                    .foregroundColor(Theme.faint)
                                            }
                                        }
                                        .font(.system(size: 12, design: .monospaced))
                                    }
                                    if cat.limit > 0 {
                                        GoldBar(value: byCat[cat.name] ?? 0, max: cat.limit, height: 3)
                                    }
                                }
                            }
                        }
                    }
                    
                    // ─── 7-Day Outlook ────────────────
                    let events = store.outlookEvents()
                    if !events.isEmpty {
                        GeltCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel(text: "7-DAY OUTLOOK")
                                
                                let _ = { () -> [AnyView] in
                                    var bal = store.data.settings.primaryBalance
                                    return events.prefix(6).map { ev in
                                        bal += ev.item.isIncome ? ev.item.amount : -ev.item.amount
                                        let balCopy = bal
                                        return AnyView(
                                            HStack(spacing: 8) {
                                                Text(ev.item.icon).font(.system(size: 14))
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text(ev.item.name)
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(Theme.cream)
                                                    Text(shortDateLabel(ev.date))
                                                        .font(.system(size: 10))
                                                        .foregroundColor(Theme.dim)
                                                }
                                                Spacer()
                                                Text("\(ev.item.isIncome ? "+" : "-")\(ev.item.amount.money)")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(ev.item.isIncome ? Theme.green : Theme.red)
                                                Text(balCopy.money)
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(Theme.faint)
                                                    .frame(minWidth: 55, alignment: .trailing)
                                            }
                                            .padding(.vertical, 4)
                                        )
                                    }
                                }()
                                
                                // Rebuild outlook inline
                                OutlookList(events: Array(events.prefix(6)), startBalance: store.data.settings.primaryBalance)
                            }
                        }
                    }
                    
                    // ─── Accounts Strip ───────────────
                    GeltCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionLabel(text: "ACCOUNTS")
                                Spacer()
                                DimText(text: store.totalSavings.money)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(store.data.accounts) { acc in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(acc.icon).font(.system(size: 20))
                                            Text(acc.name)
                                                .font(.system(size: 9, weight: .semibold))
                                                .tracking(0.5)
                                                .foregroundColor(Theme.faint)
                                                .textCase(.uppercase)
                                            Text(acc.balance.money)
                                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.gold)
                                        }
                                        .padding(12)
                                        .background(Theme.bg2)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                    
                    // ─── Loans Snapshot ───────────────
                    if !store.data.loans.isEmpty {
                        GeltCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    SectionLabel(text: "LOANS")
                                    Spacer()
                                    DimText(text: "\(store.totalLoanRemaining.money) remaining")
                                }
                                
                                ForEach(store.data.loans) { loan in
                                    VStack(spacing: 4) {
                                        HStack {
                                            Text("\(loan.icon) \(loan.name)")
                                                .font(.system(size: 12))
                                                .foregroundColor(Theme.cream)
                                            Spacer()
                                            Text(loan.remaining.money)
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.cream)
                                        }
                                        GoldBar(value: loan.principal - loan.remaining, max: loan.principal, height: 3)
                                        DimText(text: "\(Int(loan.progressPercent))% · \(loan.monthlyPayment.money)/mo · \(String(format: "%.1f", loan.apr))%", size: 10)
                                    }
                                    .padding(.bottom, 4)
                                }
                                
                                Divider().background(Theme.cardBorder)
                                
                                HStack(spacing: 16) {
                                    StatTile(label: "AVG APR", value: String(format: "%.1f%%", store.weightedAPR), color: Theme.gold)
                                    StatTile(label: "INTEREST", value: store.totalInterestPaid.money, color: Theme.red)
                                    StatTile(label: "PAID", value: (store.totalLoanPrincipal - store.totalLoanRemaining).money, color: Theme.green)
                                }
                            }
                        }
                    }
                    
                    // ─── Runway ───────────────────────
                    let cov = store.coverageMonths()
                    GeltCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                SectionLabel(text: "RUNWAY")
                                Spacer()
                                Text(String(format: "%.1f months", cov))
                                    .font(.custom("Cormorant Garamond", size: 18).weight(.bold))
                                    .foregroundColor(cov >= 3 ? Theme.green : cov >= 1 ? Theme.gold : Theme.red)
                            }
                            GoldBar(value: cov, max: 3, height: 3)
                            DimText(text: "\(store.liquidSavings.money) liquid · 3-month goal", size: 10)
                        }
                    }
                    
                    // ─── Recent Transactions ──────────
                    GeltCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(text: "RECENT")
                            
                            let recent = store.transactions(for: mk)
                                .sorted { $0.date > $1.date }
                                .prefix(5)
                            
                            if recent.isEmpty {
                                Text("No transactions yet")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.faint)
                                    .italic()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else {
                                ForEach(Array(recent)) { tx in
                                    HStack(spacing: 10) {
                                        Text(tx.icon).font(.system(size: 15))
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(tx.note.isEmpty ? "—" : tx.note)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Theme.cream)
                                                .lineLimit(1)
                                            Text("\(String(tx.date.suffix(5))) · \(tx.category)")
                                                .font(.system(size: 10))
                                                .foregroundColor(Theme.dim)
                                        }
                                        Spacer()
                                        Text(tx.amount.money)
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            .foregroundColor(tx.category == "Income" ? Theme.green : Theme.cream)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    
                    // ─── ✡ Watermark ─────────────────
                    HStack {
                        Spacer()
                        Image(systemName: "star.of.david")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.gold.opacity(0.04))
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            
            // FAB
            GoldFAB {
                Haptics.tap()
                showAddTx = true
            }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
        }
        .sheet(isPresented: $showAddTx) { AddTransactionSheet() }
    }
    
    private func shiftMonth(_ delta: Int) {
        viewMonth = Calendar.current.date(byAdding: .month, value: delta, to: viewMonth) ?? viewMonth
    }
}

// ─── Outlook List (avoids closure capture issues) ───
struct OutlookList: View {
    let events: [(date: String, item: RecurringItem)]
    let startBalance: Double
    
    var body: some View {
        let balances = computeBalances()
        ForEach(Array(events.enumerated()), id: \.offset) { i, ev in
            HStack(spacing: 8) {
                Text(ev.item.icon).font(.system(size: 14))
                VStack(alignment: .leading, spacing: 1) {
                    Text(ev.item.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.cream)
                    Text(shortDateLabel(ev.date))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                Text("\(ev.item.isIncome ? "+" : "-")\(ev.item.amount.money)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ev.item.isIncome ? Theme.green : Theme.red)
                Text(balances[i].money)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.faint)
                    .frame(minWidth: 55, alignment: .trailing)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func computeBalances() -> [Double] {
        var bal = startBalance
        return events.map { ev in
            bal += ev.item.isIncome ? ev.item.amount : -ev.item.amount
            return bal
        }
    }
}
