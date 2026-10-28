import SwiftUI

/// What a button does on the screen; each role maps to one native glass style.
enum TimiButtonRole: CaseIterable, Identifiable {
    /// The one main action of a screen or sheet (Lưu, Thêm).
    case primary
    /// Secondary actions inside content.
    case secondary
    /// Pro and AI (Nâng cấp).
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
        case .accent: "Pro và AI"
        case .destructive: "Cạnh nút Lưu ở chân sheet"
        case .destructiveSolid: "Bước cuối không hoàn tác được"
        }
    }

    fileprivate var isProminent: Bool { [.primary, .accent, .destructiveSolid].contains(self) }

    fileprivate var tint: Color? {
        switch self {
        case .primary: Palette.primary
        case .secondary: nil
        case .accent: Palette.lime
        case .destructive: Palette.red.opacity(0.14)
        case .destructiveSolid: Palette.red
        }
    }

    fileprivate var foreground: Color {
        switch self {
        case .primary, .destructiveSolid: .white
        case .secondary, .accent: Palette.ink
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
    fileprivate var horizontalPadding: CGFloat { self == .small ? 14 : 20 }
}

/// A pill button: Apple's Liquid Glass with the role's colour, Manrope SemiBold, fixed height.
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
                // Disabled: every role turns into a flat grey pill with faint text, so it never
                // reads as tappable (the glass alone only dims a little).
                .foregroundStyle(isEnabled ? role.foreground : Palette.secondary.opacity(0.7))
                .lineLimit(1)
                .padding(.horizontal, size.horizontalPadding)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: size.labelHeight)
        }
        .nativeGlassButton(prominent: isEnabled && role.isProminent, tint: isEnabled ? role.tint : Palette.fill2)
        .buttonBorderShape(.capsule)
        .modifier(ButtonHeight(height: size.height, fullWidth: fullWidth))
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

/// Optional icon (18pt, as on the web) before the title.
struct TimiButtonTitle: View {
    let title: String
    let icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon { TimiIcon(icon, size: 18) }
            Text(title)
        }
    }
}

/// Glass pads its label by 7pt above and below at the regular control size, so the label is sized
/// to make the whole capsule the token height (measured on iOS 26.3: 14pt text gives a 34pt button).
private struct ButtonHeight: ViewModifier {
    let height: CGFloat
    let fullWidth: Bool

    func body(content: Content) -> some View {
        content.controlSize(.regular)
    }
}

extension TimiButtonSize {
    /// Height of the label inside the glass's own 7pt vertical padding.
    fileprivate var labelHeight: CGFloat { height - 14 }
}
