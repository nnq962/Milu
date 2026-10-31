import SwiftUI

/// A form or detail sheet laid out like Calendar and Contacts: native bar with ✕ on the left, the
/// title centred and ✓ on the right to save; scrolling content. No footer: deleting an existing item
/// is a red `FormDestructiveRow` at the end of the content.
///
/// `header` holds what the form is about (the big amount, the kind switch), first in the scroll
/// view so it scrolls with the rows (user choice 2026-10-28, over pinning it under the bar).
struct SheetScaffold<Header: View, Content: View>: View {
    let title: String
    var canConfirm = true
    /// Checked when ✓ is tapped: false keeps the sheet open and buzzes an error, so the form can
    /// show what is missing. Prefer this to `canConfirm` when the user should learn why.
    var validate: (() -> Bool)? = nil
    var onConfirm: (() -> Void)? = nil
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content

    /// Set by the first ✓: a second tap while the sheet slides away saves nothing twice.
    @State private var hasConfirmed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    if Header.self != EmptyView.self {
                        VStack(spacing: Spacing.l) { header }
                            .frame(maxWidth: .infinity)
                    }
                    content
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.xxl)
                .frame(maxWidth: .infinity)
                .keyboardDismissArea()
            }
            .dismissesKeyboardOnTap()
            .background(Palette.background)
            .foregroundStyle(Palette.label)
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

    private var closeButton: some View { SheetCloseButton() }

    /// iOS draws ✓ on a filled glass circle in the tint (the primary colour); it greys itself out when disabled.
    private func confirmButton(_ confirm: @escaping () -> Void) -> some View {
        let action = {
            guard !hasConfirmed else { return }
            if let validate, !validate() {
                Haptics.error()
                return
            }
            hasConfirmed = true
            Haptics.success()
            confirm()
        }
        return Button(role: .confirm, action: action)
            .tint(Palette.primary)
            .disabled(!canConfirm)
            .accessibilityLabel("Lưu")
    }
}

extension SheetScaffold where Header == EmptyView {
    init(title: String, canConfirm: Bool = true, validate: (() -> Bool)? = nil, onConfirm: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.init(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                  header: { EmptyView() }, content: content)
    }
}
