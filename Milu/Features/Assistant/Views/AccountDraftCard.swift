import SwiftUI

/// The card of accounts Milu made ready, under its answer, set as the card of transactions is
/// (`DraftCard`): "Milu soạn 2 tài khoản", a dashed rule, each account as the Tài khoản tab lists
/// it (`AccountRow`: logo, name, kind, balance), then what Milu chose for the user, what to look
/// at and why it cannot be saved, and the buttons at its foot. Waiting for "Lưu", a row opens its
/// form to be changed (user request 2026-11-20).
struct AccountDraftCard: View {
    let draft: AccountDraft
    let onRow: (UUID) -> Void
    var actions: AnyView? = nil

    @Environment(FinanceStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Milu soạn \(draft.rows.count) tài khoản")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
                .padding(.horizontal, RowMetrics.horizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.s)
            DashedRule()
                .padding(.horizontal, RowMetrics.horizontal)
            VStack(spacing: 0) {
                ForEach(draft.rows) { row in rowView(row) }
            }
            footer
                .padding(.horizontal, RowMetrics.horizontal)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.m)
            if let actions {
                actions
                    .padding(.horizontal, RowMetrics.horizontal)
                    .padding(.bottom, Spacing.m)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: CardCorners.card)
        .cardShadow()
    }

    /// Saved, the account as it now is in the store (renamed since, its balance moved).
    private func shown(_ row: AccountDraft.Row) -> Account {
        draft.state == .saved ? store.account(id: row.id) ?? row.account : row.account
    }

    private func rowView(_ row: AccountDraft.Row) -> some View {
        let account = shown(row)
        let opens = draft.isPending
        return Button { onRow(row.id) } label: {
            AccountRow(account: account, showsChevron: false, subtitle: subtitle(of: account))
                .contentShape(Rectangle())
        }
        .buttonStyle(.row)
        .disabled(!opens)
        .accessibilityHint(opens ? "Sửa tài khoản này trước khi lưu" : "")
    }

    /// "Ngân hàng", "Ví điện tử · Ví đi chợ".
    private func subtitle(of account: Account) -> String {
        let kind = account.type == .credit ? AccountType.bank.title : account.type.title
        let note = account.detail.components(separatedBy: .newlines).first ?? ""
        return note.isEmpty ? kind : "\(kind) · \(note)"
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if draft.isPending {
                ForEach(notices, id: \.self) { notice in
                    Text(notice)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !warnings.isEmpty { NoticeBox(lines: warnings, tone: .warning) }
                if !problems.isEmpty { NoticeBox(lines: problems, tone: .problem) }
                Text(draft.rows.count > 1 ? "Bấm vào một tài khoản để sửa" : "Bấm vào tài khoản để sửa")
                    .textRole(.caption)
                    .foregroundStyle(Palette.tertiaryLabel)
            }
        }
    }

    private var notices: [String] { draft.rows.compactMap(\.notice) }
    private var warnings: [String] { draft.rows.compactMap(\.warning) }

    private var problems: [String] {
        draft.rows.compactMap { row in row.problem.map { "\(row.account.name): \($0)" } } + (draft.problem.map { [$0] } ?? [])
    }
}
