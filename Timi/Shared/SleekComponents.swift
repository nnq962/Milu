import SwiftUI

/// Hairline starting after a 44pt icon: 16 padding + 44 + 12 gap.
/// Use as a top overlay so it adds no row height, like Sleek's absolute divider.
struct RowDivider: View {
    @Environment(\.formIconStyle) private var iconStyle

    var body: some View {
        Palette.border
            .frame(height: 1)
            .padding(.leading, iconStyle == .plain ? RowMetrics.dividerInset : 72)
    }
}

/// Rounded track with a filled portion; every progress bar in the app is 8pt tall.
struct ProgressBar: View {
    static let height: CGFloat = 8

    let value: Double
    var color: Color = Palette.primary

    /// Spending against a limit: green below 80%, amber from 80%, red once it is used up.
    static func budgetColor(_ ratio: Double) -> Color {
        switch ratio {
        case ..<0.8: Palette.green
        case ..<1: Palette.warning
        default: Palette.red
        }
    }

    var body: some View {
        Capsule()
            .fill(Palette.muted)
            .frame(height: Self.height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * min(max(value, 0), 1))
                }
            }
            .clipShape(Capsule())
    }
}

/// 44pt circle holding a Solar/MDI icon.
struct IconCircle: View {
    let icon: String
    var iconSize: CGFloat = 20
    var background: Color = Palette.muted

    var body: some View {
        SolarIcon(icon, size: iconSize)
            .foregroundStyle(Palette.ink)
            .frame(width: 44, height: 44)
            .background(background, in: Circle())
    }
}

/// 44pt circle with a person's initial, standing in for profile photos.
struct InitialsAvatar: View {
    let name: String

    var body: some View {
        Text(String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
            .textRole(.title)
            .foregroundStyle(Palette.ink)
            .frame(width: 44, height: 44)
            .background(Palette.muted, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Section heading with an optional trailing view (badge or summary text).
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title)
                .textRole(.title)
            Spacer(minLength: Spacing.s)
            trailing
        }
        .padding(.horizontal, 4)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

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

/// Empty list placeholder from the Sleek component sheet.
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            SolarIcon(icon, size: 26)
                .foregroundStyle(Palette.secondary)
                .frame(width: 56, height: 56)
                .background(Palette.muted, in: Circle())
            Text(title)
                .textRole(.title)
                .padding(.top, Spacing.m)
            Text(message)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .sleekCard(padding: 24, radius: CardCorners.extraLarge)
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// White Sleek card: p-5, large continuous corners and the soft shadow.
    func sleekCard(padding: CGFloat = 20, radius: CGFloat = CardCorners.large) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: radius, color: Palette.card, elevated: true)
    }
}
