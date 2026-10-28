import SwiftUI

/// A form or detail sheet laid out like Calendar and Contacts: native bar with ✕ on the left, the
/// title centred and ✓ on the right to save; scrolling content. No footer: deleting an existing item
/// is a red `FormDestructiveRow` at the end of the content.
struct SheetScaffold<Content: View>: View {
    let title: String
    var canConfirm = true
    var onConfirm: (() -> Void)? = nil
    @ViewBuilder var content: Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    content
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.xxl)
            }
            .dismissesKeyboardOnTap()
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { closeButton }
                if let onConfirm {
                    ToolbarItem(placement: .confirmationAction) { confirmButton(onConfirm) }
                }
            }
        }
    }

    @ViewBuilder
    private var closeButton: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close) { dismiss() }
        } else {
            Button { dismiss() } label: { Image(systemName: "xmark") }
                .accessibilityLabel("Đóng")
        }
    }

    /// iOS 26 draws ✓ on a filled glass circle in the tint (black); it greys itself out when disabled.
    @ViewBuilder
    private func confirmButton(_ confirm: @escaping () -> Void) -> some View {
        let action = {
            Haptics.success()
            confirm()
        }
        if #available(iOS 26.0, *) {
            Button(role: .confirm, action: action)
                .tint(Palette.primary)
                .disabled(!canConfirm)
                .accessibilityLabel("Lưu")
        } else {
            Button("Lưu", action: action)
                .fontWeight(.semibold)
                .tint(Palette.primary)
                .disabled(!canConfirm)
        }
    }
}
