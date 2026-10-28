import SwiftUI

/// Every amount on screen: tabular digits, "đ" attached, sign and colour by meaning.
struct MoneyText: View {
    enum Size { case row, large, display }
    enum Tone { case plain, signedIncome, signedExpense, negativeRed }

    let amount: Double
    var size: Size = .row
    var tone: Tone = .plain
    var compact = false

    private var text: String {
        let value = compact ? abs(amount).vndCompact : abs(amount).vnd
        switch tone {
        case .signedIncome: return "+" + value
        case .signedExpense: return "-" + value
        case .plain, .negativeRed: return (amount < 0 ? "-" : "") + value
        }
    }

    private var color: Color {
        switch tone {
        case .signedExpense: Palette.red
        case .negativeRed: amount < 0 ? Palette.red : Palette.ink
        case .plain, .signedIncome: Palette.ink
        }
    }

    var body: some View {
        Text(text)
            .modifier(MoneyFont(size: size))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(size == .row ? 0.8 : 0.5)
    }
}

private struct MoneyFont: ViewModifier {
    let size: MoneyText.Size

    func body(content: Content) -> some View {
        switch size {
        case .row: content.textRole(.amount)
        case .large: content.textRole(.amountLarge).frame(minHeight: 32)
        case .display: content.textRole(.display).frame(minHeight: 42.5)
        }
    }
}
