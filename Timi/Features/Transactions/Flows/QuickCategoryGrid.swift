import SwiftUI

/// The items most used for `kind`, as a grid of round icons under the amount (user request
/// 2026-10-30, as MoMo and Money Lover do): most spending is the amount and one tap. The
/// "Hạng mục" row below still opens every item.
struct QuickCategoryGrid: View {
    let kind: TransactionKind
    @Binding var selection: String

    @Environment(FinanceStore.self) private var store

    /// Most used first, by how many transactions sit under each; topped up in the list's order.
    private var items: [Category] {
        let pickable = store.pickableItems(kind)
        let counts = Dictionary(grouping: store.transactions.filter { $0.kind == kind }, by: \.categoryID)
            .mapValues(\.count)
        let used = pickable.filter { counts[$0.id] != nil }
            .sorted { counts[$0.id, default: 0] > counts[$1.id, default: 0] }
        return Array((used + pickable.filter { counts[$0.id] == nil }).prefix(8))
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 4), spacing: Spacing.m) {
            ForEach(items) { item in
                let isChosen = item.id == selection
                Button {
                    Haptics.selection()
                    selection = item.id
                } label: {
                    VStack(spacing: Spacing.xs) {
                        TimiIcon(item.icon, size: 22)
                            .foregroundStyle(isChosen ? Palette.onPrimary : Palette.ink)
                            .frame(width: 52, height: 52)
                            .background(isChosen ? Palette.primary : Palette.card, in: Circle())
                            .shadow(color: .black.opacity(isChosen ? 0 : 0.05), radius: 4, y: 2)
                        // No shrink-to-fit: with the role's exact line height it shrank some names
                        // and not others; a long one is cut off instead.
                        Text(item.name)
                            .textRole(.caption)
                            .foregroundStyle(isChosen ? Palette.primary : Palette.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.card)
                .accessibilityLabel(item.name)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
        .animation(.snappy(duration: 0.2), value: selection)
    }
}
