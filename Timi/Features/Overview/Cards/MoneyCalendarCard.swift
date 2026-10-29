import SwiftUI

/// "Lịch thu chi": a month grid with each day's income and spending, shaded by how busy it was.
/// Tapping a day hands its date to `onSelectDay`.
struct MoneyCalendarCard: View {
    let onSelectDay: (Date) -> Void

    @Environment(FinanceStore.self) private var store
    @State private var displayedMonth = Date.now
    @ScaledMetric(relativeTo: .caption2) private var dayHeight = 52

    var body: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let dayCount = calendar.range(of: .day, in: .month, for: start)!.count
        let offset = (calendar.component(.weekday, from: start) + 5) % 7
        let cellCount = ((offset + dayCount + 6) / 7) * 7
        let transactionsByDay = Dictionary(grouping: store.monthlyTransactions(for: start)) {
            calendar.startOfDay(for: $0.date)
        }
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Lịch thu chi")
                    .textRole(.title)
                    .frame(minHeight: 24)
                Spacer(minLength: 4)
                monthMenu
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 4), count: 7), spacing: 4) {
                ForEach(["T2", "T3", "T4", "T5", "T6", "T7", "CN"], id: \.self) { title in
                    Text(title)
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 15)
                        .padding(.vertical, 4)
                        .accessibilityHidden(true)
                }
                ForEach(0..<cellCount, id: \.self) { index in
                    if index < offset || index >= offset + dayCount {
                        Color.clear.frame(height: dayHeight).accessibilityHidden(true)
                    } else {
                        let date = calendar.date(byAdding: .day, value: index - offset, to: start)!
                        let items = transactionsByDay[calendar.startOfDay(for: date)] ?? []
                        let income = items.reportable(excluding: store.lockedAccountIDs).filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
                        let expense = items.reportable(excluding: store.lockedAccountIDs).filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
                        day(date, income: income, expense: expense)
                    }
                }
            }
        }
        .overviewCard()
    }

    private var monthMenu: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: displayedMonth)
        let month = calendar.component(.month, from: displayedMonth)
        let isCurrentYear = year == calendar.component(.year, from: .now)
        return Menu {
            Button("Tháng trước") { changeMonth(-1) }
            Button("Tháng hiện tại") { displayedMonth = .now }
            Button("Tháng sau") { changeMonth(1) }
            Divider()
            ForEach((year - 1)...(year + 1), id: \.self) { targetYear in
                Menu(String(targetYear)) {
                    ForEach(1...12, id: \.self) { targetMonth in
                        Button("Tháng \(targetMonth)") {
                            if let date = calendar.date(from: DateComponents(year: targetYear, month: targetMonth, day: 1)) {
                                displayedMonth = date
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                TimiIcon("hugeicons-calendar-03", size: 14)
                Text(isCurrentYear ? "Tháng \(month)" : "T\(month)/\(year.formatted(.number.grouping(.never)))")
                    .textRole(.captionStrong)
                    .monospacedDigit()
                TimiIcon("hugeicons-arrow-down-01", size: 12)
                    .foregroundStyle(Palette.secondaryText)
            }
            .foregroundStyle(Palette.ink)
        }
        .menuIndicator(.hidden)
        .nativeGlassButton(tint: Palette.muted)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .accessibilityLabel("Chọn tháng, tháng \(month) năm \(String(year))")
    }

    private func day(_ date: Date, income: Double, expense: Double) -> some View {
        let calendar = Calendar.current
        let today = calendar.isDateInToday(date)
        let total = income + expense
        // Three neutral activity levels from the mockup; today overrides the heat map.
        let fill = today ? Palette.lime
            : total >= 3_000_000 ? Palette.secondary.opacity(0.25)
            : total >= 1_000_000 ? Palette.muted
            : Palette.muted.opacity(0.4)
        return Button { onSelectDay(date) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .textRole(.captionStrong)
                    .foregroundStyle(today ? Palette.ink : Palette.secondaryText)
                    .frame(minHeight: 16.5, alignment: .topLeading)
                VStack(alignment: .leading, spacing: 0) {
                    if income > 0 {
                        amount("+\(income.vndCompact)", color: Palette.ink)
                    }
                    if expense > 0 {
                        amount("-\(expense.vndCompact)", color: Palette.red)
                    }
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: dayHeight, alignment: .topLeading)
            .background(fill, in: RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
        }
        // Calendar cells are flat data tiles in the design; only the month control uses glass.
        .buttonStyle(.card)
        .accessibilityLabel("\(today ? "Hôm nay, " : "")\(date.formatted(.dateTime.weekday(.wide).day().month().year().locale(.vietnam))), thu \(income.vnd), chi \(expense.vnd)")
        .accessibilityHint("Xem giao dịch trong ngày")
    }

    private func amount(_ text: String, color: Color) -> some View {
        Text(text)
            .textRole(.footnote)
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1).minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: 11.25, alignment: .leading)
    }

    private func changeMonth(_ delta: Int) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        displayedMonth = calendar.date(byAdding: .month, value: delta, to: start) ?? start
    }
}
