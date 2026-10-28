import SwiftUI

/// "Cần chú ý": payments coming up, soonest first.
struct AttentionCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let reminders = store.paymentReminders.sorted { $0.dueDate < $1.dueDate }
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cần chú ý")
                    .font(Typography.font(.callout, size: 16, weight: .semibold))
                    .frame(minHeight: 24)
                Spacer(minLength: 8)
                Text("\(reminders.count) sắp đến hạn")
                    .font(Typography.font(.caption, size: 11, weight: .semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Palette.muted, in: Capsule())
            }
            if reminders.isEmpty {
                Text("Chưa có lịch thanh toán sắp tới.")
                    .font(Typography.font(.caption, size: 11))
                    .foregroundStyle(Palette.secondaryText)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                        if index > 0 {
                            Rectangle().fill(Palette.border)
                                .frame(height: 1)
                                .padding(.leading, 52)
                                .padding(.vertical, 12)
                        }
                        row(reminder)
                    }
                }
            }
        }
        .overviewCard()
    }

    private func row(_ reminder: PaymentReminder) -> some View {
        HStack(spacing: 12) {
            SolarIcon(reminder.isIncome ? "solar-user-linear" : "solar-calendar-linear", size: 20)
                .frame(width: 40, height: 40)
                .background(reminder.isIncome ? Palette.secondarySurface : Palette.muted, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(reminder.title)
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .lineLimit(1)
                    .frame(minHeight: 20)
                Text(reminder.dueDescription)
                    .font(Typography.font(.caption, size: 11))
                    .foregroundStyle(Palette.secondaryText)
                    .frame(minHeight: 16.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(reminder.isIncome ? "+" : "-")\(reminder.amount.vnd)")
                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(reminder.isIncome ? Palette.ink : Palette.red)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .combine)
    }
}
