import SwiftUI

/// Day totals beside each date heading: both sides in full, a single side compact.
struct DayTotals: View {
    let items: [FinanceTransaction]
    /// Loan payments whose interest counts as income (a loan given) or spending (one taken).
    var interestOf: [LoanPayment] = []
    /// The account whose own history this is: counted even when locked, since its rows show
    /// their amounts (review 2026-11-07: a locked account's days had no totals).
    var viewedAccount: Account.ID? = nil

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let locked = store.lockedAccountIDs.filter { $0 != viewedAccount }
        let interest = interestOf.compactMap { payment in
            store.loan(id: payment.loanID).map { payment.interestTransaction(lent: $0.direction == .lent) }
        }
        let counted = (items + interest).reportable(excluding: locked)
        let income = counted.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = counted.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        // In full where they fit, as every figure (`MoneyText` shortens both when they do not).
        HStack(spacing: Spacing.m) {
            if income > 0 {
                MoneyText(amount: income, size: .caption, tone: .signedIncome)
            }
            if expense > 0 {
                // Money out in ink, as on its rows ("B+" 2026-11-03; red before, user rule 2026-10-30).
                MoneyText(amount: expense, size: .caption, tone: .outflow)
            }
        }
        // A row added or deleted: the figures roll to the new sum with the row, not jump.
        .contentTransition(.numericText())
        // In words: "Thu 1.200.000 đ, chi 55.000 đ", not "trừ 55k".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([income > 0 ? "Thu \(MoneyText.spoken(income))" : nil,
                             expense > 0 ? "chi \(MoneyText.spoken(expense))" : nil]
            .compactMap { $0 }.joined(separator: ", ").capitalizedFirstLetter)
        .accessibilityHidden(income == 0 && expense == 0)
    }
}

/// Transactions and transfers grouped by day, newest first: the day's title and totals over a
/// card of rows, a card per day (user choice 2026-10-30, back from one long block that read as a
/// wall of rows); tapping one hands it back. Shared by "Giao dịch", its search, and the
/// histories of an account and a goal in their sheets.
struct ActivityDayList: View {
    let groups: [(day: Date, items: [AccountDetailView.Activity])]
    /// The account whose history this is (its page): transfers read "Chuyển đến …" / "Nhận từ …".
    var viewedAccount: Account.ID? = nil
    /// The day's title and totals on the page over its card, at the card's edge, as the sections
    /// of Tài khoản (Giao dịch, user request 2026-11-07); otherwise inside the card's top.
    var headingOutside = false
    /// A goal's history (its sheet): rows read from the goal's side ("Nạp tiền" · "Từ …").
    var isGoal = false
    /// Off for a closed goal, whose deposits can no longer change.
    var isEditable = true
    let onOpen: (AccountDetailView.Activity) -> Void

    static func byDay(_ items: [AccountDetailView.Activity]) -> [(day: Date, items: [AccountDetailView.Activity])] {
        let groups = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in (day, groups[day] ?? []) }
    }

    var body: some View {
        ForEach(groups, id: \.day) { group in
            Group {
                if headingOutside {
                    OutsideHeaderSection(title: group.day.transactionDayTitle) { dayTotals(group) } content: {
                        rows(group).listCard()
                    }
                } else {
                    HeaderCard(title: group.day.transactionDayTitle) {
                        dayTotals(group)
                    } content: {
                        rows(group).listCard()
                    }
                }
            }
            .transition(.unfold)
        }
    }

    private func rows(_ group: (day: Date, items: [AccountDetailView.Activity])) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                ActivityRow(item: item, side: isGoal ? .goal : viewedAccount == nil ? .list : .account,
                            isEditable: isEditable, viewedAccount: viewedAccount, detail: .time, onEdit: onOpen)
                    .separatorAbove(index > 0, order: index) { RowDivider() }
                    .transition(.unfold)
            }
        }
    }

    /// The day's totals beside its heading, over the card or inside its top (`headingOutside`).
    /// A day of one row shows no total: it was the row's own amount again, just below it (review
    /// 2026-10-31).
    /// Counted are its transactions and the interest of its loan payments, as "Đã chi" / "Đã thu"
    /// count them (review 2026-11-07); a transfer, fee and all, is a thing of its own (user
    /// choice 2026-10-29), so it adds nothing. Two of those at least, or the total would only
    /// repeat the one row's amount.
    @ViewBuilder
    private func dayTotals(_ group: (day: Date, items: [AccountDetailView.Activity])) -> some View {
        let transactions = group.items.compactMap { item -> FinanceTransaction? in
            if case .transaction(let transaction) = item { transaction } else { nil }
        }
        let payments = group.items.compactMap { item -> LoanPayment? in
            if case .loanPayment(let payment) = item, payment.interest > 0 { payment } else { nil }
        }
        if transactions.count + payments.count > 1 {
            DayTotals(items: transactions, interestOf: payments, viewedAccount: viewedAccount)
        }
    }
}
