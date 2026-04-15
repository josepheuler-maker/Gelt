import SwiftUI
#if os(iOS)
import UIKit
#endif

// ═══════════════════════════════════════════════════
//  G E L T  ₪  — Black & Gold Edition
//
//  Adaptive: iPhone tabs, iPad/Mac sidebar
// ═══════════════════════════════════════════════════

@main
struct GeltApp: App {
    @StateObject private var store = DataStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .frame(minWidth: 800, minHeight: 600)
            #if os(macOS)
                .background(Theme.bg)
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Transaction") {
                    NotificationCenter.default.post(name: .geltNewTransaction, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #endif
    }
}

// ─── Notification for keyboard shortcuts ────────────
extension Notification.Name {
    static let geltNewTransaction = Notification.Name("geltNewTransaction")
}

// ─── Adaptive Content View ──────────────────────────
struct ContentView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        Group {
            #if os(macOS)
            SidebarLayout()
            #else
            if sizeClass == .regular {
                // iPad
                SidebarLayout()
            } else {
                // iPhone
                PhoneTabLayout()
            }
            #endif
        }
        .onAppear { configureAppearance() }
    }
    
    private func configureAppearance() {
        #if os(iOS)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Theme.bg)
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.faint)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.faint)]
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.gold)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.gold)]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.card)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.cream)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        #endif
    }
}

// ═══════════════════════════════════════════════════
//  iPhone — Tab Bar
// ═══════════════════════════════════════════════════

struct PhoneTabLayout: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            AccountsView()
                .tabItem {
                    Image(systemName: "wallet.pass.fill")
                    Text("Accounts")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .tint(Theme.gold)
    }
}

// ═══════════════════════════════════════════════════
//  iPad / Mac — Sidebar + Detail
// ═══════════════════════════════════════════════════

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case accounts = "Accounts"
    case recurring = "Recurring"
    case transactions = "Transactions"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .accounts: return "wallet.pass.fill"
        case .recurring: return "repeat"
        case .transactions: return "list.bullet"
        case .settings: return "gearshape.fill"
        }
    }
}

struct SidebarLayout: View {
    @State private var selected: SidebarItem? = .home
    @State private var showAddTx = false
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selected) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("₪ Gelt")
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .tint(Theme.gold)
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        showAddTx = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Theme.gold)
                }
                #endif
            }
        } detail: {
            Group {
                switch selected {
                case .home: HomeView()
                case .accounts: AccountsView()
                case .recurring: RecurringDetailView()
                case .transactions: TransactionsDetailView()
                case .settings: SettingsView()
                case .none: HomeView()
                }
            }
            .background(Theme.bg)
        }
        .tint(Theme.gold)
        .sheet(isPresented: $showAddTx) { AddTransactionSheet() }
        .onReceive(NotificationCenter.default.publisher(for: .geltNewTransaction)) { _ in
            showAddTx = true
        }
    }
}

// ─── Standalone views for sidebar detail ────────────

struct RecurringDetailView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RECURRING")
                            .font(.custom("Cormorant Garamond", size: 9).weight(.semibold))
                            .tracking(3)
                            .foregroundColor(Theme.gold)
                        Text("Bills & Paychecks")
                            .font(.custom("Cormorant Garamond", size: 28).weight(.bold))
                            .foregroundColor(Theme.cream)
                    }
                    Spacer()
                    Button { showAdd = true } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                .padding(.bottom, 8)
                
                // Income
                let incomeItems = store.data.recurring.filter { $0.isIncome }
                if !incomeItems.isEmpty {
                    SectionLabel(text: "INCOME")
                    ForEach(incomeItems) { rec in
                        RecurringRow(rec: rec)
                    }
                }
                
                // Expenses
                let expenseItems = store.data.recurring.filter { !$0.isIncome }.sorted { $0.daysUntil < $1.daysUntil }
                if !expenseItems.isEmpty {
                    SectionLabel(text: "EXPENSES")
                    ForEach(expenseItems) { rec in
                        RecurringRow(rec: rec)
                    }
                }
                
                if store.data.recurring.isEmpty {
                    GeltCard {
                        Text("No recurring items yet")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.faint)
                            .italic()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showAdd) { AddRecurringSheet() }
    }
}

struct RecurringRow: View {
    @EnvironmentObject var store: DataStore
    let rec: RecurringItem
    
    var body: some View {
        GeltCard {
            HStack(spacing: 12) {
                Text(rec.icon).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.cream)
                    HStack(spacing: 6) {
                        Pill(text: rec.frequency.rawValue)
                        if rec.daysUntil >= 0 && rec.daysUntil <= 7 {
                            Pill(text: rec.daysUntil == 0 ? "Today" : rec.daysUntil == 1 ? "Tomorrow" : "\(rec.daysUntil)d", gold: true)
                        } else {
                            DimText(text: shortDateLabel(rec.nextDate))
                        }
                    }
                }
                Spacer()
                Text("\(rec.isIncome ? "+" : "-")\(rec.amount.money)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(rec.isIncome ? Theme.green : Theme.red)
                
                Button {
                    Haptics.tap()
                    store.markPaid(rec)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .padding(8)
                        .background(Theme.goldDim)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button { store.deleteRecurring(rec.id) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.faint)
                }
            }
        }
    }
}

struct TransactionsDetailView: View {
    @EnvironmentObject var store: DataStore
    @State private var viewMonth = Date()
    @State private var showAdd = false
    @State private var showCSV = false
    
    private var mk: String { monthKeyFor(viewMonth) }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRANSACTIONS")
                            .font(.custom("Cormorant Garamond", size: 9).weight(.semibold))
                            .tracking(3)
                            .foregroundColor(Theme.gold)
                        Text(monthLabel(for: viewMonth))
                            .font(.custom("Cormorant Garamond", size: 28).weight(.bold))
                            .foregroundColor(Theme.cream)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left").foregroundColor(Theme.dim) }
                        Button { shiftMonth(1) } label: { Image(systemName: "chevron.right").foregroundColor(Theme.dim) }
                        Button { showCSV = true } label: { Label("Import", systemImage: "arrow.up.doc") }.buttonStyle(GhostButtonStyle())
                        Button { showAdd = true } label: { Label("Add", systemImage: "plus") }.buttonStyle(GhostButtonStyle())
                    }
                }
                .padding(.bottom, 8)
                
                let txs = store.transactions(for: mk).sorted { $0.date > $1.date }
                
                if txs.isEmpty {
                    GeltCard {
                        Text("No transactions this month")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.faint)
                            .italic()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
                
                ForEach(txs) { tx in
                    GeltCard {
                        HStack(spacing: 10) {
                            Text(tx.icon).font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.note.isEmpty ? "—" : tx.note)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.cream)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Pill(text: tx.category)
                                    DimText(text: shortDateLabel(tx.date), size: 10)
                                }
                            }
                            Spacer()
                            Text(tx.amount.money)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(tx.category == "Income" ? Theme.green : Theme.cream)
                            
                            Button { store.deleteTransaction(tx.id) } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.faint)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showAdd) { AddTransactionSheet() }
        .sheet(isPresented: $showCSV) { CSVImportSheet() }
    }
    
    private func shiftMonth(_ delta: Int) {
        viewMonth = Calendar.current.date(byAdding: .month, value: delta, to: viewMonth) ?? viewMonth
    }
}

// ═══════════════════════════════════════════════════
//  Haptics
// ═══════════════════════════════════════════════════

struct Haptics {
    static func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    static func warning() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
    
    static func error() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
    
    static func selection() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
