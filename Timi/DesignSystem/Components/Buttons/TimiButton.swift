import SwiftUI

/// What a button does on the screen; each role maps to one flat fill.
enum TimiButtonRole: CaseIterable, Identifiable {
    /// The one main action of a screen or sheet (Lưu, Thêm).
    case primary
    /// Secondary actions inside content.
    case secondary
    /// Delete beside the main action: light, so that one stays the main action.
    case destructive

    var id: Self { self }

    var name: String {
        switch self {
        case .primary: "Chính"
        case .secondary: "Phụ"
        case .destructive: "Xoá"
        }
    }

    var usage: String {
        switch self {
        case .primary: "Một nút chính mỗi màn: Lưu, Thêm"
        case .secondary: "Hành động phụ trong nội dung"
        case .destructive: "Xoá nhẹ, cạnh một nút chính"
        }
    }

    fileprivate var fill: Color {
        switch self {
        case .primary: Palette.primary
        case .secondary: Palette.fill
        case .destructive: Palette.negative.opacity(0.14)
        }
    }

    fileprivate var foreground: Color {
        switch self {
        case .primary: Palette.onPrimary
        case .secondary: Palette.label
        case .destructive: Palette.negative
        }
    }
}

/// A pill button: a flat fill in the role's colour, the body role's words, 44 tall (one size:
/// the 36 and 56 of before had no caller, and 36 was under the touch target; review 2026-10-31).
/// Not glass: these sit in content (user choice 2026-10-31, glass only on the bars).
struct TimiButton<Label: View>: View {
    let role: TimiButtonRole
    var fullWidth = false
    let action: () -> Void
    @ViewBuilder var label: Label

    init(role: TimiButtonRole, fullWidth: Bool = false,
         action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.role = role
        self.fullWidth = fullWidth
        self.action = action
        self.label = label()
    }

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            label
                .textRole(.body)
                // Disabled: every role turns into a grey pill with faint text, so it never reads
                // as tappable.
                .foregroundStyle(isEnabled ? role.foreground : Palette.tertiaryLabel)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xl)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: ControlHeight.regular)
        }
        .flatCapsuleButton(fill: isEnabled ? role.fill : Palette.fill)
    }
}

extension TimiButton where Label == TimiButtonTitle {
    init(_ title: String, icon: String? = nil, role: TimiButtonRole,
         fullWidth: Bool = false, action: @escaping () -> Void) {
        self.init(role: role, fullWidth: fullWidth, action: action) {
            TimiButtonTitle(title: title, icon: icon)
        }
    }
}

/// Optional icon before the title.
struct TimiButtonTitle: View {
    let title: String
    let icon: String?

    var body: some View {
        HStack(spacing: Spacing.s) {
            if let icon { TimiIcon(icon, size: RowMetrics.iconGlyph) }
            Text(title)
        }
    }
}
