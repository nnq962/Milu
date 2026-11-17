import SwiftUI

/// The card of transactions Milu made ready, under its answer, as a receipt (user pick "B"
/// 2026-11-17: the rows' account, day and notes were said again on every row and floated apart
/// from it): "Milu soạn 3 khoản" and when, a thin line per transaction (its item, its note under
/// it, its amount), the total under a dashed rule, the account once, and what to look at (a twin
/// already saved, a row that cannot be saved) gathered in a box of its own. Waiting for "Lưu", a
/// row opens to be changed; saved, to be viewed.
struct DraftCard: View {
    let draft: TransactionDraft
    let onRow: (UUID) -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var live: [TransactionDraft.Row] { draft.liveRows }

    /// Two sizes of words on the card, as on every list card: 16 for the rows and the total, 13
    /// for all the rest (review 2026-11-17: 12 and 13 sat side by side). The rows keep their own
    /// 10 above and below; the dashed rules sit 8 under the words over them.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, RowMetrics.horizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.s)
            DashedRule()
                .padding(.horizontal, RowMetrics.horizontal)
            VStack(spacing: 0) {
                ForEach(draft.rows) { row in rowView(row) }
            }
            if live.count > 1 {
                DashedRule()
                    .padding(.horizontal, RowMetrics.horizontal)
                totals
                    .padding(.horizontal, RowMetrics.horizontal)
                    .padding(.top, RowMetrics.vertical)
            }
            footer
                .padding(.horizontal, RowMetrics.horizontal)
                .padding(.top, live.count > 1 ? Spacing.m : Spacing.xs)
                .padding(.bottom, Spacing.m)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: CardCorners.card)
        .cardShadow()
    }

    // MARK: - Đầu thẻ

    /// "Milu soạn 3 khoản" and, when they all share it, the day and time ("Hôm nay, 12:20").
    /// At the accessibility sizes the moment goes under, whole, rather than broken after "Hôm nay,".
    private var header: some View {
        AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s, stackedSpacing: RowMetrics.lineGap) {
            Text("Milu soạn \(live.isEmpty ? draft.rows.count : live.count) khoản")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
            if let moment = sharedMoment {
                Text(moment)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The day all rows share, with the time when that is shared too; nil when the days differ
    /// (each row says its own).
    private var sharedMoment: String? {
        guard let first = live.first?.transaction.date else { return nil }
        let calendar = Calendar.current
        guard live.allSatisfy({ calendar.isDate($0.transaction.date, inSameDayAs: first) }) else { return nil }
        let sameMinute = live.allSatisfy {
            calendar.isDate($0.transaction.date, equalTo: first, toGranularity: .minute)
        }
        return sameMinute ? "\(Self.day(first)), \(DraftChecks.time(first))" : Self.day(first)
    }

    private static func day(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Hôm nay" }
        if calendar.isDateInYesterday(date) { return "Hôm qua" }
        return date.shortDay
    }

    // MARK: - Dòng

    /// Set as every list of transactions sets its rows (`ListRow`, review 2026-11-17: the card's
    /// rows were lighter and their pictures smaller than on Giao dịch): the 32 picture, the name
    /// in `bodyStrong` with the line under it in `caption`, the amount "−" in ink or "+" in green,
    /// 16 at the sides, at least 52 tall. Unlike a list's, the line under a row wraps: it may say
    /// an item is made on "Lưu", and cut short it said nothing.
    private func rowView(_ row: TransactionDraft.Row) -> some View {
        let transaction = row.transaction
        let opens = draft.isPending || (draft.state == .saved && !row.removed && store.transaction(id: row.id) != nil)
        let detail = detail(of: row)
        let large = dynamicTypeSize.isAccessibilitySize
        // One line: the picture and the amount on the name's line; two: on the row's middle.
        let alignment: VerticalAlignment = large || detail == nil ? .firstTextBaseline : .center
        return Button { onRow(row.id) } label: {
            HStack(alignment: alignment, spacing: RowMetrics.gap) {
                RowIcon(name: icon(of: row))
                    .centeredOnTextLine()
                    .opacity(row.removed ? 0.5 : 1)
                AdaptiveStack(alignment: alignment, spacing: Spacing.s) {
                    VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                        Text(title(of: row))
                            .textRole(.bodyStrong)
                            .foregroundStyle(row.removed ? Palette.secondaryLabel : Palette.label)
                            .strikethrough(row.removed)
                        if let detail {
                            Text(detail)
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if !large { Spacer(minLength: 0) }
                    MoneyText(amount: transaction.amount, size: .row,
                              tone: row.removed ? .muted : transaction.kind == .income ? .signedIncome : .outflow)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
            .frame(minHeight: RowMetrics.minHeight)
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

    /// The item's name; a new one says so.
    private func title(of row: TransactionDraft.Row) -> String {
        if let item = row.newItem { return "\(item.name) (mới)" }
        return store.categoryName(row.transaction.categoryID)
    }

    /// The small line under a row: its note; where it differs from the others, its account and
    /// day; an item to make; or that it was deleted since.
    private func detail(of row: TransactionDraft.Row) -> String? {
        if row.removed { return "Đã xoá" }
        let transaction = row.transaction
        var parts: [String] = []
        let note = transaction.note.components(separatedBy: .newlines).first ?? ""
        if !note.isEmpty { parts.append(note) }
        if let item = row.newItem, draft.isPending {
            parts.append("tạo mục mới trong \(store.categoryName(item.groupID)) khi Lưu")
        }
        if sharedAccount == nil { parts.append(accountName(transaction.accountID)) }
        if sharedMoment == nil {
            parts.append("\(Self.day(transaction.date)), \(DraftChecks.time(transaction.date))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Tổng và chân thẻ

    /// "Tổng chi 85.000đ" in red, and "Tổng thu" in green when money comes in too: a total its
    /// words already name, with no sign (`MoneyText.Tone.expense`, as Giao dịch's month card).
    private var totals: some View {
        let spent = live.filter { $0.transaction.kind == .expense }.reduce(0) { $0 + $1.transaction.amount }
        let earned = live.filter { $0.transaction.kind == .income }.reduce(0) { $0 + $1.transaction.amount }
        return VStack(spacing: Spacing.xs) {
            if spent > 0 { totalLine("Tổng chi", amount: spent, tone: .expense) }
            if earned > 0 { totalLine("Tổng thu", amount: earned, tone: .income) }
        }
    }

    private func totalLine(_ title: String, amount: Double, tone: MoneyText.Tone) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textRole(.bodyStrong)
                .foregroundStyle(Palette.label)
            Spacer(minLength: Spacing.s)
            MoneyText(amount: amount, size: .rowStrong, tone: tone)
        }
        .accessibilityElement(children: .combine)
    }

    /// The account, once ("Từ Vietcombank · Milu tự chọn"), the boxes of what to look at, and
    /// while it waits, that a row opens.
    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let account = sharedAccount {
                let chosen = draft.isPending && live.allSatisfy(\.accountChosenByApp)
                let word = live.allSatisfy { $0.transaction.kind == .income } ? "Vào" : "Từ"
                Text("\(word) \(accountName(account))\(chosen ? " · Milu tự chọn" : "")")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            if draft.isPending, !warnings.isEmpty {
                NoticeBox(lines: warnings, tone: .warning)
            }
            if draft.isPending, !problems.isEmpty {
                NoticeBox(lines: problems, tone: .problem)
            }
            if draft.isPending, live.count > 0 {
                Text(live.count > 1 ? "Bấm vào một khoản để sửa" : "Bấm vào khoản để sửa")
                    .textRole(.caption)
                    .foregroundStyle(Palette.tertiaryLabel)
            }
        }
    }

    /// The account every row is on, when they are all on one.
    private var sharedAccount: Account.ID? {
        guard let first = live.first?.transaction.accountID,
              live.allSatisfy({ $0.transaction.accountID == first }) else { return nil }
        return first
    }

    private func accountName(_ id: Account.ID) -> String {
        store.account(id: id)?.name ?? "Tài khoản không còn"
    }

    /// Twins saved that day ("Hôm nay đã có Cà phê 35.000đ lúc 06:51.").
    private var warnings: [String] { live.compactMap(\.warning) }

    /// Why rows cannot be saved, each with its row's name, and the card's own.
    private var problems: [String] {
        let rows = live.compactMap { row in row.problem.map { "\(title(of: row)): \($0)" } }
        return rows + (draft.problem.map { [$0] } ?? [])
    }
}

/// A thin dashed line across the card, as on a receipt.
private struct DashedRule: View {
    var body: some View {
        Line()
            .stroke(Palette.separator, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

/// What to look at before "Lưu", gathered in one tinted box: twins saved that day (warning), or
/// rows that cannot be saved as they are (problem).
private struct NoticeBox: View {
    enum Tone { case warning, problem }
    let lines: [String]
    let tone: Tone
    /// The ⚠ grows with the words and sits on the middle of their first line (review 2026-11-17:
    /// at the largest sizes it stayed 14 at the top of a 2-line notice).
    @ScaledMetric(relativeTo: .subheadline) private var glyph = RowMetrics.inlineGlyph
    @ScaledMetric(relativeTo: .subheadline) private var lift: CGFloat = TextRole.caption.size * 0.705 / 2

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            MiluIcon("hugeicons-alert-02", size: glyph)
                .foregroundStyle(foreground)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + lift }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .textRole(.caption)
                        .foregroundStyle(foreground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(background, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var foreground: Color { tone == .warning ? Palette.warningLabel : Palette.negative }
    private var background: Color { tone == .warning ? Palette.warningSoft : Palette.expenseSoft }
}
