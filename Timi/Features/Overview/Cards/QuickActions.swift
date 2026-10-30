import SwiftUI

/// The row of shortcuts under the lead card, straight on the page like a wallet app's (user
/// request 2026-10-30: fewer cards), all alike, white circles: Ghi chi, Ghi thu, Chuyển tiền open the
/// add sheet on that mode; Trợ lý AI opens the assistant's page.
struct QuickActions: View {
    let onOpenAssistant: () -> Void

    @State private var mode: AddTransactionView.Mode?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
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
                // White on the cream page with a soft shadow, like the card above them (user
                // request 2026-10-30: the mint read as dull).
                TimiIcon(icon, size: 24)
                    .foregroundStyle(Palette.primary)
                    .frame(width: 56, height: 56)
                    .background(Palette.card, in: Circle())
                    .shadow(color: .black.opacity(0.06), radius: 1.5, y: 1)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                Text(title)
                    .textRole(.caption)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
    }
}
