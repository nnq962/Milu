import SwiftUI

/// "Cần chú ý": payments coming up, soonest first, as a plain section on the page, no card (user
/// request 2026-10-30: fewer cards). Kept light: the due date as a small leaf, the name and how
/// many days are left, the amount in short form; air between rows rather than hairlines.
struct AttentionCard: View {
    @Environment(FinanceStore.self) private var store
    /// The date leaf grows with the text in it, which a fixed 44 cut to "T…" at large sizes (HIG
    /// review 2026-10-30).
    @ScaledMetric(relativeTo: .body) private var leafSize: CGFloat = 44

    var body: some View {
        let reminders = store.paymentReminders.sorted { $0.dueDate < $1.dueDate }
        // The shared heading, `headerGap` above the rows (strict review 2026-10-31).
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: "Cần chú ý")
            if reminders.isEmpty {
                // One short line under the heading, starting where it starts.
                Text("Khoản sắp đến hạn sẽ hiện ở đây.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .padding(.horizontal, RowMetrics.horizontal)
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
                    .textRole(.body)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label)
                Text("Th\(calendar.component(.month, from: reminder.dueDate))")
                    .textRole(.footnote)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .frame(minWidth: leafSize, minHeight: leafSize)
            .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(reminder.title)
                    .textRole(.body)
                    .lineLimit(2)
                Text(reminder.dueDate.dueCountdown)
                    .textRole(.caption)
                    // Red once past due, brown within three days.
                    .foregroundStyle(days < 0 ? Palette.negative : days <= 3 ? Palette.warningLabel : Palette.secondaryLabel)
            }
            Spacer(minLength: Spacing.s)
            MoneyText(amount: reminder.amount, tone: reminder.isIncome ? .signedIncome : .signedExpense)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}
