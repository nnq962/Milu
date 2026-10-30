import SwiftUI

/// Rounded track with a filled portion; every progress bar in the app is 8pt tall.
struct ProgressBar: View {
    static let height: CGFloat = 8

    let value: Double
    var color: Color = Palette.primary

    /// Spending against a limit: ink below 80%, orange (`warning`) from 80%, red once it is used up.
    static func budgetColor(_ ratio: Double) -> Color {
        switch ratio {
        // Ink while well within: green read as the app's moss though it means nothing to tap
        // (user request 2026-10-30); colour is kept for the warnings.
        case ..<0.8: Palette.ink
        case ..<1: Palette.warning
        default: Palette.red
        }
    }

    /// 0…1; a value that is not a number (0 ÷ 0) draws an empty bar instead of an invalid frame.
    private var fraction: Double { value.isFinite ? min(max(value, 0), 1) : 0 }

    var body: some View {
        Capsule()
            .fill(Palette.muted)
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
