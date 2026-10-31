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

enum TimiButtonSize {
    case regular
    /// A smaller visual footprint for actions within cards; the touch target stays 44pt.
    case compact
}

/// A flat pill button with a minimum 44pt touch target.
/// Not glass: these sit in content (user choice 2026-10-31, glass only on the bars).
struct TimiButton<Label: View>: View {
    let role: TimiButtonRole
    var fullWidth = false
    var size: TimiButtonSize = .regular
    let action: () -> Void
    @ViewBuilder var label: Label

    init(role: TimiButtonRole, fullWidth: Bool = false, size: TimiButtonSize = .regular,
         action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.role = role
        self.fullWidth = fullWidth
        self.size = size
        self.action = action
        self.label = label()
    }

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            label
                .textRole(size == .compact ? .captionStrong : .body)
                // Disabled: every role turns into a grey pill with faint text, so it never reads
                // as tappable.
                .foregroundStyle(isEnabled ? role.foreground : Palette.tertiaryLabel)
                .lineLimit(1)
                .padding(.horizontal, size == .compact ? Spacing.m : Spacing.xl)
                .padding(.vertical, Spacing.xs)
                .frame(maxWidth: fullWidth ? .infinity : nil,
                       minHeight: size == .compact ? ControlHeight.small : ControlHeight.regular)
                .background(isEnabled ? role.fill : Palette.fill, in: Capsule())
                .frame(minHeight: ControlHeight.regular)
                .contentShape(Rectangle())
        }
        .buttonStyle(.card)
    }
}

extension TimiButton where Label == TimiButtonTitle {
    init(_ title: String, icon: String? = nil, role: TimiButtonRole,
         fullWidth: Bool = false, size: TimiButtonSize = .regular, action: @escaping () -> Void) {
        self.init(role: role, fullWidth: fullWidth, size: size, action: action) {
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
