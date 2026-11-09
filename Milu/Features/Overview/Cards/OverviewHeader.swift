import SwiftUI

/// "Tài sản ròng" on Tổng quan, kept small (user 2026-11-08: no "Tài sản | Nợ" here, the parts live
/// on the Tài sản ròng page). The heading sits on the page over the card with "Chi tiết ›", as
/// every section of the page. In the card (2026-11-08): "Hiện có" over the figure
/// (`MoneyText(.large)`, 24), no change beside it (user request); then its last six months as a
/// soft line across the card, the months named under it, today a ringed dot at its end. On
/// appearing (or with the first account) the line draws itself from the left; a new figure rolls
/// its digits. Both stand still with Reduce Motion. Tapping the card or "Chi tiết" opens it.
/// Before anything is recorded: the figure, one line, and "Thêm tài khoản"; the card is then not
/// a button, so that one is the thing to tap.
struct OverviewHeader: View {
    let onOpenNetWorth: () -> Void
    /// Opens "Thêm tài khoản" from the empty card: once the first step is done there is no other
    /// way on Tổng quan to add one (review 2026-11-08).
    let onAddAccount: () -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How much of the line is drawn, 0 to 1: drawn once, as the card first shows.
    @State private var drawn: CGFloat = 0

    /// The line's room across the card.
    private static let chartHeight: CGFloat = 76

    /// Nothing to show yet: no account and nothing else counted (a new install with no sample
    /// data, or after "Xoá toàn bộ dữ liệu"). A loan from before the app, or a jar, still has a
    /// figure, which then shows with its line, not over "Khi có tài khoản…" (review 2026-11-08).
    private var isEmpty: Bool {
        store.accounts.isEmpty && store.netWorth == 0 && store.netWorthHistory().allSatisfy { $0.value == 0 }
    }

    var body: some View {
        OutsideHeaderSection(title: "Tài sản ròng") {
            Button(action: onOpenNetWorth) { HeaderLink(title: "Chi tiết", opensPage: true) }
                .headerLinkButton()
        } content: {
            if isEmpty {
                // Not a button itself, so the "Thêm tài khoản" in it is the one thing to tap.
                card
            } else {
                Button(action: onOpenNetWorth) {
                    card
                }
                .buttonStyle(.card)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Xem tài sản ròng gồm những gì")
            }
        }
        .onAppear { if !isEmpty { drawLine() } }
        // The first account: the line draws itself in from the left, as on any first showing,
        // rather than appearing at once (review 2026-11-08).
        .onChange(of: isEmpty) { _, empty in if !empty { drawLine() } }
    }

    /// Draws the line once, from the left; at once with Reduce Motion.
    private func drawLine() {
        guard drawn < 1 else { return }
        if reduceMotion {
            drawn = 1
        } else {
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) { drawn = 1 }
        }
    }

    private var card: some View {
        let history = store.netWorthHistory()
        return VStack(alignment: .leading, spacing: 0) {
            Group {
                if isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        figure
                        Text("Khi có tài khoản, tài sản của bạn sẽ hiện ở đây.")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                        // The compact pill sits in a 44 tap area, 4 of air above and below it:
                        // taken out of the card's padding under it, so the pill keeps the
                        // card's 20 on every side.
                        MiluButton("Thêm tài khoản", role: .primary, size: .compact, action: onAddAccount)
                    }
                } else {
                    // The figure alone (user request 2026-11-08: no "+11% từ cuối T6"; the
                    // line under it says how it moved).
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Hiện có")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                        figure
                    }
                }
            }
            .padding([.horizontal, .top], Spacing.card)
            .padding(.bottom, isEmpty ? Spacing.card - (ControlHeight.regular - ControlHeight.small) / 2 : 0)
            if !isEmpty {
                chart(history)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The card clips the line to its round corners, so it runs to both edges.
        .cardSurface()
        .contentShape(Rectangle())
    }

    private var figure: some View {
        MoneyText(amount: store.netWorth, size: .large, tone: .balance)
            .contentTransition(.numericText(value: store.netWorth))
            .animation(reduceMotion ? nil : .smooth, value: store.netWorth)
    }

    /// The six months as a soft line across the card, the months named under it, drawn from the
    /// left as the card shows.
    private func chart(_ history: [NetWorthPoint]) -> some View {
        NetWorthChart(points: history, compact: true)
            .frame(height: Self.chartHeight)
            .mask(alignment: .leading) {
                GeometryReader { proxy in
                    Rectangle().frame(width: proxy.size.width * drawn)
                }
            }
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.m)
    }
}
