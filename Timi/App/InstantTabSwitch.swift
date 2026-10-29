import SwiftUI
import UIKit

/// iOS 26 cross-fades between tabs: for a moment both pages show at once, which reads as the
/// screen going blurry, then sharp. This swaps the fade for the instant switch of earlier iOS
/// (and of most banking apps) by giving the tab bar controller an animator that finishes at once.
/// SwiftUI's own delegate keeps receiving every other call, so selection still works.
///
/// It also answers taps on the last tab, the + beside the bar (`AppTab.add`): that tab is never
/// selected, so the page never switches to its empty view and back (a white flash), and
/// `onAddTab` runs instead.
struct InstantTabSwitch: UIViewControllerRepresentable {
    var onAddTab: () -> Void = {}

    func makeUIViewController(context: Context) -> Finder { Finder() }
    func updateUIViewController(_ controller: Finder, context: Context) {
        controller.onAddTab = onAddTab
    }

    final class Finder: UIViewController {
        private var proxy: DelegateProxy?
        var onAddTab: () -> Void = {} {
            didSet { proxy?.onAddTab = onAddTab }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard proxy == nil, let tabs = tabBarController ?? findTabBarController() else { return }
            let proxy = DelegateProxy(original: tabs.delegate)
            proxy.onAddTab = onAddTab
            self.proxy = proxy
            tabs.delegate = proxy
        }

        private func findTabBarController() -> UITabBarController? {
            var node: UIViewController? = view.window?.rootViewController
            var queue = [node].compactMap { $0 }
            while !queue.isEmpty {
                node = queue.removeFirst()
                if let tabs = node as? UITabBarController { return tabs }
                queue += node?.children ?? []
            }
            return nil
        }
    }

    /// Answers the transition question itself and forwards everything else to SwiftUI's delegate.
    final class DelegateProxy: NSObject, UITabBarControllerDelegate {
        weak var original: UITabBarControllerDelegate?
        var onAddTab: () -> Void = {}

        init(original: UITabBarControllerDelegate?) {
            self.original = original
        }

        /// iOS 18+ (SwiftUI's `Tab`): the + is the search-role tab, set apart beside the bar.
        @available(iOS 18.0, *)
        func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
            if tab is UISearchTab || tab === tabBarController.tabs.last {
                onAddTab()
                return false
            }
            return original?.tabBarController?(tabBarController, shouldSelectTab: tab) ?? true
        }

        /// iOS 17: the + is the fifth tab.
        func tabBarController(_ tabBarController: UITabBarController,
                              shouldSelect viewController: UIViewController) -> Bool {
            if let controllers = tabBarController.viewControllers, controllers.count == 5,
               viewController === controllers.last {
                onAddTab()
                return false
            }
            return original?.tabBarController?(tabBarController, shouldSelect: viewController) ?? true
        }

        func tabBarController(_ tabBarController: UITabBarController,
                              animationControllerForTransitionFrom fromVC: UIViewController,
                              to toVC: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
            InstantAnimator()
        }

        override func responds(to selector: Selector!) -> Bool {
            super.responds(to: selector) || (original?.responds(to: selector) ?? false)
        }

        override func forwardingTarget(for selector: Selector!) -> Any? {
            original?.responds(to: selector) == true ? original : super.forwardingTarget(for: selector)
        }
    }

    final class InstantAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using context: (any UIViewControllerContextTransitioning)?) -> TimeInterval { 0 }

        func animateTransition(using context: any UIViewControllerContextTransitioning) {
            if let toView = context.view(forKey: .to) {
                context.containerView.addSubview(toView)
            }
            context.completeTransition(!context.transitionWasCancelled)
        }
    }
}
