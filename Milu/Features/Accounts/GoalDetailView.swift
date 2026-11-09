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
    /// Set by "Xoá hũ", "Mở lại hũ" or "Đóng hũ" in the form; the goal changes once that form
    /// and this screen have closed.
    @State private var leave: GoalEditorView.Leave?
    @State private var sheet: Sheet?
    @State private var isCelebrating = false
    /// Just reached while a sheet of its own was still up: said once that sheet has gone.
    @State private var celebratesOnDismiss = false
    /// A history row tapped to change or delete it (not on a closed goal).
    @State private var editingItem: AccountDetailView.Activity?

    enum Sheet: Identifiable {
        case deposit, withdraw, withdrawAll, spend
        var id: Self { self }
    }

    var body: some View {
        if let goal = store.goal(id: goalID) {
            let activity = AccountDetailView.activity(transactions: store.goalTransactions(goal),
                                                      transfers: store.transfers(of: goal))
            // The detail page of every sheet (`SheetPage`, review 2026-11-07).
            SheetPage(title: goal.name, showsClose: showsClose, canEdit: true, onEdit: {
                editsTarget = false
                isEditing = true
            }) {
                    summary(goal)

                    if activity.isEmpty {
                        // "Lịch sử" over its card, as an account's (user request 2026-11-07); one
                        // short line, what will show here (strict review 2026-10-31).
                        OutsideHeaderSection(title: "Lịch sử") {
                            EmptyStateCard(title: "Chưa nạp lần nào",
                                           message: "Các lần nạp, rút sẽ hiện ở đây.",
                                           picture: IconCatalog.emojiName("🫙"))
                        }
                    } else {
                        // One card a day, the day's title over it, as an account's history (review
                        // 2026-11-07: a flat list here, by day there); `SheetPage` sets them 24 apart.
                        ActivityDayList(groups: ActivityDayList.byDay(activity), headingOutside: true,
                                        isGoal: true, isEditable: !goal.isClosed) {
                            editingItem = $0
                        }
                    }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                guard let leave else {
                    celebrateIfDue()
                    return
                }
                self.leave = nil
                // This sheet or page first, then the goal out of its list (`AfterDismiss`).
                dismiss()
                let store = store
                AfterDismiss.run {
                    switch leave {
                    case .delete(let accountID): store.delete(goal, returningTo: accountID)
                    case .reopen: store.reopen(goal.id)
                    case .close: store.closeEmpty(goal.id)
                    }
                }
            }) {
                GoalEditorView(goal: goal, focusesTarget: editsTarget) { leave = $0 }
            }
            .sheet(item: $sheet, onDismiss: celebrateIfDue) { sheet in
                switch sheet {
                // The account picked before the sheet opens, so its row is there from the first
                // frame (re-review 2026-10-31: it was slid in on appear).
                case .deposit: GoalTransferSheet(goal: goal, direction: .deposit, account: defaultAccount(for: goal))
                case .withdraw: GoalTransferSheet(goal: goal, direction: .withdrawal, account: defaultAccount(for: goal))
                case .withdrawAll: GoalTransferSheet(goal: goal, direction: .withdrawal, closesGoal: true,
                                                     account: defaultAccount(for: goal))
                // The add-transaction sheet, spending from the goal (user choice 2026-10-29).
                case .spend: AddTransactionView(buying: goal)
                }
            }
            .sheet(item: $editingItem, onDismiss: celebrateIfDue) { item in
                ActivityEditor(item: item)
            }
            // Just reached its target, by a deposit, a deposit changed or a lower target: said once.
            // Watched on the goal itself, since a deposit is saved only once its sheet has slid
            // away (`AfterDismiss`), after that sheet's `onDismiss` (review 2026-11-07); while one
            // of this screen's sheets is still up, the alert waits for it to go.
            .onChange(of: goal.isReached && !goal.isClosed) { was, now in
                guard !was, now else { return }
                if isEditing || sheet != nil || editingItem != nil {
                    celebratesOnDismiss = true
                } else {
                    isCelebrating = true
                }
            }
            .systemAlert("Đã đủ mục tiêu", isPresented: $isCelebrating) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Hũ “\(goal.name)” đã đủ \(goal.target.vnd).")
            }
        } else {
            SheetPage(title: "Hũ", showsClose: showsClose, canEdit: false, onEdit: {}) {
                EmptyStateCard(title: "Không tìm thấy hũ",
                               message: "Hũ này có thể đã bị xoá.", picture: IconCatalog.emojiName("🧭"))
            }
        }
    }

    /// Its jar's water: its place among the goals being saved for, as Sổ ví counts them.
    private func water(of goal: SavingsGoal) -> Color {
        Palette.jarWater(at: store.activeGoals.firstIndex { $0.id == goal.id } ?? 0)
    }

    /// Where a deposit comes from and a withdrawal goes: the account of this goal's last transfer
    /// while it is still open, else the one used last, else the first (review 2026-11-06: always
    /// "Ví tiền mặt", though "Mua xe" was only ever fed from Vietcombank).
    private func defaultAccount(for goal: SavingsGoal) -> Account.ID? {
        let open = store.paymentAccounts.filter { !$0.isLocked }
        let usable = Set(open.map(\.id))
        if let last = store.transfers(of: goal).max(by: { $0.date < $1.date })?.accountID,
           usable.contains(last) {
            return last
        }
        // The account the last transaction was recorded on, as Thêm giao dịch starts with.
        if let recent = UserDefaults.standard.string(forKey: StorageKey.lastAccountID).flatMap(UUID.init),
           usable.contains(recent) {
            return recent
        }
        return open.first?.id
    }

    private func open(_ next: Sheet, for goal: SavingsGoal) {
        sheet = next
    }

    /// The alert held back while a sheet was up (`celebratesOnDismiss`).
    private func celebrateIfDue() {
        guard celebratesOnDismiss else { return }
        celebratesOnDismiss = false
        isCelebrating = true
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
                // The water of its jar on Sổ ví, so a goal keeps one colour in both places (user
                // choice 2026-11-06); green once reached, as the jar's "100%".
                ProgressBar(value: goal.progress, color: goal.isReached ? Palette.progressDone : water(of: goal))
                    .padding(.top, Spacing.l)
                progressLine(goal)
                    .padding(.top, Spacing.s)
                actions(goal)
                    .padding(.top, Spacing.xl)
            }
        }
    }

    /// One line under the bar while it fits: how far along (and, with a deadline, the monthly
    /// amount) on the left, the target on the right; "Đã đủ mục tiêu" once reached. When it does
    /// not fit, the two halves stack, whole, rather than shrink or cut ("2.500.000đ/thá…" at
    /// XXXL, review 2026-11-06: stacking waited for AX1).
    private func progressLine(_ goal: SavingsGoal) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                progressState(goal).fixedSize()
                Spacer(minLength: Spacing.s)
                targetText(goal).fixedSize()
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                progressState(goal).fixedSize(horizontal: false, vertical: true)
                targetText(goal).fixedSize(horizontal: false, vertical: true)
            }
        }
        .monospacedDigit()
    }

    @ViewBuilder
    private func progressState(_ goal: SavingsGoal) -> some View {
        if goal.isReached {
            StatusBadge(title: "Đã đủ mục tiêu", tone: .positive, icon: "hugeicons-checkmark-badge-01")
        } else if goal.isOverdue {
            // Past its deadline: say so, as an overdue loan does, instead of "167.000đ/tháng".
            StatusBadge(title: "Quá hạn · \(goal.progressText)", tone: .warning)
        } else {
            (Text(goal.progressText).foregroundStyle(Palette.label)
                + Text(Self.monthlyText(goal).map { " · \($0)" } ?? ""))
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
        }
    }

    private func targetText(_ goal: SavingsGoal) -> some View {
        Text("Mục tiêu \(goal.target.vnd)")
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryLabel)
    }

    /// How it ended as the screen's one kind of badge, as "Đã đủ mục tiêu" (re-review 2026-10-31:
    /// a grey box with 12 corners beside a green pill): "Đã dùng: Mua xe" in the pill, the rest of
    /// where the money went and the day beside it while they fit, under it, wrapping rather than
    /// cut off, when not ("36.000.000đ về Ví tiền mặt · 29/10"). Beside it the card is three lines, not
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
            .accessibilityLabel(FormDateRow.spokenDays(in: rest))
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
                MiluButton("Mua ngay", icon: "hugeicons-shopping-bag-01", role: .primary, fullWidth: true) {
                    open(.spend, for: goal)
                }
                // Side by side while both fit whole, else one above the other (Simulator 2026-11-07:
                // "Mục tiêu mới" read "Mục tiêu…" at the default size).
                PairOrStack {
                    MiluButton("Rút hết", icon: "hugeicons-arrow-up-02", role: .secondary, fullWidth: true) {
                        open(.withdrawAll, for: goal)
                    }
                    MiluButton("Mục tiêu mới", icon: "hugeicons-target-02", role: .secondary, fullWidth: true) {
                        editsTarget = true
                        isEditing = true
                    }
                }
            }
        } else {
            // Money out on the left, in on the right (user choice 2026-10-28); one above the other
            // when side by side they would be cut, "Rút t…" (review 2026-11-07).
            PairOrStack {
                MiluButton("Rút tiền", icon: "hugeicons-arrow-up-02", role: .secondary, fullWidth: true) {
                    open(.withdraw, for: goal)
                }
                .disabled(goal.saved <= 0)
                MiluButton("Nạp tiền", icon: "hugeicons-add-01", role: .primary, fullWidth: true) {
                    open(.deposit, for: goal)
                }
            }
        }
    }

    /// "167.000đ/tháng" when the goal has a deadline and is not reached yet.
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
                // Money out in ink, as a spending is ("B+"): in red, putting money by looked worse
                // than spending it (review 2026-11-06).
                amountTone: side == .list ? .neutral : intoGoal ? .signedIncome : .outflow,
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
        .miluSheetStyle()
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

/// Two buttons side by side while both fit whole, otherwise one above the other, 12 apart: a
/// label is never cut to "…", at any text size.
private struct PairOrStack<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            EqualWidthRow(spacing: Spacing.m) { content }
            VStack(spacing: Spacing.m) { content }
        }
    }
}

/// Side by side in equal widths. Its ideal width is the widest one's times the count, so
/// `ViewThatFits` takes it only when every label fits its share (an `HStack` reports the sum of
/// the widths, and then split the room evenly and cut the wider label).
private struct EqualWidthRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let gaps = spacing * CGFloat(subviews.count - 1)
        let ideals = subviews.map { $0.sizeThatFits(.unspecified) }
        let widest = ideals.map(\.width).max() ?? 0
        let width = proposal.width ?? (widest * CGFloat(subviews.count) + gaps)
        let share = (width - gaps) / CGFloat(subviews.count)
        let height = subviews.map { $0.sizeThatFits(ProposedViewSize(width: share, height: nil)).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let share = (bounds.width - spacing * CGFloat(subviews.count - 1)) / CGFloat(subviews.count)
        var x = bounds.minX
        for subview in subviews {
            subview.place(at: CGPoint(x: x, y: bounds.minY), proposal: ProposedViewSize(width: share, height: bounds.height))
            x += share + spacing
        }
    }
}
