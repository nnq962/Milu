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

    /// "Bộ lọc" on a bar: in the bar's glass circle, the glass tinted with the primary colour
    /// while a filter is on, as Mail on iOS 26 (review 2026-11-07: a circled glyph in the glass
    /// circle read as a ring in a ring). Before iOS 26 the glyph says it (`FilterGlyph`).
    @ViewBuilder
    func filterBarButtonStyle(isActive: Bool) -> some View {
        if #available(iOS 26.0, *), isActive {
            buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(Palette.primary)
        } else {
            buttonBorderShape(.circle)
                .tint(Palette.primary)
        }
    }
}

/// The glyph of "Bộ lọc" on a bar: iOS 26's plain lines in the glass circle; before iOS 26, with
/// no glass, the circled one, filled while a filter is on.
enum FilterGlyph {
    static func name(isActive: Bool) -> String {
        // The plain lines everywhere: before iOS 26 the bar circle now holds them, and a filter
        // that is on fills it (`BarSymbol(prominent:)`).
        "line.3.horizontal.decrease"
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
    /// "⌄" after the words when it opens a picker (the month of Lịch thu chi, its wheels).
    var opensMenu = false

    /// The › or ⌄: SF Semibold 13 that grows with the words, 6 from them, the same glyph, size and
    /// gap as Giao dịch's "Báo cáo ›" and "Tháng 11 ⌄" (review 2026-11-08: Hugeicons' › here and a
    /// 12 with a 4 gap read thinner and tighter than there).
    @ScaledMetric(relativeTo: .subheadline) private var chevron = IconSize.chevron

    var body: some View {
        HStack(spacing: IconSize.glyphGap) {
            Text(title)
                .textRole(.accessory)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
            if opensPage || opensMenu {
                Image(systemName: opensPage ? "chevron.right" : "chevron.down")
                    .font(.system(size: chevron, weight: .semibold))
                    .accessibilityHidden(true)
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
    /// Before iOS 26: drawn on the primary colour, as a filter that is on (iOS 26's
    /// `.glassProminent` does it there).
    var prominent = false

    init(_ name: String, prominent: Bool = false) {
        self.name = name
        self.prominent = prominent
    }

    var body: some View {
        if legacyProminent {
            glyph
                .foregroundStyle(Palette.onPrimary)
                .legacyBarCircle(prominent: true)
        } else {
            glyph.legacyBarCircle()
        }
    }

    private var glyph: some View {
        Image(systemName: name)
            .font(.system(size: IconSize.bar, weight: .regular))
            .frame(width: IconSize.barFrame, height: IconSize.barFrame)
    }

    private var legacyProminent: Bool {
        if #available(iOS 26.0, *) { return false }
        return prominent
    }
}
