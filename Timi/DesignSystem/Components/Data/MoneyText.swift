import SwiftUI

/// Every amount on screen: tabular digits, "đ" attached, sign and colour by meaning.
struct MoneyText: View {
    /// `caption`: a total beside a heading (a day's +/-).
    /// `heading`: a total inside a chart (Tổng chi in the ring).
    enum Size { case caption, row, heading, large, display }
    /// `muted`: grey, for money that does not count (a locked account). `signedNet`: a change
    /// either way, "+" in ink above zero and "-" in red below (Dư ra, a day's total).
    enum Tone { case plain, signedIncome, signedExpense, signedNet, negativeRed, muted }

    let amount: Double
    var size: Size = .row
    var tone: Tone = .plain
    var compact = false

    private var text: String {
        let value = compact ? abs(amount).vndCompact : abs(amount).vnd
        switch tone {
        case .signedIncome: return "+" + value
        case .signedExpense: return "-" + value
        case .signedNet: return (amount > 0 ? "+" : amount < 0 ? "-" : "") + value
        case .plain, .negativeRed, .muted: return (amount < 0 ? "-" : "") + value
        }
    }

    private var color: Color {
        switch tone {
        case .signedExpense: Palette.negative
        case .negativeRed, .signedNet: amount < 0 ? Palette.negative : Palette.label
        // Money in ink with its "+", money out red, everywhere (user choice 2026-10-30).
        case .signedIncome, .plain: Palette.label
        case .muted: Palette.secondaryLabel
        }
    }

    var body: some View {
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
        case .heading: content.textRole(.heading).monospacedDigit()
        case .large: content.textRole(.amountLarge)
        case .display: content.textRole(.display)
        }
    }
}
