import SwiftUI

/// "Hồ sơ của bạn": the name on Cài đặt's card and the bars, and the picture by it (user request
/// 2026-11-12): the initial or one of Milu's faces. Saved with ✓; both follow the user through
/// iCloud.
struct ProfileNameSheet: View {
    @AppStorage(StorageKey.profileName) private var savedName = ""
    @AppStorage(StorageKey.profileAvatar) private var savedAvatar = ""
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var avatar = ProfileAvatar.initial
    /// Return and ✓ close the sheet once: a ✓ tapped while it slides away saves nothing twice.
    @State private var didSave = false

    static let maxLength = 30
    private static let previewSize: CGFloat = 96
    private static let choiceSize: CGFloat = 56

    var body: some View {
        SheetScaffold(title: "Hồ sơ của bạn", onConfirm: save) {
            ProfileAvatarView(avatar: avatar, name: name, size: Self.previewSize)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s)
                .animation(Motion.gentle(.smooth(duration: 0.25)), value: avatar)
        } content: {
            FormGroup(title: "Tên") {
                FormTextRow(title: "Tên", text: $name, prompt: "Ví dụ: Minh", maxLength: Self.maxLength)
                    // A name as typed: autocorrect "fixed" Vietnamese names (review 2026-11-09).
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: "Ảnh đại diện", style: .group)
                choices
                    .padding(Spacing.l)
                    .listCard()
            }
        }
        .miluSheetStyle()
        .sensoryFeedback(.selection, trigger: avatar)
        .onAppear {
            name = savedName
            avatar = ProfileAvatar(raw: savedAvatar)
        }
    }

    /// The initial, then Milu's faces.
    private var choices: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: Self.choiceSize), spacing: Spacing.m)], spacing: Spacing.m) {
            choice(.initial, label: "Chữ cái đầu")
            ForEach(MiluHero.Look.allCases, id: \.self) { look in
                choice(.milu(look), label: "Milu")
            }
        }
    }

    private func choice(_ option: ProfileAvatar, label: String) -> some View {
        let selected = avatar == option
        return Button { avatar = option } label: {
            ProfileAvatarView(avatar: option, name: name, size: Self.choiceSize)
                .overlay {
                    Circle().strokeBorder(Palette.primary, lineWidth: selected ? 3 : 0)
                }
                .padding(2)
                .overlay {
                    Circle().strokeBorder(Palette.background, lineWidth: selected ? 2 : 0)
                        .padding(2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func save() {
        guard !didSave else { return }
        didSave = true
        savedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        savedAvatar = avatar.raw
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
