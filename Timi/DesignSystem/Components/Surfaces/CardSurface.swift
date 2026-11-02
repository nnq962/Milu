import SwiftUI

extension View {
    /// A borderless solid surface with continuous corners and an optional light-mode shadow.
    /// Inside a `HeaderCard` it turns into a flat tile in `surfaceMuted` (the goal tiles), so a
    /// card never sits white on white.
    func cardSurface(radius: CGFloat = CardCorners.large, color: Color = Palette.surface, shadowed: Bool = true) -> some View {
        modifier(CardSurface(radius: radius, color: color, shadowed: shadowed))
    }

    /// Shared light-mode shadow for cards, chat bubbles and round action backgrounds.
    func cardShadow() -> some View {
        modifier(CardShadow())
    }
}

extension EnvironmentValues {
    /// True inside a `HeaderCard`: the card is already drawn, so `card()` and `listCard()` add
    /// none of their own and a tile drawn with `cardSurface` goes flat and grey.
    @Entry var isInHeaderCard = false
}

private struct CardSurface: ViewModifier {
    let radius: CGFloat
    let color: Color
    let shadowed: Bool

    @Environment(\.isInHeaderCard) private var isInHeaderCard

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .clipShape(shape)
            .background {
                if isInHeaderCard {
                    shape.fill(Palette.surfaceMuted)
                } else if shadowed {
                    shape.fill(color).cardShadow()
                } else {
                    shape.fill(color)
                }
            }
    }
}

/// No borders in either appearance; dark surfaces separate through their fill alone.
private struct CardShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        content
            // A close contact shadow under a soft one: the card sits on the page rather than
            // floating over it (user pick "D" 2026-11-02, with the page a step darker).
            .shadow(color: .black.opacity(isDark ? 0 : 0.05), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 7, x: 0, y: 4)
    }
}

extension View {
    /// A card holding rows (accounts, transactions, settings): no padding, the rows bring
    /// their own. One helper so every list card looks the same.
    /// Corners 24, as form groups: concentric with the rows' 16 inset and their ~9 icon corners
    /// (user report 2026-10-30: at 28 the corners crowded the first and last rows' icons).
    /// Inside a `HeaderCard` the rows go straight under its heading, with no card of their own.
    func listCard() -> some View {
        modifier(ListCard())
    }

    /// The app's card: 20 inside, large continuous corners and the light-mode shadow. Inside a
    /// `HeaderCard` only the padding stays, less of it on top, where the heading already is.
    func card(padding: CGFloat = Spacing.card, radius: CGFloat = CardCorners.large) -> some View {
        modifier(PaddedCard(padding: padding, radius: radius))
    }
}

private struct ListCard: ViewModifier {
    @Environment(\.isInHeaderCard) private var isInHeaderCard

    func body(content: Content) -> some View {
        if isInHeaderCard {
            content.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(radius: CardCorners.inset)
        }
    }
}

private struct PaddedCard: ViewModifier {
    let padding: CGFloat
    let radius: CGFloat

    @Environment(\.isInHeaderCard) private var isInHeaderCard

    func body(content: Content) -> some View {
        if isInHeaderCard {
            content
                .padding(.horizontal, padding)
                .padding(.bottom, padding)
                .padding(.top, Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(radius: radius)
        }
    }
}
