import SwiftUI

/// Header of a short sheet, laid out like a native sheet's bar: ✕ on the left, title centred and,
/// when there is something to confirm, ✓ on the right (black, like the form sheet's).
struct SheetHeader: View {
    let title: String
    var onConfirm: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Text(title)
                .textRole(.title)
                .lineLimit(1)
                .padding(.horizontal, 60)
            HStack {
                Button { dismiss() } label: { glyph("xmark", color: Palette.ink) }
                    .nativeCircleButton(diameter: 44)
                    .accessibilityLabel("Đóng")
                Spacer()
                if let onConfirm {
                    confirmButton(onConfirm)
                }
            }
        }
        .frame(height: 44)
        .padding(.top, Spacing.l)
    }

    private func glyph(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
    }

    @ViewBuilder
    private func confirmButton(_ action: @escaping () -> Void) -> some View {
        let button = Button(action: action) { glyph("checkmark", color: .white) }
            .accessibilityLabel("Xong")
        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .buttonSizing(.flexible)
                .tint(Palette.primary)
                .frame(width: 44, height: 44)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Palette.primary)
                .frame(width: 44, height: 44)
        }
    }
}
