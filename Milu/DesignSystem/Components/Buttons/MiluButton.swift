import SwiftUI

/// What a button does on the screen; each role maps to one flat fill.
enum MiluButtonRole: CaseIterable, Identifiable {
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
        case .primary: Palette.accent
        case .secondary: Palette.fill
        case .destructive: Palette.expenseSoft
        }
    }

    fileprivate var foreground: Color {
        switch self {
        case .primary: Palette.onAccent
        case .secondary: Palette.label
        case .destructive: Palette.negative
        }
    }
}

enum MiluButtonSize {
    case regular
    /// A smaller visual footprint for actions within cards; the touch target stays 44pt.
    case compact
}

/// A flat pill button with a minimum 44pt touch target.
/// Not glass: these sit in content (user choice 2026-10-31, glass only on the bars).
struct MiluButton<Label: View>: View {
    let role: MiluButtonRole
    var fullWidth = false
    var size: MiluButtonSize = .regular
    let action: () -> Void
    @ViewBuilder var label: Label

    init(role: MiluButtonRole, fullWidth: Bool = false, size: MiluButtonSize = .regular,
         action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.role = role
        self.fullWidth = fullWidth
        self.size = size
        self.action = action
        self.label = label()
    }

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: action) {
            label
                .textRole(size == .compact ? .buttonCompact : .button)
                // Disabled: every role turns into a grey pill with faint text, so it never reads
                // as tappable.
                .foregroundStyle(isEnabled ? role.foreground : Palette.tertiaryLabel)
                // Two lines at the accessibility sizes, centred, rather than "Thêm tài kh…"
                // (review 2026-11-08).
                .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                .multilineTextAlignment(.center)
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

extension MiluButton where Label == MiluButtonTitle {
    init(_ title: String, icon: String? = nil, role: MiluButtonRole,
         fullWidth: Bool = false, size: MiluButtonSize = .regular, action: @escaping () -> Void) {
        self.init(role: role, fullWidth: fullWidth, size: size, action: action) {
            MiluButtonTitle(title: title, icon: icon)
        }
    }
}

/// Optional icon before the title.
struct MiluButtonTitle: View {
    let title: String
    let icon: String?

    var body: some View {
        HStack(spacing: Spacing.s) {
            if let icon { MiluIcon(icon, size: IconSize.control) }
            Text(title)
        }
    }
}
