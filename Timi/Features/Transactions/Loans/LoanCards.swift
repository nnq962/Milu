import SwiftUI

/// How near a loan's deadline is, for its badge and its place in the list (user request
/// 2026-10-29): overdue red, within a week orange, within a month grey, further green.
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
        case .upcoming, .noDeadline: .neutral
        case .later, .settled: .positive
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

/// Loan card (user request 2026-10-29): who, with a badge for how near the deadline is; what is
/// left out of the principal; repayment progress. An overdue loan gets a thin red outline.
struct LoanCard: View {
    let loan: Loan
    /// Passed in so the badge moves on overnight with the page.
    var today = Date.now

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let urgency = LoanUrgency(loan, today: today)
        let borrowed = loan.direction == .borrowed
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: RowMetrics.gap) {
                InitialsAvatar(name: loan.name)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(loan.name)
                        .textRole(.body)
                        .lineLimit(1)
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                StatusBadge(text: urgency.text, tone: urgency.tone)
            }

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(loan.isSettled ? loan.principal.vndCompact : "Còn \(loan.outstanding.vndCompact)")
                    .textRole(.bodyStrong)
                    .foregroundStyle(borrowed && !loan.isSettled ? Palette.red : Palette.ink)
                if !loan.isSettled {
                    Text("/ \(loan.principal.vndCompact)")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                Spacer(minLength: Spacing.s)
                Text(paidText)
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryText)
            }
            .monospacedDigit()
            .padding(.top, Spacing.l)

            ProgressBar(value: loan.paidRatio, color: Self.progressColor(for: loan, urgency: urgency))
                .padding(.top, Spacing.s)
        }
        .sleekCard()
        .overlay {
            if case .overdue = urgency {
                RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
                    .strokeBorder(Palette.red.opacity(0.35), lineWidth: 1)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        // In words: "Minh Trần, còn 8 ngày, còn 45.000.000 đồng trên 75.000.000 đồng, đã trả 40%".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([loan.name, subtitle, urgency.text,
                             loan.isSettled ? loan.principal.vnd : "còn \(loan.outstanding.vnd) trên \(loan.principal.vnd)",
                             paidText].joined(separator: ", "))
        .accessibilityHint("Xem khoản vay")
    }

    /// The deadline's day, the relationship, and the monthly interest when there is one.
    private var subtitle: String {
        let relationship = loan.contactID.flatMap { store.contact(id: $0) }
            .map { store.relationship(id: $0.relationshipID).name }
        let due = loan.isSettled ? nil : loan.dueDate.map { "Hạn \($0.dayMonth)" }
        let interest = loan.monthlyInterestRate > 0 && !loan.isSettled ? "Lãi \(loan.monthlyInterest.vndCompact)" : nil
        let parts = [due, interest].compactMap { $0 }
        return parts.isEmpty ? (relationship ?? loan.direction.title) : parts.joined(separator: " · ")
    }

    private var paidText: String { loan.paidText }

    /// The bar takes the badge's colour when the deadline is close, else the side's; the same on
    /// the card and the loan's sheet.
    static func progressColor(for loan: Loan, urgency: LoanUrgency) -> Color {
        switch urgency {
        case .overdue: Palette.red
        case .soon: Palette.warning
        case .settled: Palette.green
        default: loan.direction == .borrowed ? Palette.red : Palette.primary
        }
    }
}
