import SwiftUI

/// One choice in a short option sheet; the title names it (review 2026-10-31: a fresh UUID on
/// every build broke the rows' identity).
struct SheetOption: Identifiable {
    var id: String { title }
    let icon: String
    let title: String
    var subtitle: String? = nil
}

/// A short sheet of choices (web "Thêm mới"); picking one closes it, then runs the action.
struct OptionSheet: View {
    let title: String
    let options: [SheetOption]
    let onSelect: (SheetOption) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetScaffold(title: title, fitsContent: true) {
            FormGroup {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        Haptics.selection()
                        dismiss()
                        onSelect(option)
                    } label: {
                        NavigationRowContent(title: option.title, subtitle: option.subtitle, icon: option.icon)
                    }
                    .buttonStyle(.row)
                    .separatorAbove(index > 0, order: index) { FormDivider() }
                }
            }
        }
    }
}
