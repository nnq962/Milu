import SwiftUI
import UIKit
import CoreText

/// CSS line boxes from the design, scaled along with the semantic font size.
private struct DesignLineHeight: ViewModifier {
    @ScaledMetric private var height: CGFloat

    init(_ height: CGFloat, relativeTo style: Font.TextStyle) {
        _height = ScaledMetric(wrappedValue: height, relativeTo: style)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.lineHeight(.exact(points: height))
        } else {
            content.frame(minHeight: height)
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

    /// Manrope draws thin, so every weight renders one step heavier, as on the web design system
    /// (`font-normal` 500, `medium` 600, `semibold` 700, `bold` 800). Code keeps naming the intended
    /// weight; only this mapping knows about the shift. User request 2026-10-28.
    /// Selects the font's named instance rather than asking SwiftUI to synthesize a weight.
    static func instance(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin: "Manrope-Light"
        case .light: "Manrope-Regular"
        case .medium: "Manrope-SemiBold"
        case .semibold: "Manrope-Bold"
        case .bold, .heavy, .black: "Manrope-ExtraBold"
        default: "Manrope-Medium"
        }
    }

    static var body: Font { font(.body, size: 17) }

    static func configureNativeAppearance() {
        _ = registered
        guard let regular = UIFont(name: instance(for: .regular), size: 10) else {
            assertionFailure("Manrope registration failed")
            return
        }
        // Only text attributes: iOS owns the tab bar's material, geometry and icons.
        let appearance = UITabBarAppearance()
        for layout in [appearance.stackedLayoutAppearance,
                       appearance.inlineLayoutAppearance,
                       appearance.compactInlineLayoutAppearance] {
            layout.normal.titleTextAttributes = [.font: regular]
            layout.selected.titleTextAttributes = [.font: regular]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Sleek segmented control: selected SemiBold ink, others Medium muted; iOS owns the shape.
        let segmented = UISegmentedControl.appearance()
        if let medium = UIFont(name: instance(for: .medium), size: 14), let semibold = UIFont(name: instance(for: .semibold), size: 14) {
            segmented.setTitleTextAttributes([.font: medium, .foregroundColor: UIColor(Palette.secondaryText)], for: .normal)
            segmented.setTitleTextAttributes([.font: semibold, .foregroundColor: UIColor(Palette.ink)], for: .selected)
        }

        let navigation = UINavigationBar.appearance()
        navigation.titleTextAttributes = [.font: UIFont(name: instance(for: .semibold), size: 17) ?? regular.withSize(17)]
        navigation.largeTitleTextAttributes = [.font: UIFont(name: instance(for: .bold), size: 34) ?? regular.withSize(34)]
    }
}
