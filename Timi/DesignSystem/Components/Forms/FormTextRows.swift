import SwiftUI

/// iOS Settings/Contacts style field row: label on the left, value typed on the right, inside a FormGroup.
struct FormTextRow: View {
    let title: String
    @Binding var text: String
    var prompt = ""
    var icon: String? = nil
    var keyboard: UIKeyboardType = .default
    var isInvalid = false
    /// Longer text is cut to this many characters as it is typed.
    var maxLength: Int? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            FormRowLabel(title: title, icon: icon, isInvalid: isInvalid)
                .fixedSize()
            TextField(prompt, text: $text)
                .textRole(.body)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)
                .focused($isFocused)
                .onChange(of: text) { _, new in
                    if let maxLength, new.count > maxLength { text = String(new.prefix(maxLength)) }
                }
        }
        .formRowFrame()
        .onTapGesture { isFocused = true }
    }
}

/// A secondary amount in a form row ("Đã để dành", "Còn phải thu"): label left, digits grouped as
/// they are typed on the right, "đ" after them. The form's main amount uses `TimiAmountField`.
struct FormAmountRow: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            FormRowLabel(title: title, icon: icon)
                .fixedSize()
            HStack(spacing: 0) {
                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                Text("đ")
                    .foregroundStyle(text.isEmpty ? Color(.placeholderText) : Palette.ink)
            }
            .textRole(.amount)
            .foregroundStyle(Palette.ink)
        }
        .formRowFrame()
        .onTapGesture { isFocused = true }
        .onChange(of: text) { _, newValue in
            let formatted = newValue.groupedVNDInput
            if formatted != newValue { text = formatted }
        }
    }
}

/// A multi-line note filling a FormGroup row, placeholder in grey (iOS Notes / Reminders style).
struct FormNoteRow: View {
    @Binding var text: String
    var prompt = "Ghi chú"

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(prompt, text: $text, axis: .vertical)
            .textRole(.body)
            .foregroundStyle(Palette.ink)
            .lineLimit(3...6)
            .focused($isFocused)
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            // The whole box takes the tap, not only the first line.
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
    }
}
