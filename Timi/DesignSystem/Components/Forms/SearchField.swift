import SwiftUI

/// A search field drawn by the app (a screen of its own, not the bar's): magnifier, the words, a
/// clear button once something is typed, on a white capsule with a thin outline. No correction,
/// "Tìm" on the keyboard.
struct SearchField: View {
    let prompt: String
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: Spacing.s) {
            TimiIcon("hugeicons-search-01", size: 18)
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)
            TextField(prompt, text: $text)
                .textRole(.body)
                .focused(isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit(onSubmit)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.secondary.opacity(0.6))
                        .frame(width: RowMetrics.toolbarGlyphFrame)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Xoá chữ đã gõ")
            }
        }
        .padding(.horizontal, Spacing.l)
        // At least the field height, taller with larger text (Dynamic Type).
        .padding(.vertical, Spacing.s)
        .frame(minHeight: ControlHeight.field)
        .fixedSize(horizontal: false, vertical: true)
        .background(Palette.card, in: Capsule())
        // Inside the capsule, so a scroll view or a stack never clips half the line.
        .overlay { Capsule().strokeBorder(Palette.border, lineWidth: 1) }
        .contentShape(Capsule())
        .onTapGesture { isFocused.wrappedValue = true }
    }
}
