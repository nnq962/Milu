//
//  AccountsView.swift
//  Timi
//

import SwiftUI

struct AccountsView: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summary
                }

                ForEach(AccountType.allCases) { type in
                    let accounts = store.accounts.filter { $0.type == type }
                    if !accounts.isEmpty {
                        Section {
                            ForEach(accounts) { account in
                                NavigationLink(value: account.id) {
                                    AccountRow(account: account)
                                }
                            }
                        } header: {
                            HStack {
                                Text(type.title)
                                Spacer()
                                Text(accounts.reduce(0) { $0 + $1.balance }.vnd)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tài khoản")
            .navigationDestination(for: Account.ID.self) { accountID in
                AccountDetailView(accountID: accountID)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tổng số dư")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(store.netWorth.vnd)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            HStack(spacing: 24) {
                summaryItem(title: "Tài sản", value: store.totalAssets, color: .green)
                summaryItem(title: "Dư nợ", value: store.totalDebt, color: .red)
                summaryItem(title: "Số tài khoản", text: "\(store.accounts.count)", color: .accentColor)
            }
        }
        .padding(.vertical, 6)
    }

    private func summaryItem(title: String, value: Double = 0, text: String? = nil, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(text ?? value.vndCompact)
                .font(.subheadline.weight(.semibold))
        }
    }
}

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemName: account.type.icon, color: account.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(account.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(account.balance.vnd)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(account.balance < 0 ? .red : .primary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AccountsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
