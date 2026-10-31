import SwiftUI

/// Two or three figures side by side at one size, a hairline between them ("Đã chi | Đã thu" on
/// Thu chi, Tổng quan and Báo cáo, "Cho vay | Đi vay"): a small grey title, the amount
/// (`MoneyText(.large)`) and under it whatever the screen adds (how many people, the change
/// against the period before). Stacked, a hairline between, at the accessibility text sizes,
/// where two columns cut the figures short. One view for the four cards that drew it by hand
/// (design-system pass 2026-10-31).
struct SplitTotals<Detail: View>: View {
    typealias Item = SplitTotalItem

    let items: [Item]
    let detail: (Item) -> Detail

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(items: [Item], @ViewBuilder detail: @escaping (Item) -> Detail) {
        self.items = items
        self.detail = detail
    }

    var body: some View {
        let last = items.count - 1
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    column(item)
                        .padding(.top, index > 0 ? Spacing.m : 0)
                        .padding(.bottom, index < last ? Spacing.m : 0)
                        .overlay(alignment: .top) { if index > 0 { SplitLine() } }
                }
            }
        } else {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    column(item)
                        .padding(.leading, index > 0 ? Spacing.l : 0)
                        .padding(.trailing, index < last ? Spacing.l : 0)
                        .overlay(alignment: .trailing) { if index < last { VerticalDivider() } }
                }
            }
        }
    }

    @ViewBuilder
    private func column(_ item: Item) -> some View {
        let column = VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(item.title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
            MoneyText(amount: item.amount, size: .large, tone: item.tone)
            detail(item)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if let label = item.accessibilityLabel {
            column
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
        } else {
            column
                .accessibilityElement(children: .combine)
        }
    }
}

extension SplitTotals where Detail == EmptyView {
    init(items: [Item]) {
        self.init(items: items) { _ in EmptyView() }
    }
}

/// One column of `SplitTotals`. Outside the generic view so the column's type does not depend on
/// what sits under it.
struct SplitTotalItem: Identifiable {
    /// The title names the column: `detail` tells them apart by it.
    var id: String { title }
    let title: String
    let amount: Double
    var tone: MoneyText.Tone = .plain
    /// What VoiceOver says for the column; the words on screen when nil.
    var accessibilityLabel: String? = nil

    init(_ title: String, amount: Double, tone: MoneyText.Tone = .plain, accessibilityLabel: String? = nil) {
        self.title = title
        self.amount = amount
        self.tone = tone
        self.accessibilityLabel = accessibilityLabel
    }
}
