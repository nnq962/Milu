import SwiftUI

/// Header of a short sheet, laid out like a native sheet's bar: ✕ on the left, title centred and,
/// when there is something to confirm, ✓ on the right (in the primary colour, like the form
/// sheet's). On iOS 26 both are the system's own close and confirm buttons on glass circles,
/// glyph and all, so they match `SheetCloseButton` and the form sheet's ✓ (sheet review
/// 2026-10-30: they were glyphs drawn on hand-made glass). It stands in for a navigation bar
/// where a fitted sheet has none, so it never takes part in a push and pop.
struct SheetHeader: View {
    private static let button = ControlHeight.regular

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
                closeButton
                Spacer()
                if let onConfirm {
                    confirmButton(onConfirm)
                }
            }
        }
        // At least the buttons' height; taller with large text.
        .frame(minHeight: Self.button)
        .padding(.top, Spacing.l)
    }

    /// The system's own glyph at the size of a bar's ✕ and ✓, framed like the other bar glyphs.
    private func glyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.body.weight(.medium))
            .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
    }

    private var closeButton: some View {
        // Outside a toolbar the close role shows the word "Đóng", so the ✕ is given.
        Button(role: .close) { dismiss() } label: { glyph("xmark") }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(Palette.label)
            .accessibilityLabel("Đóng")
    }

    private func confirmButton(_ action: @escaping () -> Void) -> some View {
        Button(role: .confirm, action: action) { glyph("checkmark") }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(Palette.primary)
            .accessibilityLabel("Xong")
    }
}
