import SwiftUI

/// The lead card of Tổng quan, a card (HIG pass 2026-10-31: content on solid surfaces,
/// glass only on the bars and controls): "Tài sản ròng" and a chevron at the far right, net worth
/// in large type, how much it moved since the chart's first month in small green words, and the
/// growth line over a faint wash; tapping it opens "Tài sản ròng", where the figure is taken
/// apart. The way into the assistant is the ✦ on the bar (2026-11-02).
struct HeroCard: View {
    let onOpen: () -> Void

    @Environment(FinanceStore.self) private var store

    /// The growth line's height.
    /// 64, not 48: the card had more space under the line than the line itself (Overview review
    /// 2026-11-02).
    private static let chartHeight: CGFloat = 64

    /// Nothing recorded yet (a new install with no sample data, or after "Xoá toàn bộ dữ liệu"): one
    /// line on what to do instead of "↑ 0đ từ cuối tháng 6" over a flat line (user request 2026-11-02).
    private var isEmpty: Bool {
        store.netWorth == 0 && store.netWorthHistory().allSatisfy { $0.value == 0 }
    }

    var body: some View {
        let history = store.netWorthHistory()
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Label, figure and growth drawn as on the Tài sản ròng page, so the one
                    // figure reads the same in both places (strict review 2026-10-31).
                    HStack {
                        Text("Tài sản ròng")
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.secondaryLabel)
                        Spacer()
                        RowChevron()
                    }
                    // Red below zero.
                    MoneyText(amount: store.netWorth, size: .display, tone: .balance)
                    if isEmpty {
                        Text("Thêm tài khoản để Timi theo dõi tài sản của bạn.")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if let first = history.first {
                        NetWorthGrowth(change: store.netWorth - first.value, since: first)
                    }
                }
                if !isEmpty {
                    NetWorthChart(points: history, compact: true)
                        .frame(height: Self.chartHeight)
                        .accessibilityHidden(true)
                }
            }
            .padding([.horizontal, .top], Spacing.leadCard)
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: CardCorners.large)
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Xem tài sản ròng gồm những gì")
    }
}
