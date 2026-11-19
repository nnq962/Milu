import AppIntents
import CoreText
import SwiftUI
import WidgetKit

/// A pill that opens the app at `link`.
struct WidgetButton: View {
    let title: String
    let icon: String
    let link: WidgetShared.Link
    let isPrimary: Bool

    var body: some View {
        Button(intent: OpenMiluIntent(link)) { label }
            .buttonStyle(.plain)
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .frame(width: 20, height: 20)
            Text(title)
                .font(WidgetFont.nunito(15, .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(isPrimary ? Palette.onPrimary : Palette.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(isPrimary ? Palette.primary : Palette.surface, in: .capsule)
        .contentShape(.capsule)
    }
}

extension Image {
    /// Resizable, and keeping Milu's own colours when the user tints the home screen (iOS 18
    /// and later).
    @ViewBuilder
    func miluFullColor() -> some View {
        if #available(iOS 18.0, *) {
            resizable().widgetAccentedRenderingMode(.fullColor)
        } else {
            resizable()
        }
    }
}

/// The app's Nunito (`Typography`), bundled with the widget too.
enum WidgetFont {
    private static let registered: Void = {
        if let url = Bundle.main.url(forResource: "Nunito", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    /// Fixed sizes: the widget is a fixed box, and grown text would push the buttons out.
    static func nunito(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        _ = registered
        let name = switch weight {
        case .black: "Nunito-Black"
        case .heavy: "Nunito-ExtraBold"
        case .bold: "Nunito-Bold"
        case .semibold: "Nunito-SemiBold"
        default: "Nunito-Medium"
        }
        return .custom(name, fixedSize: size)
    }
}
