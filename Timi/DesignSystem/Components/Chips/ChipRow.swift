import SwiftUI

/// Horizontally scrolling filter chips; the selected chip uses dark prominent glass.
struct ChipRow<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        // Scroll only when the chips overflow; a horizontal ScrollView behind glass
        // chips draws a lighter band across the row on iOS 26.
        ViewThatFits(in: .horizontal) {
            chips
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView(.horizontal) {
                chips
                    .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .modifier(NoScrollEdgeEffect())
            // Bleed to the screen edges like Sleek's -mx-5 px-5.
            .padding(.horizontal, -20)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// Group the glass chips so iOS renders them as one glass layer.
    @ViewBuilder
    private var chips: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer { chipStack }
        } else {
            chipStack
        }
    }

    private var chipStack: some View {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    let selected = option == selection
                    Button { selection = option } label: {
                        Text(title(option))
                            .textRole(.captionStrong)
                            .foregroundStyle(selected ? Color.white : Palette.ink)
                    }
                    .nativeGlassButton(prominent: selected, tint: selected ? Palette.primary : nil)
                    .buttonBorderShape(.capsule)
                    .controlSize(.regular)
                    .tint(Palette.ink)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
    }
}

/// iOS 26 draws a soft edge band behind a horizontal scroll view's content; a chip row needs none.
private struct NoScrollEdgeEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(true, for: .all)
        } else {
            content
        }
    }
}
