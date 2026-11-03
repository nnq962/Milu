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
                    Self.refreshHiddenBars(in: window)
                }
            } else {
                window.overrideUserInterfaceStyle = style
                Self.refreshHiddenBars(in: window)
            }
        }
    }

    /// The tabs not on screen take the new colours now, not when next shown: their bars kept the
    /// old ink until then, so a tab opened just after a switch showed its title and bar buttons
    /// dark on the dark page (or light on light) for a second or two (user report 2026-11-03).
    /// UIKit leaves views outside the window to update their traits lazily; this asks every view
    /// controller under the window, and the bars of each, to do it at once.
    private static func refreshHiddenBars(in window: UIWindow) {
        guard let root = window.rootViewController else { return }
        var stack = [root]
        while let controller = stack.popLast() {
            controller.updateTraitsIfNeeded()
            if let navigation = controller as? UINavigationController {
                navigation.navigationBar.updateTraitsIfNeeded()
                navigation.navigationBar.setNeedsLayout()
                navigation.navigationBar.layoutIfNeeded()
            }
            if let tabs = controller as? UITabBarController {
                tabs.tabBar.updateTraitsIfNeeded()
                stack.append(contentsOf: tabs.viewControllers ?? [])
            }
            stack.append(contentsOf: controller.children)
            if let presented = controller.presentedViewController { stack.append(presented) }
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
