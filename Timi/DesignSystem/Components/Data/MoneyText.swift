import SwiftUI

/// Every amount on screen: tabular digits, "đ" attached, sign and colour by meaning.
struct MoneyText: View {
    /// `caption`: a total beside a heading (a day's +/-).
    /// `heading`: a total inside a chart (Tổng chi in the ring).
    enum Size { case caption, row, heading, large, display }
    /// Named by what the figure is (review 2026-10-31: `negativeRed` named a colour):
    /// `balance` is a sum that may go below zero, red with "-" when it does (the default: a
    /// balance, net worth, a limit left); `neutral` never turns red (a transfer between accounts,
    /// a loan's principal); `signedIncome` "+" in ink, `signedExpense` "-" in red; `signedNet` a
    /// change either way, "+" in ink above zero and "-" in red below (Dư ra, a day's total);
    /// `muted` grey, for money that does not count (a locked account).
    enum Tone { case balance, neutral, signedIncome, signedExpense, signedNet, muted }

    let amount: Double
    var size: Size = .row
    var tone: Tone = .balance
    var compact = false

    private var text: String {
        let value = compact ? abs(amount).vndCompact : abs(amount).vnd
        switch tone {
        case .signedIncome: return "+" + value
        case .signedExpense: return "-" + value
        case .signedNet: return (amount > 0 ? "+" : amount < 0 ? "-" : "") + value
        case .neutral, .balance, .muted: return (amount < 0 ? "-" : "") + value
        }
    }

    private var color: Color {
        switch tone {
        case .signedExpense: Palette.negative
        case .balance, .signedNet: amount < 0 ? Palette.negative : Palette.label
        // Money in ink with its "+", money out red, everywhere (user choice 2026-10-30).
        case .signedIncome, .neutral: Palette.label
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
        case .signedExpense: sign = "trừ "
        case .signedNet, .neutral, .balance, .muted: sign = amount < 0 ? "trừ " : (tone == .signedNet && amount > 0 ? "cộng " : "")
        }
        return "\(sign)\(figure) đồng"
    }

    var body: some View {
        Text(text)
            .modifier(MoneyFont(size: size))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(size == .large || size == .display ? 0.5 : 0.8)
            .accessibilityLabel(spoken)
    }
}

private struct MoneyFont: ViewModifier {
    let size: MoneyText.Size

    func body(content: Content) -> some View {
        switch size {
        case .caption: content.textRole(.captionStrong).monospacedDigit()
        case .row: content.textRole(.amount)
        case .heading: content.textRole(.heading).monospacedDigit()
        case .large: content.textRole(.amountLarge)
        case .display: content.textRole(.display)
        }
    }
}
