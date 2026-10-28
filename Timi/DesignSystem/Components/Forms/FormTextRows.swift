import SwiftUI

/// iOS Settings/Contacts style field row: label on the left, value typed on the right, inside a FormGroup.
struct FormTextRow: View {
    let title: String
    @Binding var text: String
    var prompt = ""
    var icon: String? = nil
    var keyboard: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            FormRowLabel(title: title, icon: icon)
                .fixedSize()
            TextField(prompt, text: $text)
                .textRole(.body)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)
                .focused($isFocused)
            if isFocused && !text.isEmpty {
                ClearFieldButton { text = "" }
            }
        }
        .formRowFrame()
        .onTapGesture { isFocused = true }
    }
}

/// A multi-line note filling a FormGroup row, placeholder in grey (iOS Notes / Reminders style).
struct FormNoteRow: View {
    @Binding var text: String
    var prompt = "Ghi chú"

    var body: some View {
        TextField(prompt, text: $text, axis: .vertical)
            .textRole(.body)
            .foregroundStyle(Palette.ink)
            .lineLimit(3...6)
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
    }
}
