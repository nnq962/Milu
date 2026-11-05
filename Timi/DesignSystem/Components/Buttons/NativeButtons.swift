import SwiftUI

extension View {
    /// Floating action button: Apple's prominent glass tinted with the primary colour (the send
    /// button of Trợ lý AI); a solid disc of that colour before iOS 26.
    @ViewBuilder
    func nativeFloatingButton(diameter: CGFloat, tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .buttonSizing(.flexible)
                .tint(tint)
                .frame(width: diameter, height: diameter)
        } else {
            buttonStyle(.plain)
                .frame(width: diameter, height: diameter)
                .background(tint, in: Circle())
        }
    }

    /// A glass circle of the system's, `diameter` wide, outside a toolbar (the close button of
    /// the search screen); a blurred material disc before iOS 26.
    @ViewBuilder
    func nativeCircleButton(diameter: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .buttonSizing(.flexible)
                .controlSize(.regular)
                .frame(width: diameter, height: diameter)
        } else {
            buttonStyle(.plain)
                .frame(width: diameter, height: diameter)
                .background(.regularMaterial, in: Circle())
        }
    }
}

/// The edit button of a detail screen's toolbar: a pencil, which iOS 26 sets in a glass circle
/// like the back button (user choice 2026-10-28, over the word "Sửa").
struct EditToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BarSymbol("pencil")
        }
        // The action colour, as the sheet's ✕ beside it (final icon review 2026-11-05: it drew
        // in ink, darker than the ✕).
        .tint(Palette.primary)
        .accessibilityLabel("Sửa")
    }
}

/// A control on a heading's row ("Lưu trữ (2) ›", "Xoá", the month of Lịch thu chi): 14 words in
/// the primary colour, no fill and no glass (user request 2026-10-30, after trying small glass
/// capsules). Its words end where the heading's row ends, so it lines up with the card's right
/// edge; the area that takes a tap reaches 12 past the words each way, so it is at least 44 at
/// any text size without making the row taller (review 2026-10-31: a 44 frame and a -10 padding
/// assumed a 24pt line).
struct HeaderLink: View {
    let title: String
    /// "›" after the words when it opens a page.
    var opensPage = false
    /// "⌄" after the words when it opens a menu (the month of Lịch thu chi).
    var opensMenu = false

    /// The › or ⌄ grows with the words: fixed at 12 it looked like a dot beside them at the
    /// accessibility sizes (review 2026-11-03).
    @ScaledMetric(relativeTo: .subheadline) private var chevron = RowMetrics.linkChevron

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .textRole(.accessory)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
            if opensPage {
                TimiIcon("hugeicons-arrow-right-01", size: chevron)
            } else if opensMenu {
                TimiIcon("hugeicons-arrow-down-01", size: chevron)
            }
        }
        .foregroundStyle(Palette.primary)
        .contentShape(Rectangle().inset(by: -Spacing.m))
    }
}

extension View {
    /// A plain button for a `HeaderLink`.
    func headerLinkButton() -> some View {
        buttonStyle(.plain)
    }
}

/// A button inside content, never glass (user choice 2026-10-31: glass only on the bars and the
/// floating +, since glass in a scrolling card trailed it): a flat fill in `shape`, dimmed while
/// pressed with the app's lively press (`LivelyPress`), sinking a little more as it is small.
struct FlatButtonStyle<S: Shape>: ButtonStyle {
    var fill: Color = Palette.fill
    let shape: S
    /// A fixed square for round buttons; nil lets the label size the button.
    var diameter: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // The fill takes the whole button, not only the glyph inside it.
            .frame(width: diameter, height: diameter)
            .background(fill, in: shape)
            .contentShape(shape)
            .modifier(LivelyPress(isPressed: configuration.isPressed, scale: 0.92))
    }
}

extension View {
    /// A round flat button `diameter` wide (‹ › on Báo cáo, the report circle on Thu chi).
    func flatCircleButton(diameter: CGFloat = ControlHeight.regular, fill: Color = Palette.fill) -> some View {
        buttonStyle(FlatButtonStyle(fill: fill, shape: Circle(), diameter: diameter))
    }

    /// A flat capsule button; size the label yourself (at least `ControlHeight.regular` to tap).
    func flatCapsuleButton(fill: Color = Palette.fill) -> some View {
        buttonStyle(FlatButtonStyle(fill: fill, shape: Capsule()))
    }
}

/// An SF Symbol in a bar's glass button, the one size and weight of every bar glyph
/// (`IconSize.bar`, Regular), in the frame that makes each glass circle the same.
struct BarSymbol: View {
    let name: String

    init(_ name: String) { self.name = name }

    var body: some View {
        Image(systemName: name)
            .font(.system(size: IconSize.bar, weight: .regular))
            .frame(width: IconSize.barFrame, height: IconSize.barFrame)
    }
}
