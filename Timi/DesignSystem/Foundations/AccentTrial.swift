import SwiftUI
import Observation

/// Tries colour combos across the whole app without a rebuild (user request 2026-10-30): a
/// primary colour with a page tinted faintly toward it, as Apple's apps do; and since 2026-10-31
/// a monochrome set, where the words and every other hue change with it.
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
        /// The words and the other hues: the warm moss set unless a combo brings its own (the
        /// monochrome one, 2026-10-31, where every hue but red and orange is a grey).
        var neutrals = Neutrals.moss
        var hues = Hues.moss
    }

    /// Ink, the two greys and the fills that follow ink.
    struct Neutrals: Equatable {
        let ink: Color
        let secondaryText: Color
        let secondary: Color

        static let moss = Neutrals(ink: rgb(31, 42, 34), secondaryText: rgb(111, 103, 91), secondary: rgb(150, 142, 130))
        /// Plain near-black and iOS's own greys.
        static let mono = Neutrals(ink: rgb(17, 17, 17), secondaryText: rgb(110, 110, 115), secondary: rgb(174, 174, 178))
    }

    /// Good signs, the second hue, the accent and the chart's shades.
    struct Hues: Equatable {
        let green: Color
        let sky: Color
        let lime: Color
        /// Words on `lime`: ink on a bright accent, white on a dark one.
        let onLime: Color
        let chartCoral: Color
        let chartRest: Color
        /// The chart's four shades, largest group first; nil means primary · sky · lime · coral.
        var chartSteps: [Color]? = nil

        static let moss = Hues(green: rgb(30, 90, 72), sky: rgb(95, 184, 154), lime: rgb(201, 242, 107), onLime: rgb(31, 42, 34),
                               chartCoral: rgb(232, 145, 122), chartRest: rgb(169, 185, 160))
        /// Monochrome as in the Iconly mock-ups (user 2026-10-31: black and white, no mid greys):
        /// good signs and the accent in ink, white words on the accent (a black pill), and the
        /// data told apart by small vivid marks: the chart in blue · orange · coral · violet, as
        /// the storage bar of the mock-up, the second hue that blue.
        static let mono = Hues(green: rgb(17, 17, 17), sky: rgb(47, 124, 246), lime: rgb(17, 17, 17), onLime: .white,
                               chartCoral: rgb(245, 85, 93), chartRest: rgb(209, 209, 214),
                               chartSteps: [rgb(47, 124, 246), rgb(245, 166, 35), rgb(245, 85, 93), rgb(124, 77, 255)])
    }

    static let choices: [Choice] = [
        // The monochrome study (user request 2026-10-31): near-black for every primary thing on
        // a near-white page, grey only as a faint block and a hairline, red kept for money out.
        // Default while it is being judged.
        // The page a step whiter than iOS's grouped grey (user request 2026-10-31), neutral, so the
        // white cards still read against it by their shadow and a hair of contrast.
        Choice(id: "mono", name: "Đơn sắc", color: rgb(17, 17, 17),
               background: rgb(250, 250, 250), muted: rgb(243, 243, 244), border: rgb(232, 232, 234), input: rgb(245, 245, 246),
               neutrals: .mono, hues: .mono),
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
/// it, the chosen one ringed. Labelled like its neighbours (icon, title, value), the swatches
/// under the title, so every row of the group starts at the icon column and the hairline above
/// lines up (strict review 2026-10-31: no icon, words at 16 among rows at 54).
struct AccentTrialRow: View {
    private static let swatch: CGFloat = 36
    private let trial = AccentTrial.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                FormRowLabel(title: "Màu (thử)", icon: "hugeicons-paint-board")
                Spacer(minLength: Spacing.s)
                Text(trial.choice.name)
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
            }
            .frame(minHeight: RowMetrics.minHeight - 2 * RowMetrics.vertical)
            // 8 apart: five 44 targets then take 252, inside the 265 a 375pt phone leaves under the
            // title (re-review 2026-10-31: at 12 the row ran 268 and spilled on an SE).
            HStack(spacing: Spacing.s) {
                ForEach(AccentTrial.choices) { choice in
                    let isChosen = choice == trial.choice
                    Button { trial.choice = choice } label: {
                        // The page colour with the primary laid over its lower half.
                        Circle()
                            .fill(choice.background)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(choice.color).frame(height: Self.swatch / 2)
                            }
                            .clipShape(Circle())
                            .overlay { Circle().strokeBorder(Palette.ink.opacity(0.08)) }
                            .frame(width: Self.swatch, height: Self.swatch)
                            .padding(Spacing.xs)
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
            // Under the title, not under the icon.
            .padding(.leading, RowMetrics.dividerInset - RowMetrics.horizontal)
            .sensoryFeedback(.selection, trigger: trial.choice)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
    }
}
