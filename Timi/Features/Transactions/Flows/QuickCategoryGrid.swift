import SwiftUI

/// The items most used for `kind`, as a grid of tiles in a "Chọn nhanh" card under the amount (user request
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
        // A titled card like the groups under it (user request 2026-10-31: the bare circles on the
        // page read loose, the grey names faint, and it sat tight on "Chi tiết"). The tiles are
        // `ChoiceTile`, shared with the goal's icon (2026-11-05).
        // Worked out once a draw: it counts every transaction, and each tile asked again (review
        // 2026-11-09: nine times on each opening and each tap).
        let items = self.items
        let byID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return FormGroup(title: "Chọn nhanh") {
            ChoiceTileGrid(items: items.map(\.id)) { id in
                if let item = byID[id] {
                    // No haptic here: the "Hạng mục" row below gives one for every change of it.
                    ChoiceTile(icon: item.icon, title: item.name, isChosen: item.id == selection) {
                        selection = item.id
                    }
                }
            }
        }
        .animation(Motion.gentle(.snappy(duration: 0.2)), value: selection)
    }
}
