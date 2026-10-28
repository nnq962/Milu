import SwiftUI

extension View {
    /// A standard iOS sheet: Apple's own corners, grabber and dimming; Timi only sets the page colour.
    func timiSheetStyle(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationBackground(Palette.background)
    }

    /// A standard iOS sheet as tall as its content (short choices, a calendar).
    func timiFittedSheet() -> some View {
        modifier(FittedSheet())
    }
}

private struct FittedSheet: ViewModifier {
    @State private var height: CGFloat = 400

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
            .frame(maxHeight: .infinity, alignment: .top)
            .presentationDetents([.height(height)])
            .presentationBackground(Palette.background)
    }
}

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

/// One choice in a short option sheet.
struct SheetOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    var subtitle: String? = nil
    var accent = false
}

/// Header of a short sheet, laid out like a native sheet's bar: ✕ on the left, title centred and,
/// when there is something to confirm, ✓ on the right (black, like the form sheet's).
struct SheetHeader: View {
    let title: String
    var onConfirm: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Text(title)
                .textRole(.title)
                .lineLimit(1)
                .padding(.horizontal, 60)
            HStack {
                Button { dismiss() } label: { glyph("xmark", color: Palette.ink) }
                    .nativeCircleButton(diameter: 44)
                    .accessibilityLabel("Đóng")
                Spacer()
                if let onConfirm {
                    confirmButton(onConfirm)
                }
            }
        }
        .frame(height: 44)
        .padding(.top, Spacing.l)
    }

    private func glyph(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
    }

    @ViewBuilder
    private func confirmButton(_ action: @escaping () -> Void) -> some View {
        let button = Button(action: action) { glyph("checkmark", color: .white) }
            .accessibilityLabel("Xong")
        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .buttonSizing(.flexible)
                .tint(Palette.primary)
                .frame(width: 44, height: 44)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Palette.primary)
                .frame(width: 44, height: 44)
        }
    }
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
                        HStack(spacing: RowMetrics.gap) {
                            FormIconTile(icon: option.icon)
                            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                                Text(option.title).textRole(.body)
                                if let subtitle = option.subtitle {
                                    Text(subtitle)
                                        .textRole(.caption)
                                        .foregroundStyle(Palette.secondaryText)
                                }
                            }
                            Spacer()
                            SolarIcon("solar-alt-arrow-right-linear", size: 16)
                                .foregroundStyle(Palette.secondary)
                        }
                        .padding(.horizontal, RowMetrics.horizontal)
                        .padding(.vertical, RowMetrics.vertical)
                        .frame(minHeight: RowMetrics.minHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .timiFittedSheet()
    }
}

/// Picks one value in a short sheet: rows with a check on the current one; picking closes it.
struct ChoiceSheet<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: title)
            FormGroup {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    Button {
                        selection = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(label(option)).textRole(.body)
                            Spacer()
                            if option == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Palette.primary)
                            }
                        }
                        .padding(.horizontal, RowMetrics.horizontal)
                        .padding(.vertical, RowMetrics.vertical)
                        .frame(minHeight: RowMetrics.minHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option == selection ? .isSelected : [])
                    .overlay(alignment: .top) { if index > 0 { FormDivider(hasIcon: false) } }
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .timiFittedSheet()
    }
}

extension View {
    /// Closes the keyboard when the user taps outside a field or drags the content.
    /// Fields, buttons and pickers inside keep their own taps; only empty space reaches this one.
    func dismissesKeyboardOnTap() -> some View {
        self
            .keyboardDoneButton()
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    /// "Xong" above the keyboard, as in Apple's own apps: the number pad has no Return key, so this
    /// is the one obvious way to close it. Put it once on the screen or sheet, not on each field,
    /// or iOS stacks one button per field.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Xong") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
                .tint(Palette.primary)
            }
        }
    }
}

/// Haptics for actions that close the view they start in (save, delete, pick and close), where
/// `.sensoryFeedback` could vanish with the view. Changes that stay on screen use `.sensoryFeedback`.
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
