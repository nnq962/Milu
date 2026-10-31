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
            TimiIcon("hugeicons-search-01", size: RowMetrics.iconGlyph)
                .foregroundStyle(Palette.secondaryLabel)
                .accessibilityHidden(true)
            TextField(prompt, text: $text)
                .textRole(.body)
                .focused(isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit(onSubmit)
            if !text.isEmpty {
                Button { text = "" } label: {
                    // 44 wide to tap and dark enough to see as a control (review 2026-10-31:
                    // 28 wide in the chevron grey).
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(width: ControlHeight.regular)
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
        .frame(minHeight: ControlHeight.regular)
        .fixedSize(horizontal: false, vertical: true)
        .background(Palette.surface, in: Capsule())
        // Inside the capsule, so a scroll view or a stack never clips half the line.
        .overlay { Capsule().strokeBorder(Palette.separator, lineWidth: 1) }
        .contentShape(Capsule())
        .onTapGesture { isFocused.wrappedValue = true }
    }
}
