import SwiftUI

/// A row of words to choose from (user pick "B" 2026-11-03 for Giao dịch, after a segmented
/// control and chips read basic; "B+" the same day, as words alone read lifeless). `page` is the
/// larger pair that picks a page ("Thu chi · Vay nợ"), the chosen one an ink capsule with white
/// words; `filter` the smaller words that pick what a list shows ("Tất cả · Thu · Chi · Chuyển
/// khoản"), the chosen one in ink over a short lime line. One weight for every word, so choosing
/// one does not shift the others. Scrolls when the words overflow.
struct TextTabs<Option: Hashable & Identifiable>: View {
    enum Style {
        case page, filter
    }

    @Binding var selection: Option
    let options: [Option]
    var style: Style = .filter
    /// The words for each option.
    let optionTitle: (Option) -> String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView(.horizontal) {
                row
                    .padding(.horizontal, Spacing.page)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHiddenIfAvailable(true)
            // Bleed to the screen edges: the page margin, in and out.
            .padding(.horizontal, -Spacing.page)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var row: some View {
        HStack(spacing: style == .page ? Spacing.xs : Spacing.l) {
            ForEach(options) { option in
                let selected = option == selection
                Button { selection = option } label: {
                    label(optionTitle(option), selected: selected)
                        // 44 tall, the words in the middle, so each takes a full tap.
                        .frame(minHeight: ControlHeight.regular)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .textRole(style == .page ? .title : .body)
    }

    @ViewBuilder
    private func label(_ title: String, selected: Bool) -> some View {
        let words = Text(title)
            .lineLimit(1)
            .fixedSize()
        switch style {
        case .page:
            words
                .foregroundStyle(selected ? Palette.onPrimary : Palette.secondaryLabel)
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: ControlHeight.small)
                .background(selected ? Palette.primary : .clear, in: Capsule())
        case .filter:
            // The line under every word, seen under the chosen one only, so the row keeps its
            // height and its words their place.
            words
                .foregroundStyle(selected ? Palette.label : Palette.secondaryLabel)
                .padding(.bottom, Spacing.s)
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(Palette.accent)
                        .frame(height: 3)
                        .opacity(selected ? 1 : 0)
                }
        }
    }
}
