import SwiftUI

/// "Cần chú ý": payments coming up, soonest first, as a plain section on the page, no card (user
/// request 2026-10-30: fewer cards). Kept light: the due date as a small leaf, the name and how
/// many days are left, the amount in short form; air between rows rather than hairlines.
struct AttentionCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let reminders = store.paymentReminders.sorted { $0.dueDate < $1.dueDate }
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text("Cần chú ý")
                .textRole(.title)
            if reminders.isEmpty {
                Text("Chưa có lịch thanh toán sắp tới.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
            } else {
                VStack(spacing: Spacing.l) {
                    ForEach(reminders) { reminder in
                        row(reminder)
                    }
                }
            }
        }
    }

    private func row(_ reminder: PaymentReminder) -> some View {
        let calendar = Calendar.current
        let days = reminder.dueDate.daysFromToday
        return HStack(spacing: Spacing.m) {
            // The due date as a small calendar leaf, in place of an icon and "Hạn 2/11".
            VStack(spacing: 0) {
                Text("\(calendar.component(.day, from: reminder.dueDate))")
                    .textRole(.label)
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                Text("Th\(calendar.component(.month, from: reminder.dueDate))")
                    .textRole(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }
            .frame(width: 44, height: 44)
            .background(Palette.muted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(reminder.title)
                    .textRole(.label)
                    .lineLimit(1)
                Text(reminder.dueDate.dueCountdown)
                    .textRole(.caption)
                    // Red once past due, brown within three days.
                    .foregroundStyle(days < 0 ? Palette.red : days <= 3 ? Palette.warningText : Palette.secondaryText)
            }
            Spacer(minLength: Spacing.s)
            Text("\(reminder.isIncome ? "+" : "-")\(reminder.amount.vndCompact)")
                .textRole(.label)
                .monospacedDigit()
                .foregroundStyle(reminder.isIncome ? Palette.income : Palette.red)
        }
        .accessibilityElement(children: .combine)
    }
}
