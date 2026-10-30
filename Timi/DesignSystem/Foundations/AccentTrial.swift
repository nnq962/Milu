import SwiftUI
import Observation

/// Tries colour combos across the whole app without a rebuild (user request 2026-10-30): a
/// primary colour with a page tinted faintly toward it, never a plain grey, as Apple's apps do.
/// Picked in Cài đặt → Nhà phát triển, saved on the device. `Palette` reads the choice, and since
/// this is `@Observable`, every screen showing it redraws at once.
@Observable
final class AccentTrial {
    static let shared = AccentTrial()

    struct Choice: Identifiable, Equatable {
        let id: String
        let name: String
        let color: Color
        /// The page, then the quiet blocks on it, the hairlines and the chat field: one hue,
        /// a few percent toward the primary.
        let background: Color
        let muted: Color
        let border: Color
        let input: Color
        /// Too light for white words on it: they take ink instead. None of the combos is; kept for
        /// a light one added later.
        var isLight = false
    }

    static let choices: [Choice] = [
        Choice(id: "moss", name: "Rêu & Kem", color: rgb(62, 91, 63),
               background: rgb(250, 247, 242), muted: rgb(241, 238, 230), border: rgb(236, 231, 220), input: rgb(244, 241, 234)),
        Choice(id: "blue", name: "Xanh biển & Ngà lạnh", color: rgb(31, 95, 209),
               background: rgb(246, 248, 252), muted: rgb(235, 239, 247), border: rgb(227, 232, 242), input: rgb(239, 242, 249)),
        Choice(id: "emerald", name: "Lục bảo & Bạc hà", color: rgb(18, 128, 92),
               background: rgb(243, 248, 245), muted: rgb(230, 239, 234), border: rgb(221, 232, 226), input: rgb(235, 243, 238)),
        Choice(id: "indigo", name: "Chàm & Oải hương", color: rgb(79, 70, 200),
               background: rgb(247, 246, 253), muted: rgb(236, 234, 248), border: rgb(228, 225, 243), input: rgb(240, 238, 250)),
        Choice(id: "amber", name: "Hổ phách & Giấy", color: rgb(199, 102, 26),
               background: rgb(251, 246, 238), muted: rgb(243, 235, 221), border: rgb(237, 227, 210), input: rgb(246, 239, 228)),
    ]

    var choice: Choice {
        didSet { UserDefaults.standard.set(choice.id, forKey: StorageKey.accentTrial) }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: StorageKey.accentTrial)
        choice = Self.choices.first { $0.id == saved } ?? Self.choices[0]
    }

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}

/// "Màu (thử)" in Cài đặt → Nhà phát triển: one swatch per combo, its page with the primary on
/// it, the chosen one ringed.
struct AccentTrialRow: View {
    private let trial = AccentTrial.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Text("Màu (thử)")
                    .textRole(.body)
                Spacer()
                Text(trial.choice.name)
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryText)
            }
            HStack(spacing: Spacing.m) {
                ForEach(AccentTrial.choices) { choice in
                    let isChosen = choice == trial.choice
                    Button { trial.choice = choice } label: {
                        // The page colour with the primary laid over its lower half.
                        Circle()
                            .fill(choice.background)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(choice.color).frame(height: 18)
                            }
                            .clipShape(Circle())
                            .overlay { Circle().strokeBorder(Palette.ink.opacity(0.08)) }
                            .frame(width: 36, height: 36)
                            .padding(4)
                            .overlay {
                                Circle().strokeBorder(isChosen ? Palette.ink : .clear, lineWidth: 2)
                            }
                            .frame(minWidth: ControlHeight.regular, minHeight: ControlHeight.regular)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(choice.name)
                    .accessibilityAddTraits(isChosen ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: trial.choice)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
    }
}
