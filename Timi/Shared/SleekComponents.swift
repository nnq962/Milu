import SwiftUI

/// Hairline starting after a 44pt icon: 16 padding + 44 + 12 gap.
/// Use as a top overlay so it adds no row height, like Sleek's absolute divider.
struct RowDivider: View {
    var body: some View {
        Palette.border
            .frame(height: 1)
            .padding(.leading, 72)
    }
}

/// Rounded track with a filled portion; Sleek uses 8pt or 10pt heights.
struct ProgressBar: View {
    let value: Double
    var color: Color = Palette.lime
    var height: CGFloat = 10

    var body: some View {
        Capsule()
            .fill(Palette.muted)
            .frame(height: height)
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
            .font(Typography.font(.callout, size: 16, weight: .semibold))
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
                .font(Typography.font(.headline, size: 16, weight: .semibold))
                .designLineHeight(24, relativeTo: .headline)
            Spacer(minLength: 8)
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
            // Bleed to the screen edges like Sleek's -mx-5 px-5.
            .padding(.horizontal, -20)
        }
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
                            .font(Typography.font(.caption, size: 12, weight: selected ? .semibold : .medium))
                            .foregroundStyle(selected ? Color.white : Palette.ink)
                    }
                    .nativeGlassButton(prominent: selected, tint: selected ? Palette.ink : nil)
                    .buttonBorderShape(.capsule)
                    .controlSize(.regular)
                    .tint(Palette.ink)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
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
                .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                .padding(.top, 12)
            Text(message)
                .font(Typography.font(.caption, size: 12))
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
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
