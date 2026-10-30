import SwiftUI

/// Header of a short sheet, laid out like a native sheet's bar: ✕ on the left, title centred and,
/// when there is something to confirm, ✓ on the right (black, like the form sheet's).
/// Its ✕ and ✓ are the system's own glyphs, as `SheetCloseButton` and the native close/confirm
/// buttons are: it stands in for a navigation bar where a sheet has none.
struct SheetHeader: View {
    private static let button: CGFloat = 44
    private static let glyphSize: CGFloat = 17
    private static let glyphFrame: CGFloat = RowMetrics.toolbarGlyphFrame

    let title: String
    var onConfirm: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Text(title)
                .textRole(.title)
                .lineLimit(1)
                .padding(.horizontal, Self.button + Spacing.l)
            HStack {
                Button { dismiss() } label: { glyph("xmark", color: Palette.ink) }
                    .nativeCircleButton(diameter: Self.button)
                    .accessibilityLabel("Đóng")
                Spacer()
                if let onConfirm {
                    confirmButton(onConfirm)
                }
            }
        }
        .frame(height: Self.button)
        .padding(.top, Spacing.l)
    }

    private func glyph(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: Self.glyphSize, weight: .medium))
            .foregroundStyle(color)
            .frame(width: Self.glyphFrame, height: Self.glyphFrame)
    }

    @ViewBuilder
    private func confirmButton(_ action: @escaping () -> Void) -> some View {
        let button = Button(action: action) { glyph("checkmark", color: Palette.onPrimary) }
            .accessibilityLabel("Xong")
        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .buttonSizing(.flexible)
                .tint(Palette.primary)
                .frame(width: Self.button, height: Self.button)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Palette.primary)
                .frame(width: Self.button, height: Self.button)
        }
    }
}
