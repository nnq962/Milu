import SwiftUI

/// The row of shortcuts under the lead card, straight on the page, all alike:
/// circles with the card edge (HIG pass 2026-10-31: a button inside scrolling content is not glass).
/// Ghi chi, Ghi thu, Chuyển tiền open the add sheet on that mode; Trợ lý AI opens the assistant's
/// page. The name under a circle is part of its button, one control for VoiceOver (design-system
/// pass 2026-10-31: it was a tap gesture of its own). At the accessibility text sizes they go two
/// by two, as four in a row ran into each other (HIG review 2026-10-30).
struct QuickActions: View {
    let onOpenAssistant: () -> Void

    /// The circle and its glyph grow with the names under them: at the accessibility sizes a fixed
    /// 56 with a 24 glyph looked tiny under large words (review 2026-10-31).
    @ScaledMetric(relativeTo: .body) private var circle = ControlHeight.large
    @ScaledMetric(relativeTo: .body) private var glyph = RowMetrics.iconColumn

    @State private var mode: AddTransactionView.Mode?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let columns = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0, alignment: .top), count: columns),
                  alignment: .center, spacing: Spacing.l) {
            action("Ghi chi", icon: "hugeicons-money-send-02") { mode = .expense }
            action("Ghi thu", icon: "hugeicons-money-receive-02") { mode = .income }
            action("Chuyển tiền", icon: "hugeicons-arrow-data-transfer-horizontal") { mode = .transfer }
            action("Trợ lý AI", icon: "hugeicons-ai-magic", action: onOpenAssistant)
        }
        .sheet(item: $mode) { AddTransactionView(mode: $0) }
    }

    private func action(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.s) {
                // A circle with the card edge, the glyph in the primary colour (user 2026-10-31: no
                // grey discs).
                TimiIcon(icon, size: glyph)
                    .foregroundStyle(Palette.primary)
                    .frame(width: circle, height: circle)
                    .background { Circle().fill(Palette.surface).cardEdge(Circle()) }
                Text(title)
                    .textRole(.caption)
                    .foregroundStyle(Palette.label)
                    // Two lines rather than cut off when the text is large.
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        .accessibilityLabel(title)
    }
}
