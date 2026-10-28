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

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
