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
