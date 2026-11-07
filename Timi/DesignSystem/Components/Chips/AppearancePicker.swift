import SwiftUI

/// Visual theme choices, as iOS's own Display & Brightness: a tall miniature of the app in each
/// look, its name, and a round tick under it (user request 2026-10-31: the flat 62×35 cards read
/// too small). The samples keep their own colour scheme, independent of the page. Only the
/// binding changes here; the caller decides whether to apply it to the app or preview it.
struct AppearancePicker: View {
    @Binding var selection: AppAppearance
    @Environment(\.dynamicTypeSize) private var typeSize

    private let options: [AppAppearance] = [.light, .dark, .system]

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.l))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.l))
        layout {
            ForEach(options) { option in
                choice(option)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.l)
        .cardSurface(radius: CardCorners.card)
    }

    private func choice(_ option: AppAppearance) -> some View {
        let selected = selection == option
        return Button {
            selection = option
        } label: {
            Group {
                if typeSize.isAccessibilitySize {
                    // Beside its words at the accessibility sizes, a fixed width so the words get room.
                    HStack(spacing: Spacing.l) {
                        AppearanceSample(appearance: option, isSelected: selected)
                            .frame(width: AppearanceSample.compactWidth)
                        Text(option.title)
                            .textRole(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SelectionDot(isSelected: selected)
                    }
                } else {
                    VStack(spacing: Spacing.s) {
                        AppearanceSample(appearance: option, isSelected: selected)
                        Text(option.title)
                            .textRole(selected ? .captionStrong : .caption)
                            .foregroundStyle(selected ? Palette.label : Palette.secondaryLabel)
                            .lineLimit(1)
                        SelectionDot(isSelected: selected)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        .accessibilityLabel(option == .system ? "Theo hệ thống" : option.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// The round mark under a choice: a tick on the primary colour when chosen, an empty ring otherwise.
private struct SelectionDot: View {
    let isSelected: Bool

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Palette.primary : .clear)
            Circle()
                .strokeBorder(isSelected ? Palette.primary : Palette.tertiaryLabel, lineWidth: 1.5)
            if isSelected {
                TimiIcon("hugeicons-tick-02", size: size * 0.6)
                    .foregroundStyle(Palette.onPrimary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A miniature screen of the app in one look: the page, a title, the lead card with its figure,
/// two rows and the tab bar. "Hệ thống" is the light one on the left half, the dark on the right.
private struct AppearanceSample: View {
    let appearance: AppAppearance
    let isSelected: Bool

    /// Its width beside the words at the accessibility sizes.
    static let compactWidth: CGFloat = 64
    /// A phone's proportions, a little shorter.
    private static let aspect: CGFloat = 0.62
    private static let radius: CGFloat = 14
    /// The ring around the chosen one, and the gap between it and the screen.
    private static let ring: CGFloat = 2.5
    private static let gap: CGFloat = 3

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        ZStack {
            screen.environment(\.colorScheme, appearance == .light ? .light : .dark)
            if appearance == .system {
                screen
                    .environment(\.colorScheme, .light)
                    .mask {
                        GeometryReader { proxy in
                            Rectangle().frame(width: proxy.size.width / 2)
                        }
                    }
            }
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Palette.separator, lineWidth: 1) }
        .padding(Self.gap + Self.ring)
        .overlay {
            RoundedRectangle(cornerRadius: Self.radius + Self.gap + Self.ring, style: .continuous)
                .strokeBorder(isSelected ? Palette.primary : .clear, lineWidth: Self.ring)
        }
        .accessibilityHidden(true)
    }

    /// Sized from its own width, so it reads the same at any column width.
    private var screen: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let pad = w * 0.11
            let bar = w * 0.045
            VStack(alignment: .leading, spacing: w * 0.07) {
                // The page's title.
                Capsule().fill(Palette.label)
                    .frame(width: w * 0.42, height: bar * 1.3)
                // The lead card: a small label over the large figure.
                VStack(alignment: .leading, spacing: w * 0.05) {
                    Capsule().fill(Palette.tertiaryLabel)
                        .frame(width: w * 0.28, height: bar)
                    Capsule().fill(Palette.label)
                        .frame(width: w * 0.5, height: bar * 1.6)
                }
                .padding(w * 0.07)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: w * 0.09, style: .continuous))
                // Two rows on a card, the second amount in the money-out colour.
                VStack(spacing: w * 0.06) {
                    row(width: w, bar: bar, amount: Palette.label)
                    row(width: w, bar: bar, amount: Palette.negative)
                }
                .padding(w * 0.07)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: w * 0.09, style: .continuous))
                Spacer(minLength: 0)
                // The tab bar.
                Capsule().fill(Palette.surface)
                    .frame(height: w * 0.14)
                    .overlay {
                        HStack(spacing: w * 0.1) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle().fill(index == 0 ? Palette.label : Palette.tertiaryLabel)
                                    .frame(width: bar * 1.4, height: bar * 1.4)
                            }
                        }
                    }
            }
            .padding(pad)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .background(Palette.background)
        }
    }

    private func row(width w: CGFloat, bar: CGFloat, amount: Color) -> some View {
        HStack(spacing: w * 0.05) {
            Circle().fill(Palette.surfaceMuted)
                .frame(width: bar * 2.4, height: bar * 2.4)
            Capsule().fill(Palette.secondaryLabel)
                .frame(width: w * 0.22, height: bar)
            Spacer(minLength: 0)
            Capsule().fill(amount)
                .frame(width: w * 0.14, height: bar)
        }
    }
}
