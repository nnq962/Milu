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
        // Select the font's named instance rather than asking SwiftUI to synthesize a weight.
        let name: String
        switch weight {
        case .ultraLight, .thin: name = "Manrope-ExtraLight"
        case .light: name = "Manrope-Light"
        case .medium: name = "Manrope-Medium"
        case .semibold: name = "Manrope-SemiBold"
        case .bold: name = "Manrope-Bold"
        case .heavy, .black: name = "Manrope-ExtraBold"
        default: name = "Manrope-Regular"
        }
        return .custom(name, size: size, relativeTo: style)
    }

    static var body: Font { font(.body, size: 17) }
    static var headline: Font { font(.headline, size: 17, weight: .semibold) }
    static var subheadline: Font { font(.subheadline, size: 15) }
    static var callout: Font { font(.callout, size: 16) }
    static var footnote: Font { font(.footnote, size: 13) }
    static var caption: Font { font(.caption, size: 12) }
    static var caption2: Font { font(.caption2, size: 11) }
    static var title: Font { font(.title, size: 28) }
    static var title2: Font { font(.title2, size: 22) }
    static var title3: Font { font(.title3, size: 20) }

    static func configureNativeAppearance() {
        _ = registered
        guard let regular = UIFont(name: "Manrope-Regular", size: 10) else {
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
        if let medium = UIFont(name: "Manrope-Medium", size: 14), let semibold = UIFont(name: "Manrope-SemiBold", size: 14) {
            segmented.setTitleTextAttributes([.font: medium, .foregroundColor: UIColor(red: 89/255, green: 97/255, blue: 113/255, alpha: 1)], for: .normal)
            segmented.setTitleTextAttributes([.font: semibold, .foregroundColor: UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1)], for: .selected)
        }

        let navigation = UINavigationBar.appearance()
        navigation.titleTextAttributes = [.font: UIFont(name: "Manrope-SemiBold", size: 17) ?? regular.withSize(17)]
        navigation.largeTitleTextAttributes = [.font: UIFont(name: "Manrope-Bold", size: 34) ?? regular.withSize(34)]
    }
}
