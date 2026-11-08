import SwiftUI
import UIKit

/// "Sắp xếp": the groups of a kind, or a group's items, with the drag handles showing, as
/// Reminders and Mail order their lists (review 2026-11-08: nothing could be moved, and the order
/// is the one the category picker shows). ✓ keeps the new order, ✕ drops it.
///
/// The list is UIKit's own table (`ReorderTable`), not SwiftUI's `List`: after a drop, `List` drew
/// the lines a beat late and the ground under the lifted row flickered, even with iOS drawing its
/// colours (user report 2026-11-08, twice). Each row is still the app's SwiftUI label.
struct CategoryOrderSheet: View {
    let title: String
    @State private var order: [Category]

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    init(title: String, categories: [Category]) {
        self.title = title
        _order = State(initialValue: categories)
    }

    var body: some View {
        NavigationStack {
            ReorderTable(items: $order,
                         footer: "Kéo tay nắm ở cuối dòng để đổi chỗ. Thứ tự này cũng là thứ tự khi chọn hạng mục.")
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
                    ToolbarItem(placement: .confirmationAction) { confirmButton }
                }
        }
        .timiSheetStyle()
    }

    /// iOS's ✓, as every sheet of the app (`SheetScaffold`), in the app's own tint: opened from
    /// the category picker it took iOS's blue (Simulator check 2026-11-08).
    private var confirmButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(role: .confirm, action: save)
            } else {
                Button(action: save) { Image(systemName: "checkmark").fontWeight(.semibold) }
                    .accessibilityLabel("Xong")
            }
        }
        .tint(Palette.primary)
    }

    private func save() {
        // A "saved" tick only when it was (review 2026-11-08).
        if store.reorder(order.map(\.id)) { Haptics.success() } else { Haptics.error() }
        dismiss()
    }
}

/// An inset-grouped `UITableView` always in editing mode with only the reorder handles: lift,
/// move, drop and lines drawn by UIKit as in iOS's own apps. Rows show `FormRowLabel` through
/// `UIHostingConfiguration`; a drop writes the new order to `items`. Coloured as every sheet of
/// the app (user report 2026-11-08: iOS's grey was the wrong ground): the sheet's white (blue at
/// night), the rows the same in a card with Milu's quiet 1pt edge and 26 corners.
private struct ReorderTable: UIViewControllerRepresentable {
    @Binding var items: [Category]
    let footer: String

    func makeUIViewController(context: Context) -> Controller {
        Controller(items: items, footer: footer) { items = $0 }
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        // Only an order from outside: the table's own drop already shows the order it wrote.
        guard controller.items.map(\.id) != items.map(\.id) else { return }
        controller.items = items
        controller.tableView.reloadData()
    }

    final class Controller: UITableViewController {
        var items: [Category]
        private let footer: String
        private let onMove: ([Category]) -> Void
        private static let cellID = "row"
        /// The card's edge: a ring one point wider than the rows, behind them, so only its rim
        /// shows and a lifted row passes over it rather than under it.
        private let edge = UIView()

        init(items: [Category], footer: String, onMove: @escaping ([Category]) -> Void) {
            self.items = items
            self.footer = footer
            self.onMove = onMove
            super.init(style: .insetGrouped)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.register(RowCell.self, forCellReuseIdentifier: Self.cellID)
            tableView.isEditing = true
            tableView.allowsSelectionDuringEditing = false
            // As every sheet of the app (`timiSheetStyle`): no scroll bar.
            tableView.showsVerticalScrollIndicator = false
            tableView.backgroundColor = UIColor(Palette.surface)
            tableView.separatorColor = UIColor(Palette.separator)
            // White inside with only its rim in the line colour: filled with it, the gap a
            // lifted row leaves showed blue (user report 2026-11-08).
            edge.backgroundColor = UIColor(Palette.surface)
            edge.layer.borderWidth = 1
            paintEdge()
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
                self.paintEdge()
            }
            edge.layer.cornerCurve = .continuous
            edge.layer.cornerRadius = CardCorners.card + 1
            edge.isUserInteractionEnabled = false
            tableView.insertSubview(edge, at: 0)
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            layoutEdge()
        }

        /// A layer's border takes a fixed colour: set again for light or dark.
        private func paintEdge() {
            edge.layer.borderColor = UIColor(Palette.separator).resolvedColor(with: traitCollection).cgColor
        }

        /// Around the rows from the first to the last, as wide as they are.
        private func layoutEdge() {
            guard !items.isEmpty else {
                edge.isHidden = true
                return
            }
            // The section less its header and footer: it holds still while a row is dragged, where
            // the first and last rows' places followed the lifted row (user report 2026-11-08:
            // the top edge went missing, the bottom one ran over the footer). An inset-grouped
            // section stands in the table's side margins (the cells span the whole width, their
            // ground drawn inside).
            let section = tableView.rect(forSection: 0)
            let top = max(section.minY, tableView.rectForHeader(inSection: 0).maxY)
            let footer = tableView.rectForFooter(inSection: 0)
            let bottom = footer.height > 0 ? footer.minY : section.maxY
            let margins = tableView.layoutMargins
            edge.isHidden = false
            edge.frame = CGRect(x: margins.left, y: top,
                                width: tableView.bounds.width - margins.left - margins.right,
                                height: bottom - top)
                .insetBy(dx: -1, dy: -1)
            tableView.sendSubviewToBack(edge)
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            items.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
            let category = items[indexPath.row]
            (cell as? RowCell)?.categoryID = category.id
            (cell as? RowCell)?.showsLine = indexPath.row < items.count - 1
            cell.contentConfiguration = UIHostingConfiguration {
                FormRowLabel(title: category.name, icon: category.icon)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
            }
            .margins(.vertical, RowMetrics.vertical)
            var ground = UIBackgroundConfiguration.listGroupedCell()
            ground.backgroundColor = UIColor(Palette.surface)
            ground.cornerRadius = CardCorners.card
            cell.backgroundConfiguration = ground
            cell.showsReorderControl = true
            cell.selectionStyle = .none
            return cell
        }

        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            footer
        }

        // Handles only: no red minus, no indent.
        override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            .none
        }

        override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
            false
        }

        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }

        override func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
            let moved = items.remove(at: source.row)
            items.insert(moved, at: destination.row)
            onMove(items)
            // The row now last loses its line, the one that was last gains one, at once as the
            // row is dropped (known by what each row shows, not where the table has it yet).
            let last = items.last?.id
            for case let cell as RowCell in tableView.visibleCells {
                cell.showsLine = cell.categoryID != last
            }
        }
    }

    /// A row that draws its own one line, at its foot, where iOS puts its separator (and none on
    /// the last row). iOS's own lines are hidden: a lifted row carried one above and one below,
    /// and dropped into a place that already had both, the lines showed twice as it landed (user
    /// report 2026-11-08). With one line each, a dropped row's line meets the one above exactly.
    final class RowCell: UITableViewCell {
        var showsLine = true {
            didSet { setNeedsLayout() }
        }
        /// What the row shows, to tell the last one after a drop.
        var categoryID: String?
        private let line = UIView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            line.backgroundColor = UIColor(Palette.separator)
            line.isUserInteractionEnabled = false
            addSubview(line)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func layoutSubviews() {
            super.layoutSubviews()
            // iOS's separators: their place is copied (the inset from the words to the edge,
            // under the handle too), then they are hidden.
            var place: CGRect?
            for view in subviews where view !== line && String(describing: type(of: view)).contains("Separator") {
                if place == nil || view.frame.minY > place!.minY { place = view.frame }
                view.isHidden = true
            }
            guard let place else {
                line.isHidden = true
                return
            }
            line.frame = CGRect(x: place.minX, y: bounds.height - place.height,
                                width: place.width, height: place.height)
            line.isHidden = !showsLine
            bringSubviewToFront(line)
        }
    }
}
