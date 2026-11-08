import SwiftUI

/// Rounded track with a filled portion; every progress bar in the app is 8pt tall.
struct ProgressBar: View {
    static let height: CGFloat = 8

    let value: Double
    var color: Color = Palette.progress

    /// Spending against a limit: `progress` ink below 80%, amber (`warning`) from 80% up to the
    /// limit itself, red once over it (review 2026-11-08: red at exactly 100% beside the amber
    /// "Hết hạn mức").
    static func budgetColor(_ ratio: Double) -> Color {
        switch ratio {
        // Ink while well within: a coloured bar read as something to tap though it means nothing
        // (user request 2026-10-30); colour is kept for the warnings.
        case ..<0.8: Palette.progress
        case ...1: Palette.warning
        default: Palette.negative
        }
    }

    /// 0…1; a value that is not a number (0 ÷ 0) draws an empty bar instead of an invalid frame.
    private var fraction: Double { value.isFinite ? min(max(value, 0), 1) : 0 }

    var body: some View {
        Capsule()
            .fill(Palette.progressTrack)
            .frame(height: Self.height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .clipShape(Capsule())
    }
}
