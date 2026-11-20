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
    /// Something typed or picked is not saved yet: ✕ asks before it goes, and a swipe down does
    /// not close it (audit 2026-11-15: a drag to put the keyboard away closed the form, and
    /// everything typed was lost; Milu: "Tiếp tục chỉnh sửa" / "Bỏ thay đổi").
    var hasChanges = false
    /// For `fitsContent`: the least change of height the sheet slides to; under it, the new
    /// height is taken at once (`FittedDetent`). 44 unless the content animates its own lines,
    /// when a line more should slide with it ("Thêm bằng AI", as the words come into its card).
    var fitStep: CGFloat = 44
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content
    @ViewBuilder var trailing: Trailing

    /// For `fitsContent`: the rows with their margins plus the bar, reported by the page.
    @State private var fittedHeight: CGFloat?

    var body: some View {
        NavigationStack {
            SheetPage(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                      measuresHeight: fitsContent, hasChanges: hasChanges,
                      header: { header }, content: { content }, trailing: { trailing })
        }
        .interactiveDismissDisabled(hasChanges)
        .onPreferenceChange(SheetHeightKey.self) { if fitsContent, $0 != fittedHeight { fittedHeight = $0 } }
        .modifier(FittedDetent(isOn: fitsContent, height: fittedHeight, step: fitStep))
        // The sheet's own chrome, so no caller has to remember it (review 2026-10-31: five short
        // sheets had no `miluSheetStyle` and could show a scroll bar).
        // Solid when it fits its rows: on its glass iOS drew the ✕ on a flat grey disc.
        .sheetGround(Palette.surface, solid: fitsContent)
        .environment(\.isInSheet, true)
        // Its own cards, even when opened from inside a `HeaderCard` (see `miluSheetStyle`).
        .environment(\.isInHeaderCard, false)
        .scrollIndicators(.hidden, axes: .vertical)
    }
}

extension SheetScaffold where Trailing == EmptyView {
    init(title: String, canConfirm: Bool = true, validate: (() -> Bool)? = nil, onConfirm: (() -> Void)? = nil,
         fitsContent: Bool = false, hasChanges: Bool = false,
         @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.init(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                  fitsContent: fitsContent, hasChanges: hasChanges, header: header, content: content,
                  trailing: { EmptyView() })
    }
}

extension SheetScaffold where Header == EmptyView, Trailing == EmptyView {
    init(title: String, canConfirm: Bool = true, validate: (() -> Bool)? = nil, onConfirm: (() -> Void)? = nil,
         fitsContent: Bool = false, hasChanges: Bool = false, fitStep: CGFloat = 44,
         @ViewBuilder content: () -> Content) {
        self.init(title: title, canConfirm: canConfirm, validate: validate, onConfirm: onConfirm,
                  fitsContent: fitsContent, hasChanges: hasChanges, fitStep: fitStep,
                  header: { EmptyView() }, content: content, trailing: { EmptyView() })
    }
}

extension View {
    /// A sheet's ground in one of Milu's colours, for every sheet of the app (user choice
    /// 2026-11-20). On iOS 26 laid in the sheet over iOS's own glass, which then still swells a
    /// little under a touch, as Apple's sheets do; `presentationBackground` takes the place of
    /// that glass, and its touch with it (tried on "Thêm mới", "Thêm giao dịch" and "Thêm bằng
    /// AI" first). Before iOS 26, `presentationBackground` as before.
    ///
    /// `solid`: a sheet lower than the screen (fitted to its rows, half the screen, a set height)
    /// takes `presentationBackground` on iOS 26 too, without the swell (user choice 2026-11-20,
    /// "Giữ nền đặc"): on its glass iOS drew the ✕ as a flat grey disc ("Thêm mới"), where the
    /// tall sheets and "Thêm bằng AI" have the white glass one, and the three ✕ were unlike.
    func sheetGround(_ color: Color, solid: Bool = false) -> some View {
        modifier(SheetGround(color: color, solid: solid))
    }
}

private struct SheetGround: ViewModifier {
    let color: Color
    var solid = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), !solid {
            content.background { color.ignoresSafeArea() }
        } else {
            content.presentationBackground(color)
        }
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
    /// Unsaved input: ✕ asks first (`SheetScaffold.hasChanges`).
    var hasChanges = false
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content
    @ViewBuilder var trailing: Trailing

    /// Set by the first ✓: a second tap while the sheet slides away saves nothing twice. Cleared
    /// a moment later, so a ✓ that kept the sheet open (a save that failed) works again.
    @State private var hasConfirmed = false
    @State private var isConfirmingDiscard = false
    /// The content's height with its margins, for a sheet that fits its content.
    @State private var contentHeight: CGFloat?
    @Environment(\.dismiss) private var dismiss

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
            .modifier(ContentHeightReader(isOn: measuresHeight) { contentHeight = $0 })
        }
        .modifier(HeightReport(isOn: measuresHeight, contentHeight: contentHeight))
        .scrollBounceBehavior(measuresHeight ? .basedOnSize : .automatic)
        .dismissesKeyboardOnDrag()
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .systemAlert("Bỏ thay đổi?", isPresented: $isConfirmingDiscard) {
            Button("Bỏ thay đổi", role: .destructive) { dismiss() }
            Button("Tiếp tục chỉnh sửa", role: .cancel) {}
        } message: {
            Text("Những gì bạn vừa nhập sẽ không được lưu.")
        }
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCloseButton(onClose: hasChanges ? { isConfirmingDiscard = true } : nil)
                }
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

/// Measures the content and the bar only on a sheet that fits its content, so other sheets never
/// redraw on a change of height (review 2026-10-31: every keystroke in the amount field re-laid
/// the whole form). The content is measured inside the scroll view, which works on iOS 17 too
/// (audit 2026-11-15: measuring the scroll view needs iOS 18, and every such sheet was stuck at
/// 300pt there, the calendar and the time wheel cut off).
private struct HeightReport: ViewModifier {
    let isOn: Bool
    let contentHeight: CGFloat?

    @State private var barHeight: CGFloat?

    func body(content: Content) -> some View {
        if isOn {
            content
                // The bar is the scroll view's top safe area.
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { barHeight = $0 }
                .preference(key: SheetHeightKey.self,
                            value: contentHeight.map { $0 + (barHeight ?? ControlHeight.regular) })
        } else {
            content
        }
    }
}

/// The content's height inside the scroll view, for `HeightReport`.
private struct ContentHeightReader: ViewModifier {
    let isOn: Bool
    let report: (CGFloat) -> Void

    func body(content: Content) -> some View {
        if isOn {
            content.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { report($0) }
        } else {
            content
        }
    }
}

/// The one detent of a short sheet: its content's height, once known. iOS caps a detent taller
/// than the screen, where the content then scrolls.
///
/// A new height eases the sheet there (user request 2026-11-18: "Thêm bằng AI" jumped up and down
/// at each step, its content fading inside a sheet already at its new height). iOS slides a sheet
/// only to another of its detents, never to a new set of them: so for a moment both heights are
/// detents, the new one is selected, and the old one goes once the sheet is there.
///
/// Only once the sheet is up, and only for a step of the content, not a line more of words
/// (iPhone, 2026-11-18): opening, the height came twice and the second slide made the sheet
/// overshoot as it rose; a line of words came at once and the sheet followed after, the buttons
/// pushed down then back up. Those take the new height at once, as before. A sheet whose content
/// animates its own lines asks for a smaller `step`, and the sheet slides with them.
///
/// The keyboard is left to iOS, which carries the sheet up with it: shortened under the keyboard
/// by the home indicator's room, the sheet jumped as the keyboard rose (iPhone, 2026-11-18).
private struct FittedDetent: ViewModifier {
    let isOn: Bool
    let height: CGFloat?
    /// Smaller changes than this are a line of words, not a step: taken at once.
    let step: CGFloat

    @State private var selected: PresentationDetent?
    @State private var detents: Set<PresentationDetent> = []
    /// The height the sheet is at or going to.
    @State private var shown: CGFloat?
    /// Up a moment after its first height: no slide while it opens.
    @State private var settled = false
    /// Which move is the latest: an older one's tidying up is dropped.
    @State private var move = 0

    func body(content: Content) -> some View {
        if isOn {
            let target = PresentationDetent.height(goal)
            content
                .presentationDetents(detents.isEmpty ? [target] : detents,
                                     selection: Binding(get: { selected ?? target }, set: { selected = $0 }))
                // Two detents for a moment would show the grabber, as if the sheet could be pulled.
                .presentationDragIndicator(.hidden)
                .onChange(of: goal) { _, new in moveTo(new) }
        } else {
            content
        }
    }

    private var goal: CGFloat { max(height ?? 300, 1) }

    private func moveTo(_ height: CGFloat) {
        move += 1
        let this = move
        let before = shown
        shown = height
        let target = PresentationDetent.height(height)
        guard settled, let before, abs(height - before) >= step, let current = selected, current != target,
              let animation = Motion.gentle(.smooth(duration: 0.35)) else {
            selected = target
            detents = [target]
            if before == nil {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(700))
                    settled = true
                }
            }
            return
        }
        detents = [current, target]
        Task { @MainActor in
            // The new detent in place before it is picked.
            try? await Task.sleep(for: .milliseconds(20))
            guard move == this else { return }
            withAnimation(animation) { selected = target }
            try? await Task.sleep(for: .milliseconds(450))
            guard move == this else { return }
            detents = [target]
        }
    }
}
