//
//  AccountDetailView.swift
//  Timi
//

import SwiftUI

struct AccountDetailView: View {
    @Environment(FinanceStore.self) private var store
    let accountID: Account.ID

    var body: some View {
        if let account = store.account(id: accountID) {
            let transactions = store.accountTransactions(account)
            List {
                Section {
                    VStack(spacing: 8) {
                        IconBadge(systemName: account.type.icon, color: account.color, size: 60)
                        Text(account.balance.vnd)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(account.balance < 0 ? .red : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("\(account.type.title) · \(account.detail)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Giao dịch") {
                    if transactions.isEmpty {
                        Text("Chưa có giao dịch nào.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(transactions) { transaction in
                        TransactionRow(transaction: transaction, showsAccount: false)
                    }
                }
            }
            .navigationTitle(account.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Không tìm thấy tài khoản", systemImage: "exclamationmark.triangle")
        }
    }
}

#Preview {
    NavigationStack {
        AccountDetailView(accountID: SampleData.vietcombank.id)
    }
    .environment(FinanceStore())
    .environment(\.locale, .vietnam)
}
