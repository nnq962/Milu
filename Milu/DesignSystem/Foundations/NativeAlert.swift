import UIKit

/// iOS's own centred alert, shown by UIKit from the frontmost screen rather than by SwiftUI's
/// `.alert`. In a sheet opened from another sheet (Giao dịch → a transaction → ✎), SwiftUI built
/// the form anew as its alert came up, and the alert's buttons then did nothing: "Xoá giao dịch"
/// closed the alert and deleted nothing (Simulator, iOS 26, 2026-11-13). Here each button keeps its
/// own action, whatever SwiftUI does to the view that asked.
@MainActor
enum NativeAlert {
    struct Button {
        enum Role { case cancel, destructive, plain }
        let title: String
        var role: Role = .plain
        var action: () -> Void = {}

        static func cancel(_ title: String = "Huỷ") -> Button { Button(title: title, role: .cancel) }
    }

    static func show(_ title: String, message: String? = nil, buttons: [Button]) {
        guard let presenter = frontmost() else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for button in buttons {
            let style: UIAlertAction.Style = switch button.role {
            case .cancel: .cancel
            case .destructive: .destructive
            case .plain: .default
            }
            alert.addAction(UIAlertAction(title: button.title, style: style) { _ in button.action() })
        }
        presenter.present(alert, animated: true)
    }

    /// The screen on top: the last sheet presented over the key window's root.
    private static func frontmost() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let next = top?.presentedViewController, !next.isBeingDismissed { top = next }
        return top
    }
}
