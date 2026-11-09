import SwiftUI

/// Sets the name on Cài đặt's card and the initial on the bars (review 2026-11-09: every install
/// showed the developer's "Quyet" and a made-up email). Kept on this phone only, cleared with
/// "Xoá toàn bộ dữ liệu".
struct ProfileNameSheet: View {
    @AppStorage(StorageKey.profileName) private var savedName = ""
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    /// Return and ✓ close the sheet once: a ✓ tapped while it slides away saves nothing twice.
    @State private var didSave = false

    static let maxLength = 30

    var body: some View {
        SheetScaffold(title: "Tên của bạn", onConfirm: save, fitsContent: true) {
            FormGroup(footer: "Chỉ lưu trên máy này.") {
                FormTextRow(title: "Tên", text: $name, prompt: "Ví dụ: Minh", maxLength: Self.maxLength,
                            focusesOnAppear: true)
                    // A name as typed: autocorrect "fixed" Vietnamese names (review 2026-11-09).
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    // Return saves as ✓ does, with its tick (review 2026-11-09).
                    .submitLabel(.done)
                    .onSubmit {
                        guard !didSave else { return }
                        Haptics.success()
                        save()
                    }
            }
        }
        .onAppear { name = savedName }
    }

    private func save() {
        guard !didSave else { return }
        didSave = true
        savedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}

/// The profile's initial: the first letter of the saved name, upper case; nil with no name.
enum ProfileName {
    /// A letter or digit only: an emoji drawn as the bar's template image came out a blob.
    static func initial(of name: String) -> String? {
        guard let first = name.trimmingCharacters(in: .whitespacesAndNewlines).first,
              first.isLetter || first.isNumber else { return nil }
        return String(first).uppercased(with: .vietnam)
    }
}
