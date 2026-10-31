import SwiftUI

/// Where a spending limit stands, in one line: a small glyph and a caption in sentence case, grey
/// while fine, orange from 80%, red once over. One look wherever a limit is shown: the month card
/// on Thu chi, the note under a spending being typed, the limit row of Báo cáo (strict review
/// 2026-10-31: there were three, icon 14 or 16 or none, `caption` or `captionStrong`, lower case).
struct BudgetStatusLine: View {
    enum Level { case fine, nearing, over }

    let level: Level
    let text: String

    /// The glyph grows with the caption beside it.
    @ScaledMetric(relativeTo: .caption) private var glyph = RowMetrics.inlineGlyph

    var body: some View {
        // A Label, so the glyph sits centred on the first line when the words wrap.
        Label {
            Text(text)
                .monospacedDigit()
                .contentTransition(.numericText())
        } icon: {
            TimiIcon(level == .fine ? "hugeicons-chart-increase" : "hugeicons-alert-circle", size: glyph)
        }
        .textRole(.caption)
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        switch level {
        case .fine: Palette.secondaryText
        case .nearing: Palette.warningText
        case .over: Palette.red
        }
    }
}

extension BudgetStatusLine.Level {
    /// The level of a limit with this much spent: orange from 80%, red once over.
    init(_ progress: BudgetProgress) {
        self = progress.isOver ? .over : progress.isNearing ? .nearing : .fine
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.m) {
        BudgetStatusLine(level: .fine, text: "Đã dùng 42% hạn mức")
        BudgetStatusLine(level: .nearing, text: "Đã dùng 86% hạn mức, còn 4,2tr")
        BudgetStatusLine(level: .over, text: "Vượt hạn mức 2tr")
    }
    .padding()
}
