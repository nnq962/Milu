import SwiftUI

/// Every sheet of the app, laid out like Calendar and Contacts: the system's navigation bar with
/// ✕ on the left, the title centred and ✓ on the right to save; scrolling content. No footer:
/// deleting an existing item is a red `FormDestructiveRow` at the end of the content.
///
/// `SheetScaffold` is the sheet itself (its `NavigationStack`, background, hidden scroll
/// indicators and, for a short sheet, the detent that fits its content). `SheetPage` is one
/// screen inside it: the first one, or one pushed from it (a transaction opened from "Cùng hạng
/// mục"), which has ‹ instead of ✕. A detail screen puts its pencil in `trailing`.
///
/// `header` holds what the form is about (the big amount, the kind switch), first in the scroll
/// view so it scrolls with the rows (user choice 2026-10-28, over pinning it under the bar).
struct SheetScaffold<Header: View, Content: View, Trailing: View>: View {
    let title: String
    var canConfirm = true
    /// Checked when ✓ is tapped: false keeps the sheet open and buzzes an error, so the form can
    /// show what is missing. Prefer this to `canConfirm` when the user should learn why.
    var validate: (() -> Bool)? = nil
    var onConfirm: (() -> Void)? = nil
    /// As tall as the content (a choice, a note, the calendar); callers then set no detents of
    /// their own.
    var fitsContent = false
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content
    @ViewBuilder var trailing: Trailing

    /// For `fitsContent`: the rows with their margins plus the bar, reported by the page.
    @State private var fittedHeight: CGFloat?

    var body: some View {
        NavigationStack {
            SheetPage(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                      measuresHeight: fitsContent, header: { header }, content: { content }, trailing: { trailing })
        }
        .onPreferenceChange(SheetHeightKey.self) { if fitsContent { fittedHeight = $0 } }
        .modifier(FittedDetent(isOn: fitsContent, height: fittedHeight))
        // The sheet's own chrome, so no caller has to remember it (review 2026-10-31: five short
        // sheets had no `miluSheetStyle` and could show a scroll bar).
        .presentationBackground(Palette.surface)
        .environment(\.isInSheet, true)
        // Its own cards, even when opened from inside a `HeaderCard` (see `miluSheetStyle`).
        .environment(\.isInHeaderCard, false)
        .scrollIndicators(.hidden, axes: .vertical)
    }
}

extension SheetScaffold where Trailing == EmptyView {
    init(title: String, canConfirm: Bool = true, validate: (() -> Bool)? = nil, onConfirm: (() -> Void)? = nil,
         fitsContent: Bool = false, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.init(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                  fitsContent: fitsContent, header: header, content: content, trailing: { EmptyView() })
    }
}

extension SheetScaffold where Header == EmptyView, Trailing == EmptyView {
    init(title: String, canConfirm: Bool = true, validate: (() -> Bool)? = nil, onConfirm: (() -> Void)? = nil,
         fitsContent: Bool = false, @ViewBuilder content: () -> Content) {
        self.init(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                  fitsContent: fitsContent, header: { EmptyView() }, content: content, trailing: { EmptyView() })
    }
}

/// One screen of a sheet: the bar (✕ or ‹, the title, ✓ or `trailing`) and the scrolling content.
struct SheetPage<Header: View, Content: View, Trailing: View>: View {
    let title: String
    var canConfirm = true
    var validate: (() -> Bool)? = nil
    var onConfirm: (() -> Void)? = nil
    /// ✕ on the left: the first screen of a sheet has it; one pushed from it has only ‹.
    var showsClose = true
    /// Reports its height for a sheet that fits its content (`SheetScaffold(fitsContent:)`).
    var measuresHeight = false
    /// Builds only what scrolls into view: a detail screen whose history can run to years of
    /// days (an account's), where every day at once froze the opening (review 2026-11-09).
    var isLazy = false
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content
    @ViewBuilder var trailing: Trailing

    /// Set by the first ✓: a second tap while the sheet slides away saves nothing twice. Cleared
    /// a moment later, so a ✓ that kept the sheet open (a save that failed) works again.
    @State private var hasConfirmed = false

    var body: some View {
        ScrollView {
            Group {
                if isLazy {
                    LazyVStack(alignment: .leading, spacing: Spacing.xxl) { stack }
                } else {
                    VStack(alignment: .leading, spacing: Spacing.xxl) { stack }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
            .frame(maxWidth: .infinity)
            .keyboardDismissArea()
        }
        .modifier(HeightReport(isOn: measuresHeight))
        .scrollBounceBehavior(measuresHeight ? .basedOnSize : .automatic)
        .dismissesKeyboardOnDrag()
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
            if let onConfirm {
                ToolbarItem(placement: .confirmationAction) { confirmButton(onConfirm) }
            }
            if Trailing.self != EmptyView.self {
                ToolbarItem(placement: .topBarTrailing) { trailing }
            }
        }
    }

    @ViewBuilder private var stack: some View {
        if Header.self != EmptyView.self {
            VStack(spacing: Spacing.l) { header }
                .frame(maxWidth: .infinity)
        }
        content
    }

    /// iOS draws ✓ on a filled glass circle in the tint (the primary colour); it greys itself out when disabled.
    private func confirmButton(_ confirm: @escaping () -> Void) -> some View {
        let action = {
            guard !hasConfirmed else { return }
            if let validate, !validate() {
                Haptics.error()
                return
            }
            hasConfirmed = true
            confirm()
            Task {
                try? await Task.sleep(for: .seconds(1))
                hasConfirmed = false
            }
        }
        return Group {
            if #available(iOS 26.0, *) {
                Button(role: .confirm, action: action)
            } else {
                // Before iOS 26 there is no confirm role: a ✓ on the primary colour, the pair of
                // the grey ✕ across the bar (user choice 2026-11-09).
                Button(action: action) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.onPrimary)
                        .frame(width: LegacyBar.sheetControl, height: LegacyBar.sheetControl)
                        .background(Palette.primary, in: Circle())
                        .opacity(canConfirm ? 1 : 0.4)
                        .contentShape(Circle())
                }
            }
        }
        .tint(Palette.primary)
        .disabled(!canConfirm)
        .accessibilityLabel("Lưu")
    }
}

extension SheetPage where Header == EmptyView, Trailing == EditToolbarButton? {
    /// A detail screen: ✕ on the first one, and the pencil when the item can be changed.
    init(title: String, showsClose: Bool, canEdit: Bool, onEdit: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.init(title: title, showsClose: showsClose, isLazy: true, header: { EmptyView() }, content: content,
                  trailing: { canEdit ? EditToolbarButton(action: onEdit) : nil })
    }
}

/// The content with its margins plus the bar above it, for `SheetScaffold`'s fitted detent.
struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) { value = nextValue() ?? value }
}

/// Measures the scroll view's content and bar only on a sheet that fits its content, so other
/// sheets never redraw on a change of height (review 2026-10-31: every keystroke in the amount
/// field re-laid the whole form).
private struct HeightReport: ViewModifier {
    let isOn: Bool

    @State private var contentHeight: CGFloat?
    @State private var barHeight: CGFloat?

    func body(content: Content) -> some View {
        // Measuring the scroll view needs iOS 18; before it a fitted sheet keeps its fallback detent.
        if isOn, #available(iOS 18.0, *) {
            content
                // The content is the scroll view's one child; the bar is its top safe area.
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height } action: { _, new in contentHeight = new }
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { barHeight = $0 }
                .preference(key: SheetHeightKey.self,
                            value: contentHeight.map { $0 + (barHeight ?? ControlHeight.regular) })
        } else {
            content
        }
    }
}

/// The one detent of a short sheet: its content's height, once known. iOS caps a detent taller
/// than the screen, where the content then scrolls.
private struct FittedDetent: ViewModifier {
    let isOn: Bool
    let height: CGFloat?

    func body(content: Content) -> some View {
        if isOn {
            content.presentationDetents([.height(max(height ?? 300, 1))])
        } else {
            content
        }
    }
}
