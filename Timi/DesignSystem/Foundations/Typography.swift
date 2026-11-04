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

/// Bundled Manrope; semantic styles retain Dynamic Type scaling.
enum Typography {
    private static let registered: Void = {
        guard let url = Bundle.main.url(forResource: "Manrope", withExtension: "ttf") else {
            assertionFailure("Missing bundled Manrope font")
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

    /// Each weight is the Manrope instance of its name (regular 400, medium 500, semibold 600,
    /// bold 700, heavy/black ExtraBold 800). It rendered one step lighter for a while; that read
    /// thin and fragile, and the weights went back to their names after trying other typefaces
    /// side by side (user choice 2026-10-30, over Be Vietnam Pro, Plus Jakarta Sans, Inter and
    /// SF Pro). Selects the font's named instance rather than asking SwiftUI to synthesize a weight.
    static func instance(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light: "Manrope-Light"
        case .medium: "Manrope-Medium"
        case .semibold: "Manrope-SemiBold"
        case .bold: "Manrope-Bold"
        case .heavy, .black: "Manrope-ExtraBold"
        default: "Manrope-Regular"
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
            assertionFailure("Manrope registration failed")
            return
        }
        // Only text attributes: iOS owns the tab bar's material, geometry and icons. SemiBold:
        // Regular read too thin under the filled icons (user request 2026-10-30). Named directly so
        // the lighter app-wide weights leave it as it is.
        let tabFont = UIFont(name: "Manrope-SemiBold", size: 10) ?? regular
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
