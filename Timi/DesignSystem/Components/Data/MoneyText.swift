import SwiftUI

/// Every amount on screen: tabular digits, "đ" attached, sign and colour by meaning. Always the
/// full figure in đồng, as a banking app writes it ("33.800.000đ"); only where that does not fit
/// the room it is given does it shorten to "33,8tr" (user choice 2026-10-31: the app mixed the two
/// forms with no rule). The choice is made by layout (`ViewThatFits`), not by the caller.
struct MoneyText: View {
    /// `caption`: a total beside a heading (a day's +/-).
    /// `heading`: a total inside a chart (Tổng chi in the ring).
    /// `rowStrong`: a row's figure a step stronger than its name (accounts).
    enum Size { case caption, row, rowStrong, heading, large, display }
    /// Named by what the figure is (review 2026-10-31: `negativeRed` named a colour):
    /// `balance` is a sum that may go below zero, red with "-" when it does (the default: a
    /// balance, net worth, a limit left); `neutral` never turns red (a transfer between accounts,
    /// a loan's principal); `signedIncome` "+" in ink, `signedExpense` "-" in red; `signedNet` a
    /// change either way, "+" in ink above zero and "-" in red below (Dư ra, a day's total);
    /// `muted` grey, for money that does not count (a locked account); `outflow` money out in a
    /// list of money, "-" in ink: red on every row read as alarm ("B+" 2026-11-03), so in a list
    /// only money in takes a colour.
    enum Tone { case balance, neutral, signedIncome, signedExpense, signedNet, transfer, muted, outflow }

    let amount: Double
    var size: Size = .row
    var tone: Tone = .balance

    private func text(compact: Bool) -> String {
        let value = compact ? abs(amount).vndCompact : abs(amount).vnd
        switch tone {
        case .signedIncome: return "+" + value
        case .signedExpense, .outflow: return "-" + value
        case .signedNet: return (amount > 0 ? "+" : amount < 0 ? "-" : "") + value
        case .neutral, .balance, .transfer, .muted: return (amount < 0 ? "-" : "") + value
        }
    }

    private var color: Color {
        switch tone {
        // Money in emerald with its "+", money out coral, between the user's own accounts grey,
        // everywhere (the user's palette 2026-11-02; money in was ink before).
        case .signedExpense: Palette.expense
        case .signedIncome: Palette.income
        case .signedNet: amount > 0 ? Palette.income : amount < 0 ? Palette.expense : Palette.label
        case .balance: amount < 0 ? Palette.expense : Palette.label
        case .transfer: Palette.transfer
        case .neutral, .outflow: Palette.label
        case .muted: Palette.secondaryLabel
        }
    }

    /// What VoiceOver says: the full figure and "đồng", "cộng" or "trừ" before it as the sign
    /// shows (review 2026-10-31: "10,3tr", "1,2tỷ" and "đ" were read as written).
    private var spoken: String {
        let figure = abs(amount).formatted(.number.locale(.vietnam).precision(.fractionLength(0)))
        let sign: String
        switch tone {
        case .signedIncome: sign = "cộng "
        case .signedExpense, .outflow: sign = "trừ "
        case .signedNet, .neutral, .balance, .transfer, .muted: sign = amount < 0 ? "trừ " : (tone == .signedNet && amount > 0 ? "cộng " : "")
        }
        return "\(sign)\(figure) đồng"
    }

    var body: some View {
        Group {
            if size == .large || size == .display {
                // A lead figure stays whole and shrinks its type to fit, as it always has: two
                // columns of "-14.100.000đ" read better smaller than as "-14,1tr".
                label(text(compact: false))
            } else {
                ViewThatFits(in: .horizontal) {
                    label(text(compact: false))
                    label(text(compact: true))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .modifier(MoneyFont(size: size))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(size == .large || size == .display ? 0.5 : 0.8)
    }
}

private struct MoneyFont: ViewModifier {
    let size: MoneyText.Size

    func body(content: Content) -> some View {
        switch size {
        case .caption: content.textRole(.captionStrong).monospacedDigit()
        case .row: content.textRole(.amount)
        case .rowStrong: content.textRole(.bodyStrong).monospacedDigit()
        case .heading: content.textRole(.heading).monospacedDigit()
        case .large: content.textRole(.amountLarge)
        case .display: content.textRole(.display)
        }
    }
}
