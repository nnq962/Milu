import SwiftUI

/// A form or detail sheet laid out like Calendar and Contacts: native bar with ✕ on the left, the
/// title centred and ✓ on the right to save; scrolling content. No footer: deleting an existing item
/// is a red `FormDestructiveRow` at the end of the content.
///
/// `header` holds what the form is about (the big amount, the kind switch). It sits pinned under the
/// bar, outside the scroll view: focusing a field there must not scroll the form (iOS scrolls a
/// focused field's scroll view towards the keyboard, which threw the amount far up the sheet).
struct SheetScaffold<Header: View, Content: View>: View {
    let title: String
    var canConfirm = true
    var onConfirm: (() -> Void)? = nil
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    content
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Header.self == EmptyView.self ? Spacing.s : Spacing.m)
                .padding(.bottom, Spacing.xxl)
            }
            .dismissesKeyboardOnTap()
            .safeAreaInset(edge: .top, spacing: 0) {
                if Header.self != EmptyView.self {
                    VStack(spacing: Spacing.l) { header }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.page)
                        .padding(.top, Spacing.s)
                        .padding(.bottom, Spacing.s)
                        .background(Palette.background)
                }
            }
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

extension SheetScaffold where Header == EmptyView {
    init(title: String, canConfirm: Bool = true, onConfirm: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.init(title: title, canConfirm: canConfirm, onConfirm: onConfirm, header: { EmptyView() }, content: content)
    }
}
