import SwiftUI

/// The lead card of a screen: a small label, the big amount, an optional icon or logo on the
/// right, then whatever the screen adds below (a line, a bar, buttons). Used by "Tổng số dư", an
/// account's and a goal's screen, so they all read the same (user choice 2026-10-29: left-aligned).
struct SummaryCard<Content: View>: View {
    let label: String
    let amount: Double
    var icon: String? = nil
    var tone: MoneyText.Tone = .negativeRed
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(label)
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryText)
                    MoneyText(amount: amount, size: .display, tone: tone)
                }
                Spacer(minLength: 0)
                if let icon {
                    RowIcon(name: icon, size: RowMetrics.featureIcon)
                }
            }
            .accessibilityElement(children: .combine)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sleekCard(radius: CardCorners.extraLarge)
    }
}

extension SummaryCard where Content == EmptyView {
    init(label: String, amount: Double, icon: String? = nil, tone: MoneyText.Tone = .negativeRed) {
        self.init(label: label, amount: amount, icon: icon, tone: tone) { EmptyView() }
    }
}
