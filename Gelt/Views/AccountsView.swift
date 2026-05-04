import SwiftUI

// ═══════════════════════════════════════════════════
//  GELT — Accounts View
// ═══════════════════════════════════════════════════

struct AccountsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddAccount = false
    @State private var showAddLoan = false
    @State private var editingAccountID: UUID?
    @State private var editBalanceText = ""
    @State private var showEditBalance = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACCOUNTS")
                        .font(.custom("Cormorant Garamond", size: 9).weight(.semibold))
                        .tracking(3)
                        .foregroundColor(Theme.gold)
                    Text("Financial Overview")
                        .font(.custom("Cormorant Garamond", size: 28).weight(.bold))
                        .foregroundColor(Theme.cream)
                }
                .padding(.bottom, 8)
                
                // ─── Net Worth ────────────────────
                GeltCard {
                    VStack(spacing: 14) {
                        SectionLabel(text: "NET WORTH")
                        AnimatedMoney(amount: store.netWorth, color: store.netWorth >= 0 ? Theme.green : Theme.red, size: 36)
                        
                        HStack(spacing: 24) {
                            VStack(spacing: 2) {
                                DimText(text: "Assets")
                                Text((store.data.settings.primaryBalance + store.totalSavings).money)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.cream)
                            }
                            Rectangle().fill(Theme.cardBorder).frame(width: 1, height: 30)
                            VStack(spacing: 2) {
                                DimText(text: "Debts")
                                Text(store.totalLoanRemaining.money)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.red)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // ─── Savings ──────────────────────
                HStack {
                    SectionLabel(text: "SAVINGS")
                    Spacer()
                    Button { showAddAccount = true } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                .padding(.top, 8)
                
                ForEach(store.data.accounts) { acc in
                    GeltCard {
                        HStack(spacing: 14) {
                            Text(acc.icon).font(.system(size: 26))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(acc.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.cream)
                                Pill(text: acc.type.rawValue)
                            }
                            Spacer()
                            GoldLabel(text: acc.balance.money, size: 20)
                            
                            // Delete button
                            Button {
                                store.deleteAccount(acc.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.faint)
                            }
                        }
                    }
                    .onTapGesture {
                        editingAccountID = acc.id
                        editBalanceText = String(format: "%.2f", acc.balance)
                        showEditBalance = true
                    }
                }
                
                // ─── Loans ────────────────────────
                HStack {
                    SectionLabel(text: "LOANS")
                    Spacer()
                    Button { showAddLoan = true } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                .padding(.top, 8)
                
                // APR Summary
                if !store.data.loans.isEmpty {
                    GeltCard {
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                SectionLabel(text: "WEIGHTED APR")
                                Text(String(format: "%.2f%%", store.weightedAPR))
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(Theme.gold)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 4) {
                                SectionLabel(text: "INTEREST PAID")
                                Text(store.totalInterestPaid.money)
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(Theme.red)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 4) {
                                SectionLabel(text: "PRINCIPAL PAID")
                                Text((store.totalLoanPrincipal - store.totalLoanRemaining).money)
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(Theme.green)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                // Loan Cards
                if store.data.loans.isEmpty {
                    GeltCard {
                        Text("No loans. Debt-free king 👑")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.faint)
                            .italic()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                } else {
                    ForEach(store.data.loans) { loan in
                        LoanCard(loan: loan)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showAddAccount) { AddAccountSheet() }
        .sheet(isPresented: $showAddLoan) { AddLoanSheet() }
        .sheet(isPresented: $showEditBalance) {
            EditBalanceSheet(
                accountID: editingAccountID,
                initialBalance: editBalanceText,
                onSave: { newBalance in
                    if let id = editingAccountID, let val = Double(newBalance) {
                        store.updateAccountBalance(id, balance: val)
                    }
                    showEditBalance = false
                }
            )
        }
    }
}

// ─── Loan Card ──────────────────────────────────────
struct LoanCard: View {
    @EnvironmentObject var store: DataStore
    let loan: Loan
    
    var body: some View {
        GeltCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(loan.icon).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loan.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.cream)
                        DimText(text: "\(String(format: "%.1f", loan.apr))% APR · \(loan.monthlyPayment.money)/mo\(loan.monthsRemaining < 999 ? " · ~\(loan.monthsRemaining)mo" : "")")
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(loan.remaining.money)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.cream)
                        DimText(text: "left")
                    }
                }
                
                GoldBar(value: loan.principal - loan.remaining, max: loan.principal, height: 5)
                
                HStack(spacing: 6) {
                    MiniStat(label: "Paid", value: "\(Int(loan.progressPercent))%", color: Theme.green)
                    MiniStat(label: "Next Int.", value: loan.nextInterest.money, color: Theme.red)
                    MiniStat(label: "Next Prin.", value: loan.nextPrincipal.money, color: Theme.gold)
                }
                
                HStack {
                    DimText(text: "Interest to date: ")
                    Text(loan.interestPaid.money)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.red)
                    Spacer()
                    Button {
                        Haptics.success()
                        store.makeLoanPayment(loan.id)
                    } label: {
                        Label("Pay", systemImage: "checkmark")
                    }
                    .buttonStyle(GhostButtonStyle())
                    
                    Button { store.deleteLoan(loan.id) } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.faint)
                    }
                }
            }
        }
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            DimText(text: label, size: 9)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
