import SwiftUI

/// How near a loan's deadline is, for its badge and its place in the list (user request
/// 2026-10-29): overdue red, within a week orange, otherwise grey. A far deadline is grey on the
/// sheet as in the list, not green (strict review 2026-10-31: one deadline, two colours).
enum LoanUrgency: Comparable {
    case overdue(days: Int)
    case soon(days: Int)
    case upcoming(days: Int)
    case later(days: Int)
    case noDeadline
    case settled

    init(_ loan: Loan, today: Date = .now) {
        guard !loan.isSettled else { self = .settled; return }
        guard let due = loan.dueDate else { self = .noDeadline; return }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: today),
                                           to: calendar.startOfDay(for: due)).day ?? 0
        switch days {
        case ..<0: self = .overdue(days: -days)
        case 0...7: self = .soon(days: days)
        case 8...30: self = .upcoming(days: days)
        default: self = .later(days: days)
        }
    }

    /// Urgent first: the longest overdue, then the nearest deadline; no deadline last.
    var rank: Double {
        switch self {
        case .overdue(let days): -Double(days)
        case .soon(let days), .upcoming(let days), .later(let days): Double(days) + 1
        case .noDeadline: .infinity
        case .settled: .infinity
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }

    var text: String {
        switch self {
        case .overdue(let days): "Quá hạn \(days) ngày"
        case .soon(0): "Đến hạn hôm nay"
        case .soon(1): "Còn 1 ngày"
        case .soon(let days), .upcoming(let days), .later(let days): "Còn \(days) ngày"
        case .noDeadline: "Không có hạn"
        case .settled: "Đã tất toán"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .overdue: .warning
        case .soon: .caution
        case .upcoming, .later, .noDeadline: .neutral
        case .settled: .positive
        }
    }
}

extension Array where Element == Loan {
    /// Urgent first (see `LoanUrgency.rank`); the same deadline, the larger amount left first.
    func byUrgency(today: Date = .now) -> [Loan] {
        sorted { lhs, rhs in
            let left = LoanUrgency(lhs, today: today), right = LoanUrgency(rhs, today: today)
            if left.rank != right.rank { return left < right }
            return lhs.outstanding > rhs.outstanding
        }
    }
}

/// A loan as a row in its section's white block, like the accounts on Tài khoản (user request
/// 2026-10-30: a big card per loan, each with a badge and a bar, read as clutter). The person's
/// initial, their name with the deadline and how much is repaid under it; on the right what is
/// left, with how near the deadline is in its colour (red overdue, orange within a week).
///
/// Strict review 2026-10-31: the row has the account row's metrics (52 high, the initial in the
/// logo column, scaled with the text), so Vay nợ and Tài khoản read as one kind of list.
struct LoanRow: View {
    let loan: Loan
    /// Passed in so the deadline moves on overnight with the page.
    var today = Date.now

    @Environment(FinanceStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The same column as an account's logo; grows with the text so the letter stays inside.
    @ScaledMetric(relativeTo: .body) private var avatar = RowMetrics.listLogo

    var body: some View {
        let urgency = LoanUrgency(loan, today: today)
        let borrowed = loan.direction == .borrowed
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
        HStack(spacing: RowMetrics.gap) {
            InitialsAvatar(name: loan.name, size: avatar)
            layout {
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(loan.name)
                        .textRole(.body)
                        // Whole at the accessibility sizes, as an account's name (re-review 2026-10-31).
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    // One line, so the amount keeps its room; whole at the accessibility sizes.
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                }
                // The stack's own spacing is the gap, as on an account row (re-review 2026-10-31).
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: RowMetrics.lineGap) {
                    // Still owed by me: money going out, red with "-" as on the top card and the
                    // loan's sheet (strict review 2026-10-31).
                    MoneyText(amount: loan.isSettled ? loan.principal : loan.outstanding,
                              tone: Self.amountTone(loan), compact: true)
                        .fixedSize()
                    Text(urgency.text)
                        .textRole(.caption)
                        .foregroundStyle(Self.urgencyColor(urgency))
                        .lineLimit(1)
                }
                .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: false)
                .layoutPriority(1)
            }
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
            RowChevron()
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        // In words: "Minh Trần, hạn 6/11, đã trả 40%, còn 45.000.000 đ, còn 7 ngày".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([loan.name, subtitle,
                             loan.isSettled ? loan.principal.vnd
                                 : "còn \(borrowed ? "nợ " : "")\(loan.outstanding.vnd)",
                             urgency.text].joined(separator: ", "))
        .accessibilityHint("Xem khoản vay")
    }

    /// The deadline's day and how much is repaid once something is ("Hạn 6/11 · Đã trả 40%"); the
    /// relationship when there is no deadline; "Lãi 1tr" too when it bears interest. Settled: the
    /// side with the relationship ("Cho vay · Bạn bè"), since both sides' amounts are in ink there
    /// (re-review 2026-10-31).
    private var subtitle: String {
        let relationship = loan.contactID.flatMap { store.contact(id: $0) }
            .map { store.relationship(id: $0.relationshipID).name }
        if loan.isSettled { return [loan.direction.title, relationship].compactMap { $0 }.joined(separator: " · ") }
        let due = loan.dueDate.map { "Hạn \($0.shortDay)" } ?? relationship
        let interest = loan.monthlyInterestRate > 0 ? "Lãi \(loan.monthlyInterest.vndCompact)" : nil
        // How much is repaid only once something is: "Chưa trả" made the line wrap for little.
        let paid = loan.paidRatio > 0 ? loan.paidText : nil
        return [due, interest, paid].compactMap { $0 }.joined(separator: " · ")
    }

    /// What is left: still owed by me red with "-"; owed to me, or settled, in ink.
    static func amountTone(_ loan: Loan) -> MoneyText.Tone {
        loan.direction == .borrowed && !loan.isSettled ? .signedExpense : .plain
    }

    /// The deadline in words takes the urgency's colour: red overdue, orange within a week,
    /// green once settled, as the sheet's badge (re-review 2026-10-31), grey otherwise.
    static func urgencyColor(_ urgency: LoanUrgency) -> Color {
        switch urgency {
        case .overdue: Palette.negative
        case .soon: Palette.warningLabel
        case .settled: Palette.positive
        default: Palette.secondaryLabel
        }
    }

    /// The bar on the loan's sheet takes the deadline's colour when it is close, else the side's.
    static func progressColor(for loan: Loan, urgency: LoanUrgency) -> Color {
        switch urgency {
        case .overdue: Palette.negative
        case .soon: Palette.warning
        case .settled: Palette.positive
        default: loan.direction == .borrowed ? Palette.negative : Palette.primary
        }
    }
}

/// Loans as rows in one white block, hairlines between them; tapping one hands it back.
struct LoanRowList: View {
    let loans: [Loan]
    var today = Date.now
    let onOpen: (Loan) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(loans.enumerated()), id: \.element.id) { index, loan in
                Button { onOpen(loan) } label: { LoanRow(loan: loan, today: today) }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) {
                        // From where the names start, the avatar column scaled with the text.
                        if index > 0 { RowDivider(column: .logo) }
                    }
            }
        }
        .listCard()
    }
}
