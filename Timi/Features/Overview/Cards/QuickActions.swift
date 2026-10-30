import SwiftUI

/// The row of shortcuts under the lead card, straight on the page like a wallet app's (user
/// request 2026-10-30: fewer cards), all alike, glass circles: Ghi chi, Ghi thu, Chuyển tiền open the
/// add sheet on that mode; Trợ lý AI opens the assistant's page. At the accessibility text sizes
/// they go two by two, as four in a row ran into each other (HIG review 2026-10-30).
struct QuickActions: View {
    let onOpenAssistant: () -> Void

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
        VStack(spacing: Spacing.s) {
            // Apple's Liquid Glass circle (user request 2026-10-30, over the white circles with a
            // shadow); the system draws the press, so no custom style.
            Button(action: action) {
                // The glass hugs its label plus its own padding, so the label sets the circle's
                // size: 40 here makes the 56 circle, as 28 does the 44 ones.
                TimiIcon(icon, size: 24)
                    .foregroundStyle(Palette.primary)
                    .frame(width: 40, height: 40)
            }
            .nativeCircleButton(diameter: 56)
            .accessibilityLabel(title)
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.ink)
                // Two lines rather than cut off when the text is large.
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                // The name below the circle opens the same thing.
                .onTapGesture(perform: action)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
