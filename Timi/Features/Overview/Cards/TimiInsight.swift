import SwiftUI

/// What Timi says at the foot of the net worth card: a few words from the user's own figures, the
/// most pressing first (a loan to collect overdue or due within a week, the month's limit nearly
/// used or passed, nothing recorded yet today from noon, else what took most this month). Young
/// and teasing, as Duolingo's owl nags (user choice 2026-10-31), never mean; short enough for one
/// line beside "Hỏi Timi". Picked by rules while
/// the assistant is a mock; a real model can write it later without the page changing.
struct TimiInsight {
    let text: String

    static func make(store: FinanceStore, monthlyBudget: Double, now: Date) -> TimiInsight {
        let calendar = Calendar.current
        // A loan someone owes, overdue or due within seven days, soonest first.
        let due = store.loans
            .filter { !$0.isSettled && $0.direction == .lent }
            .compactMap { loan in loan.dueDate.map { (loan, $0.daysFromToday) } }
            .filter { $0.1 <= 7 }
            .min { $0.1 < $1.1 }
        if let (loan, days) = due {
            let text = switch days {
            case ..<0: "\(loan.name) trễ hẹn trả nợ rồi nha"
            case 0: "Hôm nay \(loan.name) tới hạn trả, hóng thôi"
            default: "Còn \(days) ngày \(loan.name) tới hạn trả"
            }
            return TimiInsight(text: text)
        }

        let spent = store.total(.expense, inMonthOf: now)
        if monthlyBudget > 0 {
            let progress = BudgetProgress(limit: monthlyBudget, spent: spent)
            if progress.isOver {
                return TimiInsight(text: "Lố hạn mức rồi, ví khóc thầm đó")
            }
            if progress.isNearing {
                return TimiInsight(text: "Hạn mức đi \(progress.ratio.percentText) rồi nha bestie")
            }
        }

        let recordedToday = store.transactions.contains { calendar.isDateInToday($0.date) }
        if !recordedToday, calendar.component(.hour, from: now) >= 12 {
            return TimiInsight(text: "Hôm nay chưa ghi khoản nào luôn á?")
        }

        if spent > 0, let top = store.expensesByCategory(inMonthOf: now).first {
            return TimiInsight(text: "\(top.name) ngốn ví nhiều nhất nha")
        }
        return TimiInsight(text: "Ví im ắng quá, hỏi mình gì đi")
    }
}
