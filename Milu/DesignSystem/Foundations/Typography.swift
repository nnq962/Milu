import SwiftUI
import UIKit

/// CSS line boxes from the design, scaled along with the semantic font size.
private struct DesignLineHeight: ViewModifier {
    @ScaledMetric private var height: CGFloat

    init(_ height: CGFloat, relativeTo style: Font.TextStyle) {
        _height = ScaledMetric(wrappedValue: height, relativeTo: style)
    }

    // The exact line box on iOS 26; before it, the font's own (a little tighter for 2-line text).
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.lineHeight(.exact(points: height))
        } else {
            content
        }
    }
}

extension View {
    func designLineHeight(_ height: CGFloat, relativeTo style: Font.TextStyle) -> some View {
        modifier(DesignLineHeight(height, relativeTo: style))
    }
}

/// Apple's SF Pro Rounded, the system font's rounded design (user choice 2026-11-24, after
/// comparing it with Nunito, Be Vietnam Pro, Quicksand, Baloo 2 and Lexend: round as Nunito was,
/// tidier, with iOS's own Vietnamese marks and figures, and nothing to bundle). It was Nunito from
/// 2026-11-04 (Milu design system). Every size scales with Dynamic Type, as the text size the
/// view is shown at says (`miluFont`), so a view set smaller (`shrinksOnlyToFit`) shrinks its words.
enum Typography {
    /// The rounded system font at `size` points, no scaling. Its figures are proportional, its 1
    /// narrower than the others but with room each side ("Tháng 11"): SF's own drawing, measured
    /// 2026-11-24, not even widths; amounts in a column ask for even ones (`monospacedDigit()`).
    static func uiFont(size: CGFloat, weight: Font.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: uiWeight(weight))
        guard let rounded = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: rounded, size: size)
    }

    /// The same, scaled as `style` scales at `traits`' text size (the app's own when nil).
    static func scaledUIFont(_ style: Font.TextStyle, size: CGFloat, weight: Font.Weight = .regular,
                             maximumPointSize: CGFloat? = nil, traits: UITraitCollection? = nil) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: uiStyle(style))
        let font = uiFont(size: size, weight: weight)
        if let maximumPointSize {
            return metrics.scaledFont(for: font, maximumPointSize: maximumPointSize, compatibleWith: traits)
        }
        return metrics.scaledFont(for: font, compatibleWith: traits)
    }

    /// SwiftUI's rounded system font at `size` scaled for `typeSize`. Use `miluFont` in a view,
    /// which reads the text size from the view's own environment.
    static func font(_ style: Font.TextStyle, size: CGFloat, weight: Font.Weight = .regular,
                     at typeSize: DynamicTypeSize = .large) -> Font {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(typeSize))
        let scaled = UIFontMetrics(forTextStyle: uiStyle(style)).scaledValue(for: size, compatibleWith: traits)
        return .system(size: scaled, weight: weight, design: .rounded)
    }

    /// A size that does not scale on its own: for text sized from something already scaled (the
    /// initial inside an avatar that grows with the text).
    static func fixedFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    private static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        default: .regular
        }
    }

    static func uiStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }

    /// Segmented controls: selected SemiBold ink, others Medium muted, 14 scaled to `size`; iOS
    /// owns the shape. UIKit takes the font when a control is made, so a screen sets this for its
    /// own text size before making one (`ScaledSegmentedPicker`); set once at launch it stayed 14
    /// at every size (HIG review 2026-10-30).
    static func configureSegmentedControls(for size: DynamicTypeSize) {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
        let metrics = UIFontMetrics(forTextStyle: .subheadline)
        let medium = uiFont(size: 14, weight: .medium)
        let semibold = uiFont(size: 14, weight: .semibold)
        let segmented = UISegmentedControl.appearance()
        segmented.backgroundColor = Palette.uiFill
        segmented.selectedSegmentTintColor = Palette.uiSurface
        segmented.setTitleTextAttributes([.font: metrics.scaledFont(for: medium, compatibleWith: traits),
                                          .foregroundColor: Palette.uiSecondaryLabel], for: .normal)
        segmented.setTitleTextAttributes([.font: metrics.scaledFont(for: semibold, compatibleWith: traits),
                                          .foregroundColor: Palette.uiLabel], for: .selected)
    }

    static func configureNativeAppearance() {
        // Only text attributes: iOS owns the tab bar's material, geometry and icons. Medium 10,
        // as the Milu tab bar.
        let tabFont = uiFont(size: 10, weight: .medium)
        let appearance = UITabBarAppearance()
        for layout in [appearance.stackedLayoutAppearance,
                       appearance.inlineLayoutAppearance,
                       appearance.compactInlineLayoutAppearance] {
            layout.normal.titleTextAttributes = [.font: tabFont]
            layout.selected.titleTextAttributes = [.font: tabFont]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        configureSegmentedControls(for: .large)

        let navigation = UINavigationBar.appearance()
        navigation.titleTextAttributes = [.font: uiFont(size: 17, weight: .semibold)]
        // A large title, should a page show one (the tabs have none since 2026-11-04): the
        // `pageTitle` role, 24, scaled with Dynamic Type like the rest.
        let pageTitle = uiFont(size: TextRole.pageTitle.size, weight: TextRole.pageTitle.weight)
        // No colour of our own: a bar whose tab is not on screen kept the colour of the old
        // appearance after a switch of theme, dark words on the dark page until scrolled (user
        // report 2026-11-02). iOS's own label colour follows the theme in every bar.
        navigation.largeTitleTextAttributes = [
            .font: UIFontMetrics(forTextStyle: .title2).scaledFont(for: pageTitle),
        ]
        // The line under a native title (Trợ lý AI): the `caption` role, muted. Only an appearance
        // carries it; a transparent one, as iOS 26 bars have no background of their own, with the
        // same title fonts as above.
        let caption = uiFont(size: TextRole.caption.size, weight: TextRole.caption.weight)
        let subtitle: [NSAttributedString.Key: Any] = [
            .font: UIFontMetrics(forTextStyle: .caption1).scaledFont(for: caption),
            .foregroundColor: Palette.uiSecondaryLabel,
        ]
        let bar = UINavigationBarAppearance()
        bar.configureWithTransparentBackground()
        bar.titleTextAttributes = navigation.titleTextAttributes ?? [:]
        bar.largeTitleTextAttributes = navigation.largeTitleTextAttributes ?? [:]
        if #available(iOS 26.0, *) {
            bar.subtitleTextAttributes = subtitle
            bar.largeSubtitleTextAttributes = subtitle
        }
        if #available(iOS 26.0, *) {
            navigation.standardAppearance = bar
            navigation.scrollEdgeAppearance = bar
            navigation.compactAppearance = bar
        } else {
            // iOS 17 to 25, as its own apps: clear at the top (the sky runs on under the bar),
            // the system's blur and hairline once the page scrolls under it (user report
            // 2026-11-09: on iOS 17 the sheets' bars showed the page through, sharp).
            let scrolled = UINavigationBarAppearance()
            scrolled.configureWithDefaultBackground()
            scrolled.titleTextAttributes = bar.titleTextAttributes
            scrolled.largeTitleTextAttributes = bar.largeTitleTextAttributes
            navigation.standardAppearance = scrolled
            navigation.compactAppearance = scrolled
            navigation.scrollEdgeAppearance = bar
        }
    }
}

extension View {
    /// One line at its own size whenever it fits. When too wide, it steps down two text sizes
    /// (a couple of points), and only past that does it scale down freely, to `minimum`. Three
    /// tries, not six: each try is the text again, laid out on every showing, and six made the
    /// tabs take a second to appear (user report 2026-11-08). Plain `minimumScaleFactor` with the app's
    /// exact line height shrank words that fitted, and words a point too wide dropped to near
    /// the floor (the calendar, the tiles, every `MoneyText`; Simulator and review 2026-11-08).
    /// `alignment` places the words when they fill their slot after shrinking: `.center` in
    /// centred slots, so a shrunk "126tr" does not sit left of its neighbours.
    func shrinksOnlyToFit(_ minimum: CGFloat, alignment: TextAlignment = .leading) -> some View {
        modifier(ShrinksOnlyToFit(minimum: minimum, alignment: alignment))
    }
}

private struct ShrinksOnlyToFit: ViewModifier {
    let minimum: CGFloat
    let alignment: TextAlignment

    @Environment(\.dynamicTypeSize) private var size

    /// `steps` text sizes below the current one, no smaller than the smallest.
    private func smaller(_ steps: Int) -> DynamicTypeSize {
        let all = DynamicTypeSize.allCases
        let index = all.firstIndex(of: size) ?? 0
        return all[max(index - steps, 0)]
    }

    func body(content: Content) -> some View {
        ViewThatFits(in: .horizontal) {
            content.lineLimit(1).fixedSize()
            content.lineLimit(1).fixedSize().dynamicTypeSize(smaller(2))
            content.lineLimit(1)
                .minimumScaleFactor(minimum)
                .multilineTextAlignment(alignment)
                .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment == .center ? .center : alignment == .trailing ? .trailing : .leading, vertical: .center))
        }
    }
}
