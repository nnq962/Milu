import Foundation

/// Hạng mục: nhóm, mục, ẩn, sắp xếp.
extension FinanceStore {
    /// What a transaction is called: its category ("Ăn trưa"); it has no name of its own.
    func title(of transaction: FinanceTransaction) -> String {
        categoryName(transaction.categoryID)
    }

    /// The name a transaction shows for its category: the item ("Ăn sáng"), an old transaction's
    /// group ("Ăn uống"), or the system's ("Điều chỉnh số dư").
    func categoryName(_ id: String) -> String {
        category(id: id)?.name ?? TransactionCategory(rawValue: id)?.title ?? "Hạng mục đã xoá"
    }

    func categoryIcon(_ id: String) -> String {
        category(id: id)?.icon ?? LineIconEmoji.asset(for: TransactionCategory(rawValue: id)?.icon ?? "hugeicons-tag-01")
    }

    /// The group a category belongs to (itself for a group or a system category).
    func groupID(of id: String) -> String {
        category(id: id)?.parentID ?? id
    }

    /// Items that can be picked for a new transaction: in use, in a group in use, of `kind`.
    func pickableItems(_ kind: TransactionKind) -> [Category] {
        groups(kind).flatMap { items(of: $0) }
    }

    /// The items last used for `kind`, newest first, still pickable.
    func recentItems(_ kind: TransactionKind, limit: Int = 4) -> [Category] {
        let pickable = Dictionary(uniqueKeysWithValues: pickableItems(kind).map { ($0.id, $0) })
        var seen = Set<String>()
        // By when it was recorded, not its date: one recorded today for last week is recent too.
        return transactions.sorted { $0.createdAt > $1.createdAt }.compactMap { transaction -> Category? in
            guard let item = pickable[transaction.categoryID], seen.insert(item.id).inserted else { return nil }
            return item
        }
        .prefix(limit).map { $0 }
    }

    func groups(_ kind: TransactionKind, hidden: Bool = false) -> [Category] {
        categories.filter { $0.isGroup && $0.kind == kind && $0.isHidden == hidden }
    }

    /// A group's items in use (or the hidden ones).
    func items(of group: Category, hidden: Bool = false) -> [Category] {
        categories.filter { $0.parentID == group.id && $0.isHidden == hidden }
    }

    func category(id: String) -> Category? {
        categories.first { $0.id == id }
    }

    /// Hidden groups and hidden items of one kind, for "Hạng mục đã ẩn". An item inside a hidden
    /// group is not listed on its own: it comes back with its group.
    func hiddenCategories(_ kind: TransactionKind) -> [Category] {
        let hiddenGroups = Set(categories.filter { $0.isGroup && $0.isHidden }.map(\.id))
        return categories.filter { $0.kind == kind && $0.isHidden && !hiddenGroups.contains($0.parentID ?? "") }
            .sorted { ($0.hiddenAt ?? .distantPast) > ($1.hiddenAt ?? .distantPast) }
    }

    /// Whether a transaction is filed under it (for a group: under it or any of its items); such a
    /// category is hidden, not deleted.
    ///
    /// The built-in groups (`TransactionCategory`) always count as used: transactions from before
    /// items existed may be filed under the group itself, so those groups are hidden, never deleted.
    func hasHistory(_ category: Category) -> Bool {
        if category.isGroup, TransactionCategory(rawValue: category.id) != nil { return true }
        let ids = Set([category.id] + categories.filter { $0.parentID == category.id }.map(\.id))
        return transactions.contains { ids.contains($0.categoryID) }
    }

    /// Adds or changes a category. A new group comes with its first item (a transaction is always
    /// filed under an item): `firstItem` names it, or it takes the group's name.
    func save(_ category: Category, firstItem: String? = nil) {
        persist {
            var category = category
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index] = category
            } else {
                category.sortOrder = (categories.map(\.sortOrder).max() ?? 0) + 100
                categories.append(category)
                if category.isGroup {
                    let item = Category(id: UUID().uuidString, kind: category.kind, parentID: category.id,
                                        name: firstItem ?? category.name, icon: category.icon,
                                        sortOrder: category.sortOrder + 1)
                    categories.append(item)
                    database?.save(item)
                }
            }
            sortCategories()
            database?.save(category)
        }
    }

    /// Hides (with history) or deletes (without) a category; a group takes its items with it. The
    /// last item of a group cannot go on its own (see `canRemove`).
    ///
    /// A group with history is hidden together with its items (same time), so "Hiện lại" brings
    /// them back as they were; a group without history is deleted with its items.
    func remove(_ category: Category) {
        guard canRemove(category) else { return }
        persist {
            if category.isGroup {
                let members = categories.filter { $0.parentID == category.id }
                if hasHistory(category) {
                    let now = Date.now
                    for item in members where !item.isHidden { setHidden(item.id, at: now) }
                    setHidden(category.id, at: now)
                } else {
                    for item in members { deleteOne(item.id) }
                    deleteOne(category.id)
                }
            } else if hasHistory(category) {
                setHidden(category.id, at: .now)
            } else {
                deleteOne(category.id)
            }
        }
    }

    /// An item can be moved to another group unless it is the last one in use in its own.
    func canMove(_ category: Category) -> Bool { canRemove(category) }

    /// An item can go unless it is the last one still in use in its group; a group, unless it is
    /// the last one in use of its kind (spending or income always has somewhere to go).
    func canRemove(_ category: Category) -> Bool {
        guard !category.isHidden else { return true }
        guard let parentID = category.parentID else { return groups(category.kind).count > 1 }
        guard let group = self.category(id: parentID) else { return true }
        return items(of: group).count > 1
    }

    private func setHidden(_ id: String, at date: Date?) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[index].hiddenAt = date
        database?.save(categories[index])
    }

    private func deleteOne(_ id: String) {
        categories.removeAll { $0.id == id }
        database?.deleteCategory(id: id)
    }

    /// Shows a hidden category again. An item's hidden group comes back with it. A group comes
    /// back with the items hidden together with it, not those the user had hidden on their own
    /// before; if none is left, its first item comes back too, so it is never empty.
    func unhide(_ category: Category) {
        persist {
            guard let current = self.category(id: category.id) else { return }
            // An item in a hidden group: the whole group comes back, with the items hidden with it.
            if let parentID = current.parentID, let parent = self.category(id: parentID), parent.isHidden {
                unhide(parent)
            }
            setHidden(current.id, at: nil)
            if current.isGroup, let hiddenAt = current.hiddenAt {
                let members = categories.filter { $0.parentID == current.id }
                for item in members where item.hiddenAt.map({ $0 >= hiddenAt }) == true {
                    setHidden(item.id, at: nil)
                }
                if let group = self.category(id: current.id), items(of: group).isEmpty, let first = members.first {
                    setHidden(first.id, at: nil)
                }
            }
        }
    }

    /// Items to count and show: in use, in a group in use.
    var visibleItemCount: Int {
        let hiddenGroups = Set(categories.filter { $0.isGroup && $0.isHidden }.map(\.id))
        return categories.filter { !$0.isGroup && !$0.isHidden && !hiddenGroups.contains($0.parentID ?? "") }.count
    }

    /// Puts siblings (the groups of a kind, or a group's items in use) in the order of `ids`, in
    /// the places they already held, so hidden siblings and every other list keep theirs. Two that
    /// shared a place are set one apart, or the new order could not show. False when one of them
    /// is gone, and then nothing moves.
    @discardableResult
    func reorder(_ ids: [String]) -> Bool {
        var slots = ids.compactMap { id in categories.first { $0.id == id }?.sortOrder }.sorted()
        guard slots.count == ids.count else { return false }
        persist {
            for index in slots.indices.dropFirst() where slots[index] <= slots[index - 1] {
                slots[index] = slots[index - 1] + 1
            }
            for (id, slot) in zip(ids, slots) {
                guard let index = categories.firstIndex(where: { $0.id == id }) else { continue }
                categories[index].sortOrder = slot
                database?.save(categories[index])
            }
            sortCategories()
        }
        return true
    }

    private func sortCategories() {
        categories.sort { $0.sortOrder < $1.sortOrder }
    }
}
