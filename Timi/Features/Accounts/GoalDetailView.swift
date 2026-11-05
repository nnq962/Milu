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
    /// ✕ on the left: the first screen of `GoalDetailSheet`.
    var showsClose = false

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

                    HeaderCard(title: "Lịch sử") {
                        if activity.isEmpty {
                            // One short line, what will show here (strict review 2026-10-31).
                            EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa nạp lần nào",
                                           message: "Các lần nạp, rút sẽ hiện ở đây.")
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
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsClose {
                    ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
                }
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
                // The account picked before the sheet opens, so its row is there from the first
                // frame (re-review 2026-10-31: it was slid in on appear).
                case .deposit: GoalTransferSheet(goal: goal, direction: .deposit, account: defaultAccount)
                case .withdraw: GoalTransferSheet(goal: goal, direction: .withdrawal, account: defaultAccount)
                case .withdrawAll: GoalTransferSheet(goal: goal, direction: .withdrawal, closesGoal: true,
                                                     account: defaultAccount)
                // The add-transaction sheet, spending from the goal (user choice 2026-10-29).
                case .spend: AddTransactionView(buying: goal)
                }
            }
            .sheet(item: $editingItem) { item in
                ActivityEditor(item: item)
            }
            .systemAlert("Đã đủ mục tiêu", isPresented: $isCelebrating) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Hũ “\(goal.name)” đã đủ \(goal.target.vnd).")
            }
        } else {
            EmptyStateCard(icon: "hugeicons-alert-02", title: "Không tìm thấy hũ",
                           message: "Hũ này có thể đã bị xoá.")
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .frame(maxHeight: .infinity, alignment: .top)
                .pageBackground()
        }
    }

    /// The first unlocked payment account: where a deposit comes from and a withdrawal goes.
    private var defaultAccount: Account.ID? {
        store.paymentAccounts.first { !$0.isLocked }?.id
    }

    private func open(_ next: Sheet, for goal: SavingsGoal) {
        wasReached = goal.isReached
        sheet = next
    }

    /// A `SummaryCard` like "Tổng số dư": label and amount on the left, the goal's icon on the right,
    /// then the bar, the progress line and the actions (or how it ended, once closed).
    private func summary(_ goal: SavingsGoal) -> some View {
        SummaryCard(title: goal.isClosed ? "Mục tiêu" : "Đã để dành",
                    amount: goal.isClosed ? goal.target : goal.saved, icon: goal.icon, tone: .neutral,
                    picture: GoalArtwork.name(for: goal.icon)) {
            if goal.isClosed {
                closedLine(goal)
                    .padding(.top, Spacing.m)
            } else {
                ProgressBar(value: goal.progress, color: goal.isReached ? Palette.progressDone : Palette.progress)
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
        // At the largest text sizes the two halves stack instead of shrinking.
        AdaptiveStack(spacing: Spacing.s) {
            if goal.isReached {
                StatusBadge(title: "Đã đủ mục tiêu", tone: .positive, icon: "hugeicons-checkmark-badge-01")
            } else if goal.isOverdue {
                // Past its deadline: say so, as an overdue loan does, instead of "45tr/tháng".
                StatusBadge(title: "Quá hạn · \(goal.progressText)", tone: .warning)
            } else {
                (Text(goal.progressText).foregroundStyle(Palette.label)
                    + Text(Self.monthlyText(goal).map { " · \($0)" } ?? ""))
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
            Text("Mục tiêu \(goal.target.vnd)")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .accessibilityLabel("Mục tiêu \(goal.target.vnd)")
        }
        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
        .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.8)
        .monospacedDigit()
    }

    /// How it ended as the screen's one kind of badge, as "Đã đủ mục tiêu" (re-review 2026-10-31:
    /// a grey box with 12 corners beside a green pill): "Đã dùng: Mua xe" in the pill, the rest of
    /// where the money went and the day beside it while they fit, under it, wrapping rather than
    /// cut off, when not ("36tr về Ví tiền mặt · 29/10"). Beside it the card is three lines, not
    /// four (user report 2026-11-05: the day alone on a line under the pill).
    private func closedLine(_ goal: SavingsGoal) -> some View {
        let parts = goal.closingNote.components(separatedBy: " · ").filter { !$0.isEmpty }
        let head = parts.first ?? "Đã hoàn thành"
        let rest = (Array(parts.dropFirst()) + [goal.closedAt?.shortDay].compactMap { $0 })
            .joined(separator: " · ")
        let badge = StatusBadge(title: head, tone: .positive, icon: "hugeicons-checkmark-badge-01")
        let note = Text(rest)
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryLabel)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                badge.fixedSize()
                if !rest.isEmpty { note.lineLimit(1).fixedSize() }
            }
            VStack(alignment: .leading, spacing: Spacing.s) {
                badge
                if !rest.isEmpty { note.fixedSize(horizontal: false, vertical: true) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func actions(_ goal: SavingsGoal) -> some View {
        if goal.isReached {
            VStack(spacing: Spacing.m) {
                TimiButton("Mua ngay", icon: "hugeicons-shopping-bag-01", role: .primary, fullWidth: true) {
                    open(.spend, for: goal)
                }
                // Side by side, one above the other at the largest text sizes.
                AdaptiveStack(spacing: Spacing.m, stackedSpacing: Spacing.m) {
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
        guard let dueDate = goal.dueDate, goal.remaining > 0, !goal.isOverdue else { return nil }
        return "\(SavingsGoal.monthlySaving(remaining: goal.remaining, until: dueDate).vnd)/tháng"
    }
}

/// A deposit or withdrawal as a row: what happened as the title ("Nạp tiền"), where the money came
/// from or went as the subtitle ("Từ Vietcombank"). Seen from an account, the goal is the other side.
/// On "Giao dịch" (`list`) it reads as a transfer there does: both ends, no sign.
struct GoalTransferRow: View {
    enum Side { case goal, account, list }

    let transfer: GoalTransfer
    let side: Side
    /// Under the amount: the day, or the time in a list grouped by day (an account's history).
    var detail: TransactionListRow.Detail = .day

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let deposit = transfer.direction == .deposit
        let intoGoal = side == .goal ? deposit : !deposit
        ListRow(icon: icon, title: title, subtitle: subtitle,
                trailingSubtitle: detail == .time
                    ? transfer.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                    : transfer.date.shortDay,
                amount: transfer.amount,
                amountTone: side == .list ? .neutral : intoGoal ? .signedIncome : .signedExpense,
                showsChevron: false)
    }

    private var icon: String {
        switch side {
        case .goal: store.account(id: transfer.accountID)?.iconName ?? "hugeicons-wallet-01"
        case .account, .list: store.goal(id: transfer.goalID)?.icon ?? SavingsGoal.defaultIcon
        }
    }

    private var title: String {
        let deposit = transfer.direction == .deposit
        switch side {
        case .goal: return deposit ? "Nạp tiền" : "Rút tiền"
        case .account, .list: return deposit ? "Nạp vào hũ" : "Rút từ hũ"
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
        case .list:
            let account = store.account(id: transfer.accountID)?.name ?? "Tài khoản đã xoá"
            let goal = store.goal(id: transfer.goalID)?.name ?? "Hũ đã xoá"
            return deposit ? "\(account) → \(goal)" : "\(goal) → \(account)"
        }
    }
}

/// A goal opened from a list: a sheet sliding up, as an account and a transaction open, so the
/// tab bar is not left showing under it (user request 2026-11-01). ✕ or a swipe down closes it.
struct GoalDetailSheet: View {
    let goalID: SavingsGoal.ID

    var body: some View {
        NavigationStack {
            GoalDetailView(goalID: goalID, showsClose: true)
        }
        .timiSheetStyle()
    }
}

/// A row or tile that opens its goal in `GoalDetailSheet`, from every list of goals.
struct GoalSheetLink<Label: View>: View {
    let goalID: SavingsGoal.ID
    @ViewBuilder var label: Label

    @State private var isOpen = false

    var body: some View {
        Button { isOpen = true } label: { label }
            .sheet(isPresented: $isOpen) { GoalDetailSheet(goalID: goalID) }
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(goalID: SampleData.savingsGoals[1].id)
    }
    .environment(FinanceStore())
    .environment(\.locale, .vietnam)
}
