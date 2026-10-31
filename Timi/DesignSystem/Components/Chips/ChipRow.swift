import SwiftUI

/// Horizontally scrolling filter chips: `TagChip`s, the chosen one filled in the primary colour.
/// Not glass (user choice 2026-10-31: glass only on the bars).
struct ChipRow<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

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
            .modifier(NoScrollEdgeEffect())
            // Bleed to the screen edges: the page margin, in and out.
            .padding(.horizontal, -Spacing.page)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var chips: some View {
        HStack(spacing: Spacing.s) {
            ForEach(options) { option in
                let selected = option == selection
                TagChip(title: title(option), isProminent: selected) { selection = option }
                    .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

/// iOS 26 draws a soft edge band behind a horizontal scroll view's content; a chip row needs none.
struct NoScrollEdgeEffect: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollEdgeEffectHidden(true, for: .all)
    }
}
