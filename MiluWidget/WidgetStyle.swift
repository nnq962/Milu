import AppIntents
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
                .font(WidgetFont.rounded(15, .heavy))
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

/// The app's font (`Typography`): SF Pro Rounded, the system's rounded design (2026-11-24).
enum WidgetFont {
    /// Fixed sizes: the widget is a fixed box, and grown text would push the buttons out.
    /// Each weight two steps lighter than it was named for Nunito, as the app's (`TextRole.weight`).
    static func rounded(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        let lighter: Font.Weight = switch weight {
        case .black: .bold
        case .heavy: .semibold
        case .bold: .medium
        case .semibold: .medium
        case .medium: .regular
        default: weight
        }
        return .system(size: size, weight: lighter, design: .rounded)
    }
}
