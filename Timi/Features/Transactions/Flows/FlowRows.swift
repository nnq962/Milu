import SwiftUI

/// Day totals beside each date heading: both sides in full, a single side compact.
struct DayTotals: View {
    let items: [FinanceTransaction]

    var body: some View {
        let income = items.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        HStack(spacing: 12) {
            if income > 0 && expense > 0 {
                Text("+\(income.formatted(.number.locale(.vietnam)))")
                Text("-\(expense.formatted(.number.locale(.vietnam)))").foregroundStyle(Palette.red)
            } else if income > 0 {
                Text("+\(income.vndCompact)")
            } else {
                Text("-\(expense.vndCompact)").foregroundStyle(Palette.secondaryText)
            }
        }
        .textRole(.captionStrong)
        .monospacedDigit()
    }
}
