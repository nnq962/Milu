import SwiftUI

/// One savings goal: how far along it is, "Rút tiền" / "Nạp tiền", then every deposit and
/// withdrawal, newest first. The pencil in the toolbar opens the goal form (name, target, icon,
/// deadline, delete), as "Sửa" does on an account.
struct GoalDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let goalID: SavingsGoal.ID

    @State private var isEditing = false
    /// Set by "Xoá hũ" in the form; the goal goes once that form has closed.
    @State private var deletesOnDismiss = false
    @State private var transferring: GoalTransfer.Direction?

    var body: some View {
        if let goal = store.goal(id: goalID) {
            let transfers = store.transfers(of: goal)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    summary(goal)

                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Lịch sử")
                        if transfers.isEmpty {
                            EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa nạp lần nào",
                                           message: "Tiền nạp vào hoặc rút ra khỏi hũ sẽ hiện ở đây.")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(transfers.enumerated()), id: \.element.id) { index, transfer in
                                    GoalTransferRow(transfer: transfer, side: .goal)
                                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                                }
                            }
                            .sleekCard(padding: 0)
                        }
                    }
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditToolbarButton { isEditing = true }
                }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                guard deletesOnDismiss else { return }
                dismiss()
                store.delete(goal)
            }) {
                GoalEditorView(goal: goal) { deletesOnDismiss = true }
            }
            .sheet(item: $transferring) { direction in
                GoalTransferSheet(goal: goal, direction: direction)
            }
        } else {
            ContentUnavailableView("Không tìm thấy hũ", image: "hugeicons-alert-02")
        }
    }

    /// Laid out like "Tổng số dư" on Tài khoản: label and amount on the left, the goal's icon on the
    /// right, then the bar with how far along on one side and the target on the other.
    private func summary(_ goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Đã để dành")
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryText)
                    Text(goal.saved.vnd)
                        .textRole(.display)
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                }
                Spacer(minLength: 0)
                RowIcon(name: goal.icon, size: RowMetrics.featureIcon)
            }
            .accessibilityElement(children: .combine)

            ProgressBar(value: goal.progress)
                .padding(.top, Spacing.l)
            // One line under the bar, never two: how far along (and, with a deadline, the monthly
            // amount) on the left, the target on the right.
            HStack(spacing: Spacing.s) {
                (Text(goal.progress.percentText).foregroundStyle(Palette.ink)
                    + Text(Self.monthlyText(goal).map { " · \($0)" } ?? ""))
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryText)
                Spacer(minLength: Spacing.s)
                Text("Mục tiêu \(goal.target.vndCompact)")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .monospacedDigit()
            .padding(.top, Spacing.s)

            // Money out on the left, in on the right (user choice 2026-10-28).
            HStack(spacing: Spacing.m) {
                TimiButton("Rút tiền", icon: "hugeicons-arrow-up-02", role: .secondary, fullWidth: true) {
                    transferring = .withdrawal
                }
                .disabled(goal.saved <= 0)
                TimiButton("Nạp tiền", icon: "hugeicons-add-01", role: .primary, fullWidth: true) {
                    transferring = .deposit
                }
            }
            .padding(.top, Spacing.xl)
        }
        .sleekCard(radius: CardCorners.extraLarge)
    }

    /// "167k/tháng" when the goal has a deadline and is not reached yet.
    static func monthlyText(_ goal: SavingsGoal) -> String? {
        guard let dueDate = goal.dueDate, goal.remaining > 0 else { return nil }
        return "\(SavingsGoal.monthlySaving(remaining: goal.remaining, until: dueDate).vndCompact)/tháng"
    }
}

/// A deposit or withdrawal as a row: what happened as the title ("Nạp tiền"), where the money came
/// from or went as the subtitle ("Từ Vietcombank"). Seen from an account, the goal is the other side.
struct GoalTransferRow: View {
    enum Side { case goal, account }

    let transfer: GoalTransfer
    let side: Side

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let deposit = transfer.direction == .deposit
        let intoGoal = side == .goal ? deposit : !deposit
        ListRow(icon: icon, title: title, subtitle: subtitle,
                trailingSubtitle: TransactionListRow.dayMonth(transfer.date),
                amount: transfer.amount,
                amountTone: intoGoal ? .signedIncome : .signedExpense,
                showsChevron: false)
    }

    private var icon: String {
        switch side {
        case .goal: store.account(id: transfer.accountID)?.iconName ?? "hugeicons-wallet-01"
        case .account: store.goal(id: transfer.goalID)?.icon ?? SavingsGoal.defaultIcon
        }
    }

    private var title: String {
        let deposit = transfer.direction == .deposit
        switch side {
        case .goal: return deposit ? "Nạp tiền" : "Rút tiền"
        case .account: return deposit ? "Nạp vào hũ" : "Rút từ hũ"
        }
    }

    private var subtitle: String {
        let deposit = transfer.direction == .deposit
        switch side {
        case .goal:
            let account = store.account(id: transfer.accountID)?.name ?? "tài khoản đã xoá"
            return deposit ? "Từ \(account)" : "Về \(account)"
        case .account:
            return store.goal(id: transfer.goalID)?.name ?? "Hũ đã xoá"
        }
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(goalID: SampleData.savingsGoals[1].id)
    }
    .environment(FinanceStore())
    .environment(\.locale, .vietnam)
}
