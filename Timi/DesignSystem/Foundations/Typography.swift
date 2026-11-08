import SwiftUI
import UIKit
import CoreText

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

/// Bundled Nunito, the variable font with Vietnamese (Milu design system 2026-11-04: Nunito for
/// headings, words, buttons and amounts; SF only where iOS draws the text itself). Semantic styles
/// keep Dynamic Type scaling.
enum Typography {
    private static let registered: Void = {
        guard let url = Bundle.main.url(forResource: "Nunito", withExtension: "ttf") else {
            assertionFailure("Missing bundled Nunito font")
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    static func font(_ style: Font.TextStyle, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        _ = registered
        return .custom(instance(for: weight), size: size, relativeTo: style)
    }

    /// A size that does not scale on its own: for text sized from something already scaled (the
    /// initial inside an avatar that grows with the text).
    static func fixedFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        _ = registered
        return .custom(instance(for: weight), fixedSize: size)
    }

    /// Each weight is the Nunito instance of its name (regular 400, medium 500, semibold 600,
    /// bold 700, heavy ExtraBold 800, black 900). Selects the font's named instance rather than
    /// asking SwiftUI to synthesize a weight.
    static func instance(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light: "Nunito-Light"
        case .medium: "Nunito-Medium"
        case .semibold: "Nunito-SemiBold"
        case .bold: "Nunito-Bold"
        case .heavy: "Nunito-ExtraBold"
        case .black: "Nunito-Black"
        default: "Nunito-Regular"
        }
    }

    /// Segmented controls: selected SemiBold ink, others Medium muted, 14 scaled to `size`; iOS
    /// owns the shape. UIKit takes the font when a control is made, so a screen sets this for its
    /// own text size before making one (`ScaledSegmentedPicker`); set once at launch it stayed 14
    /// at every size (HIG review 2026-10-30).
    static func configureSegmentedControls(for size: DynamicTypeSize) {
        _ = registered
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
        let metrics = UIFontMetrics(forTextStyle: .subheadline)
        guard let medium = UIFont(name: instance(for: .medium), size: 14),
              let semibold = UIFont(name: instance(for: .semibold), size: 14) else { return }
        let segmented = UISegmentedControl.appearance()
        segmented.backgroundColor = Palette.uiFill
        segmented.selectedSegmentTintColor = Palette.uiSurface
        segmented.setTitleTextAttributes([.font: metrics.scaledFont(for: medium, compatibleWith: traits),
                                          .foregroundColor: Palette.uiSecondaryLabel], for: .normal)
        segmented.setTitleTextAttributes([.font: metrics.scaledFont(for: semibold, compatibleWith: traits),
                                          .foregroundColor: Palette.uiLabel], for: .selected)
    }

    static func configureNativeAppearance() {
        _ = registered
        guard let regular = UIFont(name: instance(for: .regular), size: 10) else {
            assertionFailure("Nunito registration failed")
            return
        }
        // Only text attributes: iOS owns the tab bar's material, geometry and icons. Nunito
        // SemiBold 10, as the Milu tab bar.
        let tabFont = UIFont(name: "Nunito-SemiBold", size: 10) ?? regular
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
        navigation.titleTextAttributes = [.font: UIFont(name: instance(for: .semibold), size: 17) ?? regular.withSize(17)]
        // A large title, should a page show one (the tabs have none since 2026-11-04): the
        // `pageTitle` role, 24, scaled with Dynamic Type like the rest.
        let pageTitle = UIFont(name: instance(for: TextRole.pageTitle.weight), size: TextRole.pageTitle.size) ?? regular.withSize(TextRole.pageTitle.size)
        // No colour of our own: a bar whose tab is not on screen kept the colour of the old
        // appearance after a switch of theme, dark words on the dark page until scrolled (user
        // report 2026-11-02). iOS's own label colour follows the theme in every bar.
        navigation.largeTitleTextAttributes = [
            .font: UIFontMetrics(forTextStyle: .title2).scaledFont(for: pageTitle),
        ]
        // The line under a native title (Trợ lý AI): the `caption` role, muted. Only an appearance
        // carries it; a transparent one, as iOS 26 bars have no background of their own, with the
        // same title fonts as above.
        let caption = UIFont(name: instance(for: TextRole.caption.weight), size: TextRole.caption.size) ?? regular.withSize(TextRole.caption.size)
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
        navigation.standardAppearance = bar
        navigation.scrollEdgeAppearance = bar
        navigation.compactAppearance = bar
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
