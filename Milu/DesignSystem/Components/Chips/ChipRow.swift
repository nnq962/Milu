import SwiftUI

/// Horizontally scrolling filter chips: `TagChip`s, the chosen one filled in the primary colour.
/// Not glass (user choice 2026-10-31: glass only on the bars).
struct ChipRow<Option: Hashable & Identifiable>: View {
    @Binding var selection: Option
    let options: [Option]
    /// The words on each chip.
    let optionTitle: (Option) -> String

    var body: some View {
        // Scroll only when the chips overflow.
        ViewThatFits(in: .horizontal) {
            chips
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView(.horizontal) {
                chips
                    .padding(.horizontal, Spacing.page)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHiddenIfAvailable(true)
            // Bleed to the screen edges: the page margin, in and out.
            .padding(.horizontal, -Spacing.page)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var chips: some View {
        HStack(spacing: Spacing.s) {
            ForEach(options) { option in
                let selected = option == selection
                TagChip(title: optionTitle(option), isProminent: selected) { selection = option }
                    .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
