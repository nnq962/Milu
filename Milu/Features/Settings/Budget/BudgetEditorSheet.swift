import SwiftUI

/// Sets a spending limit. `check` says what is wrong with an amount (the groups' limits must fit
/// in the month's, `BudgetRules`): ✓ then keeps the sheet open and shows it in red under the
/// amount, with `fix` offered as a button when there is a way out (raise the month's limit). A
/// limit already set shows a red "Bỏ hạn mức" (review 2026-11-08: removing meant clearing the
/// field, which nothing said), always asking first, `removeWarning` saying what follows (review
/// 2026-11-08: a group's limit went at one tap, against "xoá luôn hỏi lại").
struct BudgetEditorSheet: View {
    /// A way past an error, in one tap: its words and what it does.
    struct Fix {
        let title: String
        let apply: () -> Void
    }

    @Binding var amount: Double
    var title = "Hạn mức chi tiêu"
    var caption = "Mỗi tháng"
    /// Under the amount, only when there is something to know (a floor, what is free).
    var note: String? = nil
    var check: (Double) -> String? = { _ in nil }
    var fix: (Double) -> Fix? = { _ in nil }
    /// Ready amounts offered while nothing is typed.
    var presets: [AmountPreset] = []
    /// What follows "Bỏ hạn mức", in the alert that asks first.
    var removeWarning = ""
    var onRemove: (() -> Void)? = nil
    /// A plain link at the foot ("Xem chi tiêu của nhóm ›"), the sheet closing first.
    var link: Fix? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var input: String
    @State private var error: String?
    @State private var isConfirmingRemove = false

    init(amount: Binding<Double>, title: String? = nil, caption: String? = nil, note: String? = nil,
         presets: [AmountPreset] = [], removeWarning: String = "", onRemove: (() -> Void)? = nil,
         link: Fix? = nil, fix: @escaping (Double) -> Fix? = { _ in nil },
         check: @escaping (Double) -> String? = { _ in nil }) {
        self.presets = presets
        _amount = amount
        if let title { self.title = title }
        if let caption { self.caption = caption }
        self.note = note
        self.removeWarning = removeWarning
        self.onRemove = onRemove
        self.link = link
        self.fix = fix
        self.check = check
        let current = amount.wrappedValue
        _input = State(initialValue: current > 0 ? String(Int(current)).groupedVNDInput : "")
    }

    private var value: Double { input.vndInputAmount }
    private var isValid: Bool { value.isFinite && value <= BudgetRules.cap }

    var body: some View {
        SheetScaffold(title: title, canConfirm: isValid, validate: validate, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text(caption)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                // Quick chips (user request 2026-10-30): ready amounts before typing, then the field's own
                // suggestions from the digits (5 → 5tr, 50tr…).
                MiluAmountField(text: $input, focusesOnAppear: true, presets: presets,
                                accessibilityLabel: "\(title), \(caption.lowercased())")
                if !isValid {
                    FormErrorText(message: "Tối đa \(BudgetRules.cap.vnd).")
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.s)
                } else if let error {
                    FormErrorText(message: error)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.s)
                    if let fix = fix(value) {
                        MiluButton(fix.title, role: .secondary) {
                            fix.apply()
                            dismiss()
                        }
                        .padding(.top, Spacing.s)
                    }
                } else if let note {
                    Text(note)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.s)
                }
                if amount > 0, onRemove != nil {
                    MiluButton("Bỏ hạn mức", role: .destructive) { askToRemove() }
                        .padding(.top, Spacing.l)
                }
                if let link {
                    Button {
                        dismiss()
                        AfterDismiss.run(link.apply)
                    } label: {
                        HeaderLink(title: link.title, opensPage: true)
                    }
                    .headerLinkButton()
                    .padding(.top, Spacing.l)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
            .animation(Motion.gentle(.easeOut(duration: 0.2)), value: error)
        } content: {
            EmptyView()
        }
        // A new amount clears the old complaint until ✓ checks again.
        .onChange(of: input) { error = nil }
        // iOS's own alert colours, as every alert of the app; a warning tick as it shows.
        .systemAlert("Bỏ hạn mức?", isPresented: $isConfirmingRemove) {
            Button("Bỏ hạn mức", role: .destructive) { remove() }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text(removeWarning)
        }
        // Large like every form sheet: the keyboard opens at once and the chips need room.
        .miluSheetStyle()
    }

    /// An emptied field on a limit already set is "Bỏ hạn mức": asked here, before ✓ counts as a
    /// save, so it gives no "saved" tick and does not lock ✓ for a second (review 2026-11-08).
    private func validate() -> Bool {
        if isRemoving {
            isConfirmingRemove = true
            return false
        }
        error = check(value)
        return error == nil
    }

    private var isRemoving: Bool { value == 0 && amount > 0 && onRemove != nil }

    private func save() {
        guard isValid, !isRemoving else { return }
        amount = value
        dismiss()
    }

    private func askToRemove() {
        Haptics.warning()
        isConfirmingRemove = true
    }

    private func remove() {
        onRemove?()
        dismiss()
    }
}

/// The month's limit, the same for every month; it may not drop below what the groups hold.
/// "Bỏ hạn mức" removes the groups' limits with it, after asking (review 2026-11-08: it said "Bỏ
/// hạn mức các hạng mục trước" and sent the user through every group).
struct MonthBudgetEditor: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = CategoryBudgets()

    var body: some View {
        let groups = categoryBudgets.keeping(store.budgetGroupIDs)
        let count = groups.limits.count
        BudgetEditorSheet(amount: $monthlyBudget, title: "Hạn mức tháng",
                          // Says it is one limit for every month, past ones too (review 2026-11-08).
                          caption: "Áp dụng cho mọi tháng",
                          note: groups.total > 0
                              ? "Tối thiểu \(groups.total.vnd), bằng tổng hạn mức của các nhóm."
                              : nil,
                          // Common monthly limits, none below what the groups already hold; three,
                          // so the full amounts fit one row.
                          presets: [10, 20, 30].map { AmountPreset(title: "", value: Double($0) * 1_000_000) }
                              .filter { $0.value >= groups.total },
                          removeWarning: count > 0 ? "Hạn mức riêng của \(count) nhóm cũng sẽ được bỏ."
                              : "Milu sẽ không còn nhắc khi chi tiêu sắp chạm mức.",
                          onRemove: {
                              monthlyBudget = 0
                              categoryBudgets = CategoryBudgets()
                          }) { $0 == 0 && monthlyBudget > 0 ? nil : BudgetRules.monthError($0, groups: groups) }
    }
}

/// A group's limit; it fits in what the month has not given to other groups yet. Asking for more
/// than is free offers to raise the month's limit by the difference, in the same tap (review
/// 2026-11-08: a fully split month was a dead end).
struct GroupBudgetEditor: View {
    /// Round amounts below what may be given, and "Tối đa" for all of it (review 2026-11-08: shares
    /// of a room that counted the group's own limit read as a cut, and "Hết" as "finished").
    static func presets(room: Double) -> [AmountPreset] {
        guard room > 0 else { return [] }
        let round = [500_000.0, 1_000_000, 2_000_000, 5_000_000].filter { $0 < room }.suffix(3)
            .map { AmountPreset(title: "", value: $0) }
        return Array(round) + [AmountPreset(title: "Tối đa", value: room)]
    }

    let groupID: String
    let name: String
    /// Opens the group's spending, when the sheet is opened from Hạn mức chi tiêu (from the group's
    /// own report page there is no need).
    var onViewSpending: (() -> Void)? = nil

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = CategoryBudgets()

    var body: some View {
        let groups = categoryBudgets.keeping(store.budgetGroupIDs)
        let month = monthlyBudget
        let room = BudgetRules.room(for: groupID, month: month, groups: groups)
        // Saving also drops the limits of groups no longer in use.
        let amount = Binding(get: { groups[groupID] }, set: { value in
            var kept = groups
            kept[groupID] = value
            categoryBudgets = kept
        })
        BudgetEditorSheet(amount: amount, title: name, caption: "Hạn mức mỗi tháng",
                          note: month <= 0 ? "Đặt hạn mức tháng trước."
                              : room > 0 ? "Có thể đặt tối đa \(room.vnd)."
                              : "Hạn mức tháng đã phân bổ hết cho các nhóm khác.",
                          presets: Self.presets(room: room),
                          // The last group with a limit takes "Chưa phân bổ" with it (review
                          // 2026-11-08: the alert named a row about to go).
                          removeWarning: Set(groups.limits.keys) == [groupID]
                              ? "Chi tiêu của \(name) sẽ chỉ tính vào hạn mức tháng."
                              : "Chi tiêu của \(name) sẽ tính vào phần chưa phân bổ.",
                          onRemove: { amount.wrappedValue = 0 },
                          link: onViewSpending.map { .init(title: "Xem chi tiêu của nhóm", apply: $0) },
                          fix: { value in
                              // No month limit yet: set it to this group's, in the same tap. None
                              // past the cap, which could not be typed back (review 2026-11-08).
                              let raised = month + (value - room)
                              guard value > room, raised <= BudgetRules.cap else { return nil }
                              return .init(title: month > 0 ? "Tăng hạn mức tháng lên \(raised.vnd)"
                                                            : "Đặt hạn mức tháng \(raised.vnd)") {
                                  monthlyBudget = raised
                                  amount.wrappedValue = value
                              }
                          }) {
            BudgetRules.groupError($0, groupID: groupID, month: month, groups: groups)
        }
    }
}
