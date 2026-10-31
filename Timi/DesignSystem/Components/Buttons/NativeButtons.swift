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
            TimiIcon("hugeicons-pencil-edit-01", size: RowMetrics.toolbarGlyph)
        }
        .accessibilityLabel("Sửa")
    }
}

/// Fills the toolbar's centre on a screen whose title is drawn as a leading heading instead, so the
/// system does not show the navigation title there.
struct HiddenToolbarTitle: View {
    var body: some View {
        Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
    }
}

/// A control on a heading's row ("Lưu trữ (2) ›", "Xoá", the month of Lịch thu chi): 14 moss words,
/// no glass (user request 2026-10-30, after trying small glass capsules), 44 tall to tap. Its words
/// end where the heading's row ends, so it lines up with the card's right edge.
struct HeaderCapsuleLabel: View {
    let title: String
    /// "›" after the words when it opens a page.
    var opensPage = false
    /// "⌄" after the words when it opens a menu (the month of Lịch thu chi).
    var opensMenu = false
    /// Moss words, or ink on the soft cards of Tổng quan (2026-10-31).
    var color: Color = Palette.primary

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .textRole(.accessory)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
            if opensPage {
                TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.linkChevron)
            } else if opensMenu {
                TimiIcon("hugeicons-arrow-down-01", size: RowMetrics.linkChevron)
            }
        }
        .foregroundStyle(color)
        // 44 each way to tap, even for a short word ("Xoá").
        .frame(minWidth: ControlHeight.regular, minHeight: ControlHeight.regular, alignment: .trailing)
        .contentShape(Rectangle())
    }
}

extension View {
    /// A plain button for a `HeaderCapsuleLabel`; it reaches above and below the heading rather
    /// than making the row taller.
    func headerCapsuleGlass() -> some View {
        buttonStyle(.plain)
            .padding(.vertical, -10)
    }
}

/// A button inside content, never glass (user choice 2026-10-31: glass only on the bars and the
/// floating +, since glass in a scrolling card trailed it): a flat fill in `shape`, dimmed while
/// pressed as the system's plain buttons are, nothing more.
struct FlatButtonStyle<S: Shape>: ButtonStyle {
    var fill: Color = Palette.fill2
    let shape: S
    /// A fixed square for round buttons; nil lets the label size the button.
    var diameter: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // The fill takes the whole button, not only the glyph inside it.
            .frame(width: diameter, height: diameter)
            .background(fill, in: shape)
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    /// A round flat button `diameter` wide (‹ › on Báo cáo, the report circle on Thu chi).
    func flatCircleButton(diameter: CGFloat = ControlHeight.regular, fill: Color = Palette.fill2) -> some View {
        buttonStyle(FlatButtonStyle(fill: fill, shape: Circle(), diameter: diameter))
    }

    /// A flat capsule button; size the label yourself (at least `ControlHeight.regular` to tap).
    func flatCapsuleButton(fill: Color = Palette.fill2) -> some View {
        buttonStyle(FlatButtonStyle(fill: fill, shape: Capsule()))
    }
}
