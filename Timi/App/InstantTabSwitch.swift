import SwiftUI
import UIKit

/// iOS 26 cross-fades between tabs: for a moment both pages show at once, which reads as the
/// screen going blurry, then sharp. This swaps the fade for the instant switch of earlier iOS
/// (and of most banking apps) by giving the tab bar controller an animator that finishes at once.
/// SwiftUI's own delegate keeps receiving every other call, so selection still works.
struct InstantTabSwitch: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Finder { Finder() }
    func updateUIViewController(_ controller: Finder, context: Context) {}

    final class Finder: UIViewController {
        private var proxy: DelegateProxy?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard proxy == nil, let tabs = tabBarController ?? findTabBarController() else { return }
            let proxy = DelegateProxy(original: tabs.delegate)
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

        init(original: UITabBarControllerDelegate?) {
            self.original = original
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
