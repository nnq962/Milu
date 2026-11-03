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

    /// What a window is set to: light or dark as chosen, or with "Hệ thống" the system's look of
    /// the moment (the scene's, which follows the system whatever the window is set to), set as
    /// if chosen and set again each time the system's changes (`SavedAppearanceSetter`). Left to
    /// follow the system by itself, a tab not on screen kept its old glass in the bars after a
    /// change of the system's (Simulator check 2026-11-03).
    fileprivate func style(for window: UIWindow) -> UIUserInterfaceStyle {
        guard self == .system else { return style }
        return window.windowScene?.traitCollection.userInterfaceStyle ?? .unspecified
    }

    /// Puts every window of the app in this appearance; `animated` cross-fades the whole screen
    /// (a fade, so it is fine with Reduce Motion too).
    func apply(animated: Bool) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows {
            let style = style(for: window)
            guard window.overrideUserInterfaceStyle != style else { continue }
            if animated {
                UIView.transition(with: window, duration: 0.35,
                                  options: [.transitionCrossDissolve, .allowUserInteraction]) {
                    window.overrideUserInterfaceStyle = style
                    Self.pinTabs(in: window)
                }
            } else {
                window.overrideUserInterfaceStyle = style
                Self.pinTabs(in: window)
            }
        }
    }

    /// The tabs not on screen take the new colours now, not when next shown: a tab already opened
    /// once kept the old appearance in its bar for a second or two after it came back (dark title
    /// and buttons on the light page, user reports 2026-11-03). UIKit holds back the traits of a
    /// bar that is not in the window, even once its tab has the new ones (logged: tab light, its
    /// navigation bar still dark), so each tab and each bar under it is given the window's.
    static func pinTabs(in window: UIWindow) {
        let style = window.overrideUserInterfaceStyle
        for tab in tabControllers(under: window.rootViewController) {
            tab.overrideUserInterfaceStyle = style
            for bar in navigationBars(under: tab) {
                bar.overrideUserInterfaceStyle = style
                // Its buttons' glass too, which otherwise faded over on the tab's return.
                refreshTraits(of: bar)
            }
        }
    }

    private static func refreshTraits(of view: UIView) {
        view.updateTraitsIfNeeded()
        view.subviews.forEach(refreshTraits(of:))
    }

    /// The root of each tab: the children of every tab bar controller under `root`.
    private static func tabControllers(under root: UIViewController?) -> [UIViewController] {
        guard let root else { return [] }
        var found: [UIViewController] = []
        var stack = [root]
        while let controller = stack.popLast() {
            if let tabBar = controller as? UITabBarController {
                found.append(contentsOf: tabBar.viewControllers ?? [])
            }
            stack.append(contentsOf: controller.children)
        }
        return found
    }

    /// The navigation bars of a tab, pushed pages and all.
    private static func navigationBars(under root: UIViewController) -> [UINavigationBar] {
        var found: [UINavigationBar] = []
        var stack = [root]
        while let controller = stack.popLast() {
            if let navigation = controller as? UINavigationController { found.append(navigation.navigationBar) }
            stack.append(contentsOf: controller.children)
        }
        return found
    }
}

/// Puts the saved appearance on the window as soon as the app's view joins it, before the first
/// frame shows. `onAppear` came too early: the window was not in its scene yet, so the app opened
/// light with "Tối" saved.
struct SavedAppearanceSetter: UIViewRepresentable {
    func makeUIView(context: Context) -> Setter { Setter() }
    func updateUIView(_ view: Setter, context: Context) {}

    final class Setter: UIView {
        private var isWatching = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window else { return }
            window.overrideUserInterfaceStyle = AppAppearance.saved.style(for: window)
            // With "Hệ thống", each change of the system's look is set on the window as if chosen.
            guard !isWatching, let scene = window.windowScene else { return }
            isWatching = true
            scene.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (_: UIWindowScene, _) in
                // Cross-faded as a change made in Cài đặt: set without it, the glass of a tab's bar
                // and of the tab bar kept drawing the old look although every trait was the new one
                // (logged 2026-11-03).
                if AppAppearance.saved == .system { AppAppearance.system.apply(animated: true) }
            }
            // The tabs are made after this view joins the window: pin them once they are there.
            DispatchQueue.main.async { [weak self] in
                if let window = self?.window { AppAppearance.pinTabs(in: window) }
            }
        }
    }
}
