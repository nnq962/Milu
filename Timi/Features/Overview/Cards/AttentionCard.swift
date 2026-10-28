import SwiftUI

/// "Cần chú ý": payments coming up, soonest first.
struct AttentionCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let reminders = store.paymentReminders.sorted { $0.dueDate < $1.dueDate }
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Text("Cần chú ý")
                    .textRole(.title)
                Spacer(minLength: Spacing.s)
                StatusBadge(text: "\(reminders.count) sắp đến hạn", tone: reminders.isEmpty ? .neutral : .warning)
            }
            if reminders.isEmpty {
                Text("Chưa có lịch thanh toán sắp tới.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                        ListRow(icon: reminder.isIncome ? "solar-user-linear" : "solar-calendar-linear",
                                title: reminder.title,
                                subtitle: reminder.dueDescription,
                                amount: reminder.amount,
                                amountTone: reminder.isIncome ? .signedIncome : .signedExpense,
                                showsChevron: false)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                // Rows carry their own 16pt margin; line their icons up with the card's 20pt edge.
                .padding(.horizontal, -RowMetrics.horizontal)
            }
        }
        .overviewCard()
    }
}
