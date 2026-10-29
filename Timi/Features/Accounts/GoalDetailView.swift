import SwiftUI

/// One savings goal, in one of three states (lifecycle, user request 2026-10-29):
/// - saving: how far along, "Rút tiền" / "Nạp tiền";
/// - reached the target: "Mua ngay" (spend it in the add-transaction sheet, then close), "Rút hết"
///   (take it out, then close)
///   or "Mục tiêu mới" (aim higher in the goal form); reaching it says so once, with a haptic;
/// - closed: how it ended, no actions; it lives on "Hũ đã hoàn thành".
/// Under it, the history: deposits, withdrawals and what was spent, newest first. The pencil opens
/// the goal form (name, target, icon, deadline, delete).
struct GoalDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let goalID: SavingsGoal.ID

    @State private var isEditing = false
    /// The form opened from "Mục tiêu mới": the target gets the keyboard.
    @State private var editsTarget = false
    /// Set by "Xoá hũ" in the form; the goal goes once that form has closed.
    @State private var deletesOnDismiss = false
    /// The account that gets the goal's money back when it is deleted.
    @State private var returnAccount: Account.ID?
    @State private var sheet: Sheet?
    /// Whether the goal had reached its target when a sheet opened, to tell when it just did.
    @State private var wasReached = false
    @State private var isCelebrating = false
    /// A history row tapped to change or delete it (not on a closed goal).
    @State private var editingItem: AccountDetailView.Activity?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    enum Sheet: Identifiable {
        case deposit, withdraw, withdrawAll, spend
        var id: Self { self }
    }

    var body: some View {
        if let goal = store.goal(id: goalID) {
            let activity = AccountDetailView.activity(transactions: store.goalTransactions(goal),
                                                      transfers: store.transfers(of: goal))
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    summary(goal)

                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Lịch sử")
                        if activity.isEmpty {
                            // A goal can start with money but no deposit yet (older data, sample data).
                            EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa nạp lần nào",
                                           message: goal.saved > 0
                                               ? "\(goal.saved.vnd) là số có sẵn khi tạo hũ. Các lần nạp, rút sau này sẽ hiện ở đây."
                                               : "Tiền nạp vào hoặc rút ra khỏi hũ sẽ hiện ở đây.")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(activity.enumerated()), id: \.element.id) { index, item in
                                    ActivityRow(item: item, side: .goal, isEditable: !goal.isClosed) { editingItem = $0 }
                                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                                }
                            }
                            .listCard()
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
                    EditToolbarButton {
                        editsTarget = false
                        wasReached = goal.isReached
                        isEditing = true
                    }
                }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                guard deletesOnDismiss else {
                    // A lower target can make it reached: say so once, as a deposit does.
                    if !wasReached, store.goal(id: goalID).map({ $0.isReached && !$0.isClosed }) == true {
                        isCelebrating = true
                    }
                    return
                }
                dismiss()
                store.delete(goal, returningTo: returnAccount)
            }) {
                GoalEditorView(goal: goal, focusesTarget: editsTarget) { account in
                    returnAccount = account
                    deletesOnDismiss = true
                }
            }
            .sheet(item: $sheet, onDismiss: {
                // Just reached the target with that deposit: say so once.
                if !wasReached, store.goal(id: goalID).map({ $0.isReached && !$0.isClosed }) == true {
                    // ✓ already buzzed; the alert says it.
                    isCelebrating = true
                }
            }) { sheet in
                switch sheet {
                case .deposit: GoalTransferSheet(goal: goal, direction: .deposit)
                case .withdraw: GoalTransferSheet(goal: goal, direction: .withdrawal)
                case .withdrawAll: GoalTransferSheet(goal: goal, direction: .withdrawal, closesGoal: true)
                // The add-transaction sheet, spending from the goal (user choice 2026-10-29).
                case .spend: AddTransactionView(buying: goal)
                }
            }
            .sheet(item: $editingItem) { item in
                ActivityEditor(item: item)
            }
            .alert("Đã đủ mục tiêu", isPresented: $isCelebrating) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Hũ “\(goal.name)” đã đủ \(goal.target.vnd). Giờ bạn có thể mua ngay, rút về tài khoản hoặc đặt mục tiêu mới.")
            }
        } else {
            EmptyStateCard(icon: "hugeicons-alert-02", title: "Không tìm thấy hũ",
                           message: "Hũ này có thể đã bị xoá.")
                .padding(Spacing.page)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(Palette.background)
        }
    }

    private func open(_ next: Sheet, for goal: SavingsGoal) {
        wasReached = goal.isReached
        sheet = next
    }

    /// A `SummaryCard` like "Tổng số dư": label and amount on the left, the goal's icon on the right,
    /// then the bar, the progress line and the actions (or how it ended, once closed).
    private func summary(_ goal: SavingsGoal) -> some View {
        SummaryCard(label: goal.isClosed ? "Mục tiêu" : "Đã để dành",
                    amount: goal.isClosed ? goal.target : goal.saved, icon: goal.icon, tone: .plain) {
            if goal.isClosed {
                closedLine(goal)
                    .padding(.top, Spacing.m)
            } else {
                ProgressBar(value: goal.progress)
                    .padding(.top, Spacing.l)
                progressLine(goal)
                    .padding(.top, Spacing.s)
                actions(goal)
                    .padding(.top, Spacing.xl)
            }
        }
    }

    /// One line under the bar, never two: how far along (and, with a deadline, the monthly
    /// amount) on the left, the target on the right; "Đã đủ mục tiêu" once reached.
    private func progressLine(_ goal: SavingsGoal) -> some View {
        HStack(spacing: Spacing.s) {
            if goal.isReached {
                StatusBadge(text: "Đã đủ mục tiêu", tone: .positive, icon: "hugeicons-checkmark-badge-01")
            } else {
                (Text(goal.progressText).foregroundStyle(Palette.ink)
                    + Text(Self.monthlyText(goal).map { " · \($0)" } ?? ""))
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryText)
            }
            Spacer(minLength: Spacing.s)
            Text("Mục tiêu \(goal.target.vndCompact)")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .monospacedDigit()
    }

    /// "Đã dùng: Mua xe · 36tr về Ví tiền mặt · 29/10": wraps rather than cutting off where the
    /// rest of the money went.
    private func closedLine(_ goal: SavingsGoal) -> some View {
        Label {
            Text([goal.closingNote, goal.closedAt.map(TransactionListRow.dayMonth)].compactMap { $0 }
                    .filter { !$0.isEmpty }.joined(separator: " · "))
                .textRole(.captionStrong)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            TimiIcon("hugeicons-checkmark-badge-01", size: StatusBadge.icon)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, StatusBadge.horizontalPadding)
        .padding(.vertical, Spacing.xs)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: CardCorners.field, style: .continuous))
    }

    @ViewBuilder
    private func actions(_ goal: SavingsGoal) -> some View {
        if goal.isReached {
            VStack(spacing: Spacing.m) {
                TimiButton("Mua ngay", icon: "hugeicons-shopping-bag-01", role: .primary, fullWidth: true) {
                    open(.spend, for: goal)
                }
                // Side by side, one above the other at the largest text sizes.
                AnyLayout(dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Spacing.m))
                          : AnyLayout(HStackLayout(spacing: Spacing.m))) {
                    TimiButton("Rút hết", icon: "hugeicons-arrow-up-02", role: .secondary, fullWidth: true) {
                        open(.withdrawAll, for: goal)
                    }
                    TimiButton("Mục tiêu mới", icon: "hugeicons-target-02", role: .secondary, fullWidth: true) {
                        editsTarget = true
                        wasReached = goal.isReached
                        isEditing = true
                    }
                }
            }
        } else {
            // Money out on the left, in on the right (user choice 2026-10-28).
            HStack(spacing: Spacing.m) {
                TimiButton("Rút tiền", icon: "hugeicons-arrow-up-02", role: .secondary, fullWidth: true) {
                    open(.withdraw, for: goal)
                }
                .disabled(goal.saved <= 0)
                TimiButton("Nạp tiền", icon: "hugeicons-add-01", role: .primary, fullWidth: true) {
                    open(.deposit, for: goal)
                }
            }
        }
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
