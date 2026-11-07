import SwiftUI

/// The head of Tổng quan, a card (user pick "A" 2026-11-04, after the bare figure on the ground
/// read flat): "Tài sản ròng ›", the figure in large type, how it moved in a pale chip ("↑ 19,2tr
/// từ cuối tháng 6"), and its last six months as a line along the card's foot, today a lime dot at
/// its end. On appearing the line draws itself from the left; a new figure rolls its digits. Both
/// stand still with Reduce Motion. This month's in and out live in "Tháng này", new entries in the
/// tab bar's +. Tapping it opens "Tài sản ròng".
struct OverviewHeader: View {
    let onOpenNetWorth: () -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How much of the line is drawn, 0 to 1: drawn once, as the card first shows.
    @State private var drawn: CGFloat = 0

    /// The line's room along the card's foot.
    private static let chartHeight: CGFloat = 64
    private static let chipPadding = EdgeInsets(top: Spacing.xxs + 1, leading: Spacing.s,
                                                bottom: Spacing.xxs + 1, trailing: Spacing.s)

    /// Nothing recorded yet (a new install with no sample data, or after "Xoá toàn bộ dữ liệu").
    private var isEmpty: Bool {
        store.netWorth == 0 && store.netWorthHistory().allSatisfy { $0.value == 0 }
    }

    var body: some View {
        let history = store.netWorthHistory()
        Button(action: onOpenNetWorth) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    heading
                    MoneyText(amount: store.netWorth, size: .display, tone: .balance)
                        .contentTransition(.numericText(value: store.netWorth))
                        .animation(reduceMotion ? nil : .smooth, value: store.netWorth)
                    if !isEmpty, let start = history.first {
                        chip(change: store.netWorth - start.value, since: start)
                    }
                }
                .padding([.horizontal, .top], Spacing.card)
                .padding(.bottom, isEmpty ? Spacing.card : 0)
                if !isEmpty {
                    NetWorthChart(points: history, compact: true)
                        .frame(height: Self.chartHeight)
                        .padding(.top, Spacing.m)
                        // Drawn from the left as the card shows: a mask that widens.
                        .mask(alignment: .leading) {
                            GeometryReader { proxy in
                                Rectangle().frame(width: proxy.size.width * drawn)
                            }
                        }
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // The card clips the line to its round corners, so it runs to both edges.
            .cardSurface()
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        .padding(.top, Spacing.xs)
        .onAppear {
            guard drawn < 1 else { return }
            if reduceMotion {
                drawn = 1
            } else {
                withAnimation(.easeOut(duration: 0.9).delay(0.15)) { drawn = 1 }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Xem tài sản ròng gồm những gì")
    }

    /// "Tài sản ròng ›"; before anything is recorded, what to do first.
    private var heading: some View {
        HStack(spacing: Spacing.xs) {
            Text(isEmpty ? "Thêm tài khoản để bắt đầu" : "Tài sản ròng")
                .foregroundStyle(Palette.secondaryLabel)
            TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.linkChevron)
                .foregroundStyle(Palette.tertiaryLabel)
        }
        .textRole(.captionStrong)
    }

    /// How it moved since the first month of the line, in the money's colours on their pale
    /// ground; nothing when it did not move. Worded as on the Tài sản ròng page.
    @ViewBuilder
    private func chip(change: Double, since point: NetWorthPoint) -> some View {
        if change != 0 {
            let month = Calendar.current.component(.month, from: point.month)
            Text("\(change < 0 ? "↓" : "↑") \(abs(change).vndCompact) từ cuối tháng \(month)")
                .textRole(.captionStrong)
                .monospacedDigit()
                .foregroundStyle(change > 0 ? Palette.income : Palette.expense)
                .padding(Self.chipPadding)
                // Rounded, not a capsule: at accessibility sizes it wraps to two lines, and a
                // capsule round two lines read as a blob (Simulator check 2026-11-04).
                .background(change > 0 ? Palette.incomeSoft : Palette.expenseSoft,
                            in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
                .padding(.top, Spacing.xxs)
        }
    }
}
