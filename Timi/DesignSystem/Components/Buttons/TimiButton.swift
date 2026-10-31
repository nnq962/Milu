import SwiftUI

/// What a button does on the screen; each role maps to one flat fill.
enum TimiButtonRole: CaseIterable, Identifiable {
    /// The one main action of a screen or sheet (Lưu, Thêm).
    case primary
    /// Secondary actions inside content.
    case secondary
    /// Amber, for Pro only.
    case accent
    /// Delete next to Save in a sheet footer: light, so Save stays the main action.
    case destructive
    /// The final confirmation of something that cannot be undone.
    case destructiveSolid

    var id: Self { self }

    var name: String {
        switch self {
        case .primary: "Chính"
        case .secondary: "Phụ"
        case .accent: "Nổi bật"
        case .destructive: "Xoá"
        case .destructiveSolid: "Xoá vĩnh viễn"
        }
    }

    var usage: String {
        switch self {
        case .primary: "Một nút chính mỗi màn: Lưu, Thêm"
        case .secondary: "Hành động phụ trong nội dung"
        case .accent: "Chỉ cho Timi Pro"
        case .destructive: "Xoá nhẹ, cạnh một nút chính"
        case .destructiveSolid: "Bước cuối không hoàn tác được"
        }
    }

    fileprivate var fill: Color {
        switch self {
        case .primary: Palette.primary
        case .secondary: Palette.fill2
        case .accent: Palette.lime
        case .destructive: Palette.red.opacity(0.14)
        case .destructiveSolid: Palette.red
        }
    }

    fileprivate var foreground: Color {
        switch self {
        case .primary: Palette.onPrimary
        case .destructiveSolid: Palette.onRed
        case .secondary: Palette.ink
        case .accent: Palette.onLime
        case .destructive: Palette.red
        }
    }
}

enum TimiButtonSize: CaseIterable, Identifiable {
    case small, regular, large

    var id: Self { self }

    var height: CGFloat {
        switch self {
        case .small: ControlHeight.small
        case .regular: ControlHeight.regular
        case .large: ControlHeight.large
        }
    }

    /// Body size (16) on the 44 and 56 buttons, 14 on the small 36 one.
    fileprivate var fontSize: CGFloat { self == .small ? 14 : TextRole.body.size }
    fileprivate var horizontalPadding: CGFloat { self == .small ? Spacing.m : Spacing.xl }
}

/// A pill button: a flat fill in the role's colour, Manrope SemiBold, at least the size's height.
/// Not glass: these sit in content (user choice 2026-10-31, glass only on the bars).
struct TimiButton<Label: View>: View {
    let role: TimiButtonRole
    var size: TimiButtonSize = .regular
    var fullWidth = false
    let action: () -> Void
    @ViewBuilder var label: Label

    init(role: TimiButtonRole, size: TimiButtonSize = .regular, fullWidth: Bool = false,
         action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.role = role
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
        self.label = label()
    }

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            label
                .font(Typography.font(.headline, size: size.fontSize, weight: .semibold))
                // Disabled: every role turns into a grey pill with faint text, so it never reads
                // as tappable.
                .foregroundStyle(isEnabled ? role.foreground : Palette.secondary)
                .lineLimit(1)
                .padding(.horizontal, size.horizontalPadding)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: size.height)
        }
        .flatCapsuleButton(fill: isEnabled ? role.fill : Palette.fill2)
    }
}

extension TimiButton where Label == TimiButtonTitle {
    init(_ title: String, icon: String? = nil, role: TimiButtonRole, size: TimiButtonSize = .regular,
         fullWidth: Bool = false, action: @escaping () -> Void) {
        self.init(role: role, size: size, fullWidth: fullWidth, action: action) {
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
