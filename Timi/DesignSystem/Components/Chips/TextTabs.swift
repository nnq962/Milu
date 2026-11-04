import SwiftUI

/// A row of words that pick what a list shows ("Tất cả · Thu · Chi · Chuyển khoản", user pick "B"
/// 2026-11-03 for Giao dịch, after chips read basic), the chosen one in ink over a short lime
/// line. One weight for every word, so choosing one does not shift the others. Scrolls when the
/// words overflow. The page itself ("Thu chi", "Vay nợ") is picked from a menu on the
/// bar (2026-11-04), no longer with a larger style of these.
struct TextTabs<Option: Hashable & Identifiable>: View {
    @Binding var selection: Option
    let options: [Option]
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
        HStack(spacing: Spacing.l) {
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
        .textRole(.body)
    }

    /// The line under every word, seen under the chosen one only, so the row keeps its height and
    /// its words their place.
    private func label(_ title: String, selected: Bool) -> some View {
        Text(title)
            .lineLimit(1)
            .fixedSize()
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
