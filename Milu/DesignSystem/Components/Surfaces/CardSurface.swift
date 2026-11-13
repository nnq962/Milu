import SwiftUI

extension View {
    /// A solid surface with continuous corners and Milu's quiet 1pt edge (Border/Quiet); no
    /// shadow, as Milu keeps shadows for what truly floats over the content.
    /// Inside a `HeaderCard` it turns into a flat tile in `surfaceMuted` (the goal tiles), so a
    /// card never sits white on white.
    func cardSurface(radius: CGFloat = CardCorners.card, color: Color = Palette.surface, outlined: Bool = true) -> some View {
        modifier(CardSurface(radius: radius, color: color, outlined: outlined))
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
    /// True inside a sheet (`miluSheetStyle`, `SheetScaffold`): pages there stand on the card's
    /// colour, white by day and blue at night (Milu: Surface/Card is "thẻ, ô nhập và toàn bộ sheet",
    /// user request 2026-11-05), not on the page's pale blue.
    @Entry var isInSheet = false
}

/// The ground of a page: Surface/Canvas on a tab or a pushed page, Surface/Card inside a sheet,
/// pushed pages within it included.
struct PageBackground: View {
    @Environment(\.isInSheet) private var isInSheet

    var body: some View {
        isInSheet ? Palette.surface : Palette.background
    }
}

extension View {
    /// `PageBackground` behind the view: the page colour, or the sheet's in a sheet.
    func pageBackground() -> some View {
        // Under the bars and the home indicator too, as a plain colour background does (user
        // report 2026-11-05: as a view it stopped at the safe area, black above and below).
        background { PageBackground().ignoresSafeArea() }
    }
}

private struct CardSurface: ViewModifier {
    let radius: CGFloat
    let color: Color
    let outlined: Bool

    @Environment(\.isInHeaderCard) private var isInHeaderCard

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .environment(\.rowGround, isInHeaderCard ? Palette.surfaceMuted : color)
            .clipShape(shape)
            .background {
                if isInHeaderCard {
                    shape.fill(Palette.surfaceMuted)
                } else {
                    shape.fill(color)
                }
            }
            .overlay {
                if !isInHeaderCard && outlined {
                    shape.strokeBorder(Palette.separator, lineWidth: 1)
                }
            }
    }
}

/// A shadow in light only; in dark the surfaces separate through their fill alone.
private struct CardShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        content
            // A close contact shadow under a soft one: the card sits on the page rather than
            // floating over it (user pick "D" 2026-11-02, with the page a step darker). Well under
            // half the earlier 5% and 4%, and a little closer (user 2026-11-03, twice: too strong
            // on the cream page).
            .shadow(color: .black.opacity(isDark ? 0 : 0.02), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(isDark ? 0 : 0.018), radius: 6, x: 0, y: 3)
    }
}

extension View {
    /// A card holding rows (accounts, transactions, settings): no padding, the rows bring
    /// their own. One helper so every list card looks the same.
    /// Corners `CardCorners.card` (26, iOS 26's grouped lists), as form groups.
    /// Inside a `HeaderCard` the rows go straight under its heading, with no card of their own.
    func listCard() -> some View {
        modifier(ListCard())
    }

    /// The app's card: 20 inside, large continuous corners and the light-mode shadow. Inside a
    /// `HeaderCard` only the padding stays, less of it on top, where the heading already is.
    func card(padding: CGFloat = Spacing.card, radius: CGFloat = CardCorners.card) -> some View {
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
                .cardSurface(radius: CardCorners.card)
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
