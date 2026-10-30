import SwiftUI
import UIKit

/// Cài đặt → Giao diện: by the phone, or always light or dark.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "Theo hệ thống"
        case .light: "Sáng"
        case .dark: "Tối"
        }
    }

    /// Under the tiles in Cài đặt, where "Theo hệ thống" is too long.
    var shortTitle: String {
        switch self {
        case .system: "Theo máy"
        case .light: "Sáng"
        case .dark: "Tối"
        }
    }

    var icon: String {
        switch self {
        case .system: "hugeicons-smart-phone-01"
        case .light: "hugeicons-sun-03"
        case .dark: "hugeicons-moon-02"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }

    /// Sets every window's look; sheets and menus on it follow at once.
    func apply() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows { window.overrideUserInterfaceStyle = interfaceStyle }
        }
    }
}
