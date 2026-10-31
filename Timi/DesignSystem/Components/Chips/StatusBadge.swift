import SwiftUI

/// Meaning of a badge; colour is used sparingly, red only for real warnings. "Thông tin" was dropped
/// (2026-10-29): its grey could not be told from Trung tính, and no screen used it.
enum BadgeTone: CaseIterable, Identifiable {
    case neutral, positive, pro, caution, warning

    var id: Self { self }

    var name: String {
        switch self {
        case .neutral: "Trung tính"
        case .positive: "Đã thu"
        case .pro: "Pro"
        case .caution: "Sắp đến hạn"
        case .warning: "Quá hạn"
        }
    }

    fileprivate var background: Color {
        switch self {
        case .neutral: Palette.fill
        // White with a hairline (`isOutlined`): a grey pill read as neutral, and a green tint is a
        // fill the monochrome set has none of; the dot carries the meaning.
        case .positive: Palette.surface
        case .pro: Palette.primary
        case .caution: Palette.warning.opacity(0.16)
        // White with a hairline too: red words on a red tint were 4.3:1, under 4.5 for 13pt
        // (review 2026-10-31); on white they are 4.9:1.
        case .warning: Palette.surface
        }
    }

    fileprivate var isOutlined: Bool { self == .positive || self == .warning }

    fileprivate var foreground: Color {
        switch self {
        case .warning: Palette.negative
        // Orange words on the orange tint are too light to read: the deep orange.
        case .caution: Palette.warningLabel
        case .pro: Palette.onPrimary
        default: Palette.label
        }
    }

    fileprivate var dot: Color {
        switch self {
        case .neutral: Palette.tertiaryLabel
        case .positive: Palette.positive
        // White on the black pill (user report 2026-10-31: it was ink on ink).
        case .pro: Palette.onPrimary
        case .caution: Palette.warning
        case .warning: Palette.negative
        }
    }
}

/// Pill 24 tall with a dot: status, counts, labels. With `icon`, a small icon takes the dot's place
/// ("Không tính 300.000đ đang khoá" with a lock).
struct StatusBadge: View {
    static let height: CGFloat = 24
    static let horizontalPadding: CGFloat = 10
    static let gap: CGFloat = 6
    static let dot: CGFloat = 6
    static let icon: CGFloat = 14

    let title: String
    var tone: BadgeTone = .neutral
    var showsDot = true
    var icon: String? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Self.gap) {
            if let icon {
                TimiIcon(icon, size: Self.icon)
            } else if showsDot {
                Circle().fill(tone.dot).frame(width: Self.dot, height: Self.dot)
            }
            // One line, two at the accessibility sizes; cut short with "…" rather than pushed
            // past the screen (review 2026-10-31: `fixedSize` let long badges overflow).
            Text(title)
                .textRole(.captionStrong)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .monospacedDigit()
        }
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, Self.horizontalPadding)
        // At least 24, taller with large text instead of spilling out of the pill.
        .padding(.vertical, Spacing.xxs)
        .frame(minHeight: Self.height)
        .background(tone.background, in: Capsule())
        .overlay { if tone.isOutlined { Capsule().strokeBorder(Palette.separator, lineWidth: 1) } }
        .accessibilityElement(children: .combine)
    }
}
