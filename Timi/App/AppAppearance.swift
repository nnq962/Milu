import SwiftUI
import UIKit

/// "Giao diện" in Cài đặt: follow the system, or keep Timi light or dark (user request 2026-10-31).
/// Set on the window itself, not with `preferredColorScheme`, so open sheets change with the page
/// and the change can cross-fade instead of snapping.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "Hệ thống"
        case .light: "Sáng"
        case .dark: "Tối"
        }
    }

    fileprivate var style: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }

    /// The saved choice; the system when none was made.
    static var saved: AppAppearance {
        UserDefaults.standard.string(forKey: StorageKey.appearance).flatMap(AppAppearance.init) ?? .system
    }

    /// Puts every window of the app in this appearance; `animated` cross-fades the whole screen
    /// (a fade, so it is fine with Reduce Motion too).
    func apply(animated: Bool) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows where window.overrideUserInterfaceStyle != style {
            if animated {
                UIView.transition(with: window, duration: 0.35,
                                  options: [.transitionCrossDissolve, .allowUserInteraction]) {
                    window.overrideUserInterfaceStyle = style
                }
            } else {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

/// Puts the saved appearance on the window as soon as the app's view joins it, before the first
/// frame shows. `onAppear` came too early: the window was not in its scene yet, so the app opened
/// light with "Tối" saved.
struct SavedAppearanceSetter: UIViewRepresentable {
    func makeUIView(context: Context) -> Setter { Setter() }
    func updateUIView(_ view: Setter, context: Context) {}

    final class Setter: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            window?.overrideUserInterfaceStyle = AppAppearance.saved.style
        }
    }
}
