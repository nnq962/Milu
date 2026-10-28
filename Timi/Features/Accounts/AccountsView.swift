import SwiftUI

struct AccountsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var isAddingAccount = false
    @State private var isAddingGoal = false
    @State private var editingGoal: SavingsGoal?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    totalCard
                    paymentSection
                    goalsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            // The title names the back button of pushed screens; the leading heading is the visible title.
            .navigationTitle("Tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
                if #available(iOS 26.0, *) {
                    // Sleek: the heading sits on the same row as the + button.
                    ToolbarItem(placement: .topBarLeading) { heading }
                        .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .topBarTrailing) {
                        addMenu.nativeCircleButton(diameter: 44)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) { heading }
                    ToolbarItem(placement: .topBarTrailing) { addMenu }
                }
            }
            .navigationDestination(for: Account.ID.self) { accountID in
                AccountDetailView(accountID: accountID)
            }
            .sheet(isPresented: $isAddingAccount) { AddAccountView() }
            .sheet(isPresented: $isAddingGoal) { GoalEditorView(goal: nil) }
            .sheet(item: $editingGoal) { goal in GoalEditorView(goal: goal) }
        }
    }

    private var heading: some View {
        Text("Tài khoản")
            .font(Typography.font(.title2, size: 24, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }

    private var addMenu: some View {
        Menu {
            Button { isAddingAccount = true } label: { Label("Thêm tài khoản", image: "solar-wallet-linear") }
            Button { isAddingGoal = true } label: { Label("Thêm hũ tiết kiệm", image: "mdi-piggy-bank") }
        } label: {
            SolarIcon("solar-add-circle-linear", size: 20)
                .frame(width: 28, height: 28)
        }
        .menuStyle(.button)
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel("Thêm tài khoản hoặc hũ")
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tổng số dư")
                .font(Typography.font(.caption, size: 12, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16, relativeTo: .caption)
            Text(store.paymentBalance.vnd)
                .font(Typography.font(.largeTitle, size: 34, weight: .heavy))
                .designLineHeight(42.5, relativeTo: .largeTitle)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            Text("Gồm \(store.paymentAccounts.count) tài khoản và \(store.savingsGoals.count) hũ")
                .font(Typography.font(.caption2, size: 11))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16.5, relativeTo: .caption2)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
        .sleekCard()
    }

    private var paymentSection: some View {
        // Each account is its own row, ordered cash → bank → e-wallet.
        let accounts = AccountType.paymentTypes.flatMap { store.accounts(of: $0) }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tài khoản thanh toán")
            if accounts.isEmpty {
                emptyCard("Chưa có tài khoản thanh toán.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        NavigationLink(value: account.id) {
                            ListRow(icon: account.type.icon,
                                    title: account.name,
                                    subtitle: updatedText(store.lastActivity(of: account)),
                                    amount: account.balance)
                        }
                        .buttonStyle(.plain)
                        // Sleek draws the hairline absolutely, so it adds no row height.
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .cardSurface(color: Palette.card, elevated: true)
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mục tiêu tiết kiệm")
            if store.savingsGoals.isEmpty {
                emptyCard("Chưa có hũ tiết kiệm. Nhấn + để tạo hũ đầu tiên.")
            }
            ForEach(store.savingsGoals) { goal in
                Button { editingGoal = goal } label: { GoalCard(goal: goal) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(Typography.font(.footnote, size: 12))
            .foregroundStyle(Palette.secondaryText)
            .sleekCard()
    }

    private func updatedText(_ date: Date?) -> String {
        guard let date else { return "Chưa có giao dịch" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Cập nhật hôm nay" }
        if calendar.isDateInYesterday(date) { return "Cập nhật hôm qua" }
        return "Cập nhật \(calendar.component(.day, from: date))/\(calendar.component(.month, from: date))"
    }
}

#Preview {
    AccountsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .font(Typography.body)
}
