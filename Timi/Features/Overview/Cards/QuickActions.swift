import SwiftUI

/// The row of shortcuts under the lead card, straight on the page, all alike: flat white
/// circles with a hairline (HIG pass 2026-10-31: a button inside scrolling content is not glass).
/// Ghi chi, Ghi thu, Chuyển tiền open the add sheet on that mode; Trợ lý AI opens the assistant's
/// page. The name under a circle is part of its button, one control for VoiceOver (design-system
/// pass 2026-10-31: it was a tap gesture of its own). At the accessibility text sizes they go two
/// by two, as four in a row ran into each other (HIG review 2026-10-30).
struct QuickActions: View {
    let onOpenAssistant: () -> Void

    /// The glyph in a shortcut's circle.
    private static let glyph = RowMetrics.iconColumn

    @State private var mode: AddTransactionView.Mode?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let columns = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: columns),
                  alignment: .center, spacing: Spacing.l) {
            action("Ghi chi", icon: "hugeicons-pencil-edit-02") { mode = .expense }
            action("Ghi thu", icon: "hugeicons-add-circle") { mode = .income }
            action("Chuyển tiền", icon: "hugeicons-arrow-data-transfer-horizontal") { mode = .transfer }
            action("Trợ lý AI", icon: "hugeicons-ai-magic", action: onOpenAssistant)
        }
        .sheet(item: $mode) { AddTransactionView(mode: $0) }
    }

    private func action(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.s) {
                // A white circle with a hairline, the glyph in the primary colour, as the round
                // buttons of the Iconly mock-ups (user 2026-10-31: no grey discs).
                TimiIcon(icon, size: Self.glyph)
                    .foregroundStyle(Palette.primary)
                    .frame(width: ControlHeight.large, height: ControlHeight.large)
                    .background(Palette.surface, in: Circle())
                    .cardOutline(Circle())
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
