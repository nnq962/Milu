import SwiftUI

/// Meaning of a badge; colour is used sparingly, red only for real warnings.
enum BadgeTone: CaseIterable, Identifiable {
    case neutral, positive, accent, info, warning

    var id: Self { self }

    var name: String {
        switch self {
        case .neutral: "Trung tính"
        case .positive: "Đã thu"
        case .accent: "Pro"
        case .info: "Thông tin"
        case .warning: "Sắp đến hạn"
        }
    }

    fileprivate var background: Color {
        switch self {
        case .neutral: Palette.fill2
        case .positive: Palette.green.opacity(0.12)
        case .accent: Palette.lime
        case .info: Palette.secondarySurface
        case .warning: Palette.red.opacity(0.10)
        }
    }

    fileprivate var foreground: Color {
        self == .warning ? Palette.red : Palette.ink
    }

    fileprivate var dot: Color {
        switch self {
        case .neutral, .info: Palette.secondary
        case .positive: Palette.green
        case .accent: Palette.ink
        case .warning: Palette.red
        }
    }
}

/// Pill 24 tall with a dot: status, counts, labels.
struct StatusBadge: View {
    let text: String
    var tone: BadgeTone = .neutral
    var showsDot = true

    var body: some View {
        HStack(spacing: 6) {
            if showsDot {
                Circle().fill(tone.dot).frame(width: 6, height: 6)
            }
            Text(text).textRole(.captionStrong).lineLimit(1)
        }
        .fixedSize()
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(tone.background, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
