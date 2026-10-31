import SwiftUI

/// One choice in a short option sheet.
struct SheetOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    var subtitle: String? = nil
    var accent = false
}

/// A short sheet of choices (web "Thêm mới"); picking one closes it, then runs the action.
struct OptionSheet: View {
    let title: String
    let options: [SheetOption]
    let onSelect: (SheetOption) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: title)
            FormGroup {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        Haptics.selection()
                        dismiss()
                        onSelect(option)
                    } label: {
                        NavigationRowLabel(title: option.title, subtitle: option.subtitle, icon: option.icon)
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                }
            }
        }
        .foregroundStyle(Palette.label)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .timiFittedSheet()
    }
}
