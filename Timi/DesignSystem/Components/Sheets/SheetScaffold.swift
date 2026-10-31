import SwiftUI

/// Every sheet of the app, laid out like Calendar and Contacts: the system's navigation bar with
/// ✕ on the left, the title centred and ✓ on the right to save; scrolling content. No footer:
/// deleting an existing item is a red `FormDestructiveRow` at the end of the content.
///
/// `header` holds what the form is about (the big amount, the kind switch), first in the scroll
/// view so it scrolls with the rows (user choice 2026-10-28, over pinning it under the bar).
///
/// A short sheet (a choice, a note, the calendar) sets `fitsContent`: the sheet is then as tall
/// as its rows plus the bar, and scrolls only once that is taller than the screen. The bar used
/// to be drawn by hand in those (`SheetHeader`); one scaffold since 2026-10-31, so iOS owns the
/// bar everywhere.
struct SheetScaffold<Header: View, Content: View>: View {
    let title: String
    var canConfirm = true
    /// Checked when ✓ is tapped: false keeps the sheet open and buzzes an error, so the form can
    /// show what is missing. Prefer this to `canConfirm` when the user should learn why.
    var validate: (() -> Bool)? = nil
    var onConfirm: (() -> Void)? = nil
    /// As tall as the content; callers then set no detents of their own.
    var fitsContent = false
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content

    /// Set by the first ✓: a second tap while the sheet slides away saves nothing twice.
    @State private var hasConfirmed = false
    /// For `fitsContent`: the rows with their margins, and the bar above them.
    @State private var contentHeight: CGFloat = 300
    @State private var barHeight: CGFloat = ControlHeight.regular

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
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            // The bar is the scroll view's top safe area inside the sheet.
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { barHeight = $0 }
            .scrollBounceBehavior(fitsContent ? .basedOnSize : .automatic)
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
        .modifier(FittedDetent(isOn: fitsContent, height: contentHeight + barHeight))
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
         fitsContent: Bool = false, @ViewBuilder content: () -> Content) {
        self.init(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                  fitsContent: fitsContent, header: { EmptyView() }, content: content)
    }
}

/// The one detent of a short sheet: its content's height. Ignores the zero reported before layout;
/// iOS caps a detent taller than the screen, where the content then scrolls.
private struct FittedDetent: ViewModifier {
    let isOn: Bool
    let height: CGFloat

    func body(content: Content) -> some View {
        if isOn {
            content
                .presentationDetents([.height(max(height, 1))])
                .presentationBackground(Palette.background)
        } else {
            content
        }
    }
}
