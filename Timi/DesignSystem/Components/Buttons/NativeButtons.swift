import SwiftUI

extension View {
    /// Select Apple's actual Liquid Glass button styles; no custom press animation.
    @ViewBuilder
    func nativeGlassButton(prominent: Bool = false, tint: Color? = nil) -> some View {
        if #available(iOS 26.1, *), let tint {
            self.buttonStyle(.glass(.regular.tint(tint)))
        } else if #available(iOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            if prominent {
                self.buttonStyle(.borderedProminent)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }

    /// Floating action button: Apple's prominent glass tinted with the design accent.
    @ViewBuilder
    func nativeFloatingButton(diameter: CGFloat, tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .buttonSizing(.flexible)
                .tint(tint)
                .frame(width: diameter, height: diameter)
        } else {
            self.buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(tint)
                .frame(width: diameter, height: diameter)
        }
    }

    /// Keep the system glass surface inside the specified design bounds.
    @ViewBuilder
    func nativeCircleButton(diameter: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .buttonSizing(.flexible)
                .controlSize(.regular)
                .frame(width: diameter, height: diameter)
        } else {
            self.buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.regular)
                .frame(width: diameter, height: diameter)
        }
    }
}

/// The edit button of a detail screen's toolbar: a pencil, which iOS 26 sets in a glass circle
/// like the back button (user choice 2026-10-28, over the word "Sửa").
struct EditToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TimiIcon("hugeicons-pencil-edit-01", size: 22)
        }
        .accessibilityLabel("Sửa")
    }
}
