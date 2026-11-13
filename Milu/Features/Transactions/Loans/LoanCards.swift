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

/// A loan as a row in its section's block, like the accounts on Tài khoản (user request
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
    /// False inside the person's own sheet (Danh bạ): "Cho vay" or "Đi vay" with money going out
    /// or coming in, where their initial and name would repeat on every row (review 2026-11-08).
    var showsPerson = true

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let urgency = LoanUrgency(loan, today: today)
        let borrowed = loan.direction == .borrowed
        ListRow(title: title, subtitle: subtitle(), hasTrailingNote: true) {
            if showsPerson {
                InitialsAvatar(name: loan.name, size: RowMetrics.listLogo)
            } else {
                RowIcon(name: borrowed ? "hugeicons-money-receive-02" : "hugeicons-money-send-02",
                        size: RowMetrics.listLogo)
            }
        } trailing: {
            // Still owed by me: money going out, in ink with "−" as every amount going out
            // ("B+", review 2026-11-07); under it the deadline in the urgency's colour.
            ListRowAmount(amount: loan.isSettled ? loan.principal : loan.outstanding,
                          tone: Self.amountTone(loan),
                          note: urgency.text, noteColor: Self.urgencyColor(urgency))
        }
        // In words: "Minh Trần, hạn 6/11, đã trả 40%, còn 45.000.000 đồng, còn 7 ngày".
        .accessibilityElement(children: .ignore)
        // The deadline's day in words ("hạn 6 tháng 11"), not "6/11" (review 2026-11-08).
        .accessibilityLabel([title, FormDateRow.spokenDays(in: subtitle(spoken: true)),
                             loan.isSettled ? MoneyText.spoken(loan.principal)
                                 : "còn \(borrowed ? "nợ " : "")\(MoneyText.spoken(loan.outstanding))",
                             urgency.text].filter { !$0.isEmpty }.joined(separator: ", "))
        .accessibilityHint("Xem khoản vay")
    }

    /// The loan's person, or its side ("Cho vay") without them (`showsPerson`).
    private var title: String { showsPerson ? loan.name : loan.direction.title }

    /// The deadline's day and how much is repaid once something is ("Hạn 6/11 · Đã trả 40%"); the
    /// relationship when there is no deadline; "Lãi 1tr" too when it bears interest. Settled: the
    /// side with the relationship ("Cho vay · Bạn bè"), since both sides' amounts are in ink there
    /// (re-review 2026-10-31). `spoken`: the interest in words for VoiceOver ("đồng", not "đ").
    /// Without the person (`showsPerson` false) the side is the title and the relationship is on
    /// the sheet already: settled, or open with nothing else to say, the day it began ("Từ 12/3").
    private func subtitle(spoken: Bool = false) -> String {
        let relationship = showsPerson ? loan.contactID.flatMap { store.contact(id: $0) }
            .map { store.relationship(id: $0.relationshipID).name } : nil
        let since = "Từ \(loan.date.shortDay)"
        if loan.isSettled {
            return showsPerson ? [loan.direction.title, relationship].compactMap { $0 }.joined(separator: " · ") : since
        }
        let due = loan.dueDate.map { "Hạn \($0.shortDay)" } ?? relationship
        let interest = loan.monthlyInterestRate > 0
            ? "Lãi \(spoken ? MoneyText.spoken(loan.monthlyInterest) : loan.monthlyInterest.vnd)" : nil
        // How much is repaid only once something is: "Chưa trả" made the line wrap for little.
        let paid = loan.paidRatio > 0 ? loan.paidText : nil
        let parts = [due, interest, paid].compactMap { $0 }
        return parts.isEmpty && !showsPerson ? since : parts.joined(separator: " · ")
    }

    /// What is left: still owed by me with "−", in ink as all money going out ("B+", review
    /// 2026-11-07); owed to me, or settled, plain.
    static func amountTone(_ loan: Loan) -> MoneyText.Tone {
        loan.direction == .borrowed && !loan.isSettled ? .outflow : .neutral
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

    /// The bar on the loan's sheet takes the deadline's colour when it is close, else the
    /// progress colour, either side: red only once overdue (review 2026-11-07).
    static func progressColor(for loan: Loan, urgency: LoanUrgency) -> Color {
        switch urgency {
        case .overdue: Palette.negative
        case .soon: Palette.warning
        case .settled: Palette.progressDone
        default: Palette.progress
        }
    }
}

/// Loans as rows in one block, hairlines between them; tapping one hands it back.
struct LoanRowList: View {
    let loans: [Loan]
    var today = Date.now
    /// See `LoanRow.showsPerson`.
    var showsPerson = true
    let onOpen: (Loan) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(loans.enumerated()), id: \.element.id) { index, loan in
                Button { onOpen(loan) } label: { LoanRow(loan: loan, today: today, showsPerson: showsPerson) }
                    .buttonStyle(.row)
                    // From where the names start, the avatar column scaled with the text.
                    .separatorAbove(index > 0, order: index) { RowDivider(column: .logo) }
            }
        }
        .listCard()
    }
}
