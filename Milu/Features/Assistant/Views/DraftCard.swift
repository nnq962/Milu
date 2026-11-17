import SwiftUI

/// The card of transactions Milu made ready, under its answer: every field of every row in sight
/// before "Lưu" (user choice 2026-11-17), as the lists of transactions show them, with what the
/// app chose ("tự chọn"), an item it will make, a twin already saved that day, or why a row cannot
/// be saved. Waiting, a row opens to be changed; saved, to be viewed. Several said at once share
/// the card, a line on top with how many and how much.
struct DraftCard: View {
    let draft: TransactionDraft
    let onRow: (UUID) -> Void

    @Environment(FinanceStore.self) private var store
    @ScaledMetric(relativeTo: .body) private var iconColumn = RowMetrics.iconColumn

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if draft.rows.count > 1 {
                Text(summary)
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryLabel)
                    .padding(.horizontal, RowMetrics.horizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.xs)
            }
            ForEach(Array(draft.rows.enumerated()), id: \.element.id) { index, row in
                rowView(row)
                    .separatorAbove(index > 0, order: index) { RowDivider() }
            }
            if let problem = draft.problem {
                Text(problem)
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.negative)
                    .padding(.horizontal, RowMetrics.horizontal)
                    .padding(.bottom, Spacing.m)
            }
        }
        .cardSurface(radius: CardCorners.card)
        .cardShadow()
    }

    /// "3 khoản · Chi 100.000đ · Thu 20.000.000đ".
    private var summary: String {
        let rows = draft.liveRows.map(\.transaction)
        let spent = rows.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        let earned = rows.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        return (["\(rows.count) khoản"] + [spent > 0 ? "Chi \(spent.vnd)" : nil, earned > 0 ? "Thu \(earned.vnd)" : nil]
            .compactMap { $0 }).joined(separator: " · ")
    }

    private func rowView(_ row: TransactionDraft.Row) -> some View {
        let transaction = row.transaction
        let opens = draft.isPending || (draft.state == .saved && !row.removed && store.transaction(id: row.id) != nil)
        return Button { onRow(row.id) } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ListRow(icon: icon(of: row),
                        title: row.newItem.map { "\($0.name) (mới)" } ?? store.categoryName(transaction.categoryID),
                        subtitle: subtitle(of: row),
                        trailingSubtitle: "\(transaction.date.shortDay) · \(DraftChecks.time(transaction.date))",
                        amount: transaction.amount,
                        amountTone: transaction.kind == .income ? .signedIncome : .outflow,
                        showsChevron: draft.isPending)
                ForEach(lines(of: row), id: \.text) { line in
                    Text(line.text)
                        .textRole(.caption)
                        .foregroundStyle(line.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, RowMetrics.horizontal + RowMetrics.capped(iconColumn, base: RowMetrics.iconColumn) + RowMetrics.gap)
                        .padding(.trailing, RowMetrics.horizontal)
                }
            }
            .padding(.bottom, lines(of: row).isEmpty ? 0 : Spacing.m)
            .opacity(row.removed ? 0.5 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.row)
        .disabled(!opens)
        .accessibilityHint(draft.isPending ? "Sửa khoản này trước khi lưu" : opens ? "Xem giao dịch" : "")
    }

    private func icon(of row: TransactionDraft.Row) -> String {
        if let item = row.newItem { return store.categoryIcon(item.groupID) }
        return store.categoryIcon(row.transaction.categoryID)
    }

    /// "Chi · Ví tiền mặt (tự chọn)": spending or income, said, and the account, with whether Milu
    /// chose it.
    private func subtitle(of row: TransactionDraft.Row) -> String {
        if row.removed { return "Đã xoá" }
        let transaction = row.transaction
        let account = store.account(id: transaction.accountID)?.name
            ?? store.archivedAccounts.first { $0.id == transaction.accountID }?.name ?? "Tài khoản không còn"
        let kind = transaction.kind == .income ? "Thu" : "Chi"
        return "\(kind) · \(account)\(row.accountChosenByApp && draft.isPending ? " (tự chọn)" : "")"
    }

    private struct Line {
        let text: String
        let color: Color
    }

    /// Under the row: why it cannot be saved, a twin saved that day, the item to make, the note.
    private func lines(of row: TransactionDraft.Row) -> [Line] {
        guard !row.removed else { return [] }
        var lines: [Line] = []
        if let problem = row.problem, draft.isPending { lines.append(Line(text: problem, color: Palette.negative)) }
        if let warning = row.warning, draft.isPending { lines.append(Line(text: warning, color: Palette.warningLabel)) }
        if let item = row.newItem, draft.isPending {
            lines.append(Line(text: "Bấm Lưu sẽ tạo mục mới trong \(store.categoryName(item.groupID)).",
                              color: Palette.secondaryLabel))
        }
        let note = row.transaction.note.components(separatedBy: .newlines).first ?? ""
        if !note.isEmpty { lines.append(Line(text: "Ghi chú: \(note)", color: Palette.secondaryLabel)) }
        return lines
    }
}
