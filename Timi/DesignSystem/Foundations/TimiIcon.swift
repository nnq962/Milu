import SwiftUI

/// An icon from the asset catalog (Hugeicons Stroke Rounded, "hugeicons-<id>"), drawn as a template
/// in the foreground colour; its size stays independent of the text beside it.
struct TimiIcon: View {
    let name: String
    var size: CGFloat = 24

    init(_ name: String, size: CGFloat = 24) {
        self.name = name
        self.size = size
    }

    /// Chevrons are Apple's own, straight-edged as in Settings (user request 2026-11-01: the set's
    /// were rounded at the tip).
    private static let systemChevrons = [
        "hugeicons-arrow-right-01": "chevron.right",
        "hugeicons-arrow-left-01": "chevron.left",
        "hugeicons-arrow-down-01": "chevron.down",
        "hugeicons-arrow-up-01": "chevron.up",
    ]

    var body: some View {
        if let symbol = Self.systemChevrons[name] {
            Image(systemName: symbol)
                .font(.system(size: size * 0.8, weight: .semibold))
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        } else {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}
