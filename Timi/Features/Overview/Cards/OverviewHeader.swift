import SwiftUI

/// The head of Tổng quan, on its soft coloured ground (`TabBackdrop`), not in a card (the
/// user's references 2026-11-02: the main figure on the ground). Centred and two short lines only
/// (user reviews 2026-11-02: too many words; the greeting went up beside the avatar): "Tài sản ròng"
/// with how it moved in small words, and the figure in large type under it. This month's in and
/// out live in "Tháng này", new entries in the tab bar's +. Tapping it opens "Tài sản ròng".
struct OverviewHeader: View {
    let onOpenNetWorth: () -> Void

    @Environment(FinanceStore.self) private var store

    /// Nothing recorded yet (a new install with no sample data, or after "Xoá toàn bộ dữ liệu").
    private var isEmpty: Bool {
        store.netWorth == 0 && store.netWorthHistory().allSatisfy { $0.value == 0 }
    }

    var body: some View {
        Button(action: onOpenNetWorth) {
            VStack(spacing: Spacing.xs) {
                label
                MoneyText(amount: store.netWorth, size: .display, tone: .balance)
            }
            // Room above, none below: the page's 28 between sections is the gap to the first card
            // (user report 2026-11-02: 16 more here made it look adrift).
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.top, Spacing.l)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Xem tài sản ròng gồm những gì")
    }

    /// "Tài sản ròng · ↑ 19,2tr ›"; before anything is recorded, what to do first.
    private var label: some View {
        let history = store.netWorthHistory()
        let change = history.first.map { store.netWorth - $0.value } ?? 0
        return HStack(spacing: Spacing.xs) {
            Text(isEmpty ? "Thêm tài khoản để bắt đầu" : "Tài sản ròng")
                .foregroundStyle(Palette.secondaryLabel)
            if !isEmpty, change != 0 {
                Text("\(change < 0 ? "↓" : "↑") \(abs(change).vndCompact)")
                    .monospacedDigit()
                    .foregroundStyle(change > 0 ? Palette.income : Palette.expense)
            }
            TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.linkChevron)
                .foregroundStyle(Palette.tertiaryLabel)
        }
        .textRole(.captionStrong)
    }
}
