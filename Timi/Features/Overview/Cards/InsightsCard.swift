import SwiftUI

/// "Timi nhận thấy" on Tổng quan: a few things read from the user's own figures, each a row with a
/// 3D picture on a pale tile, a small label, one line in Timi's teasing voice, and the figure with
/// a note beside it (the user's reference 2026-11-02, "What I'm noticing"). Each opens where its
/// figure comes from (user review 2026-11-02: they led nowhere): the group's report, the goal,
/// the month's report. Only what holds is
/// shown, and the card goes away when nothing does. The pictures are Microsoft's Fluent Emoji 3D
/// (MIT, `Fluent3D` in Assets).
struct InsightsCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let insights = Insight.all(store: store, now: .now)
        if !insights.isEmpty {
            HeaderCard(title: "Timi nhận thấy") {
                VStack(spacing: 0) {
                    ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                        link(insight)
                            .overlay(alignment: .top) { if index > 0 { RowDivider(column: .none) } }
                    }
                }
                .listCard()
            }
        }
    }

    @ViewBuilder
    private func link(_ insight: Insight) -> some View {
        switch insight.target {
        case .group(let groupID):
            NavigationLink {
                CategoryReportView(groupID: groupID, period: ReportPeriod(.month, containing: .now))
            } label: { InsightRow(insight: insight) }
            .buttonStyle(.row)
        case .goal(let goalID):
            GoalSheetLink(goalID: goalID) { InsightRow(insight: insight) }
                .buttonStyle(.row)
        case .month:
            NavigationLink {
                ReportView(period: ReportPeriod(.month, containing: .now))
            } label: { InsightRow(insight: insight) }
            .buttonStyle(.row)
        }
    }
}

/// One thing Timi noticed.
struct Insight: Identifiable {
    /// Where tapping it leads.
    enum Target {
        case group(String), goal(SavingsGoal.ID), month
    }

    let id: String
    /// The `Fluent3D` picture, without its "fluent-" prefix.
    let picture: String
    let label: String
    let title: String
    let figure: String
    let note: String?
    let noteColor: Color
    let target: Target
    /// Seven bars, Monday first, when the insight is about days of the week.
    var week: [Double]? = nil

    /// Pictures for the default groups of "Hạng mục"; anything else is the money bag.
    private static let pictures = ["food", "transport", "bills", "housing", "shopping", "entertainment",
                                   "health", "education", "family"]

    static func all(store: FinanceStore, now: Date) -> [Insight] {
        var result: [Insight] = []
        let calendar = Calendar.current

        // What took most this month, and how often, against last month.
        if let top = store.expensesByCategory(inMonthOf: now).first {
            let count = store.expenses(inGroup: top.groupID, in: .month(of: now)).count
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let before = store.expenses(inGroup: top.groupID, in: .month(of: lastMonth)).count
            // Orange only for more times than last month; fewer, or nothing to compare, is a plain count.
            let isMore = before > 0 && count > before
            result.append(Insight(id: "top", picture: pictures.contains(top.groupID) ? top.groupID : "money", label: top.name.uppercased(),
                                  title: "\(top.name) ngốn ví nhiều nhất tháng này",
                                  figure: top.amount.vndCompact,
                                  note: isMore ? "+\(count - before) lần so với tháng trước" : "\(count) lần trong tháng",
                                  noteColor: isMore ? Palette.warningLabel : Palette.secondaryLabel,
                                  target: .group(top.groupID)))
        }

        // Weekends against weekdays over the last four weeks.
        if let start = calendar.date(byAdding: .day, value: -28, to: calendar.startOfDay(for: now)) {
            let spending = store.reportableTransactions(in: DateInterval(start: start, end: now))
                .filter { $0.kind == .expense }
            var week = Array(repeating: 0.0, count: 7)
            for item in spending {
                // Monday 0 … Sunday 6.
                let day = (calendar.component(.weekday, from: item.date) + 5) % 7
                week[day] += item.amount
            }
            let weekday = week[0..<5].reduce(0, +) / 5
            let weekend = week[5...].reduce(0, +) / 2
            if weekday > 0, weekend / weekday >= 1.3 {
                let times = weekend / weekday
                result.append(Insight(id: "weekend", picture: "calendar",
                                      label: "CUỐI TUẦN", title: "Cuối tuần bạn chi mạnh tay hơn hẳn",
                                      figure: "×\(times.formatted(.number.precision(.fractionLength(1)).locale(.vietnam)))",
                                      note: "so với ngày thường", noteColor: Palette.secondaryLabel,
                                      target: .month, week: week))
            }
        }

        // The goal nearest full, while it is not yet.
        if let goal = store.activeGoals.filter({ $0.target > 0 && $0.saved < $0.target })
            .max(by: { $0.saved / $0.target < $1.saved / $1.target }) {
            result.append(Insight(id: "goal", picture: "goal",
                                  // "Hũ tiết kiệm" already says "Hũ": not "Hũ Hũ tiết kiệm".
                                  label: "HŨ TIẾT KIỆM",
                                  title: "\(goal.name.lowercased().hasPrefix("hũ") ? goal.name : "Hũ \(goal.name)") sắp đầy rồi",
                                  figure: (goal.saved / goal.target).percentText,
                                  note: "còn \((goal.target - goal.saved).vndCompact)", noteColor: Palette.income,
                                  target: .goal(goal.id)))
        }
        return result
    }
}

private struct InsightRow: View {
    let insight: Insight

    @ScaledMetric(relativeTo: .body) private var tile: CGFloat = RowMetrics.picture

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image("fluent-\(insight.picture)")
                .resizable()
                .scaledToFit()
                // On nothing: a pale tile behind each picture was one more colour (2026-11-03).
                .frame(width: tile, height: tile)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(insight.label)
                    .textRole(.overline)
                    .foregroundStyle(Palette.secondaryLabel)
                Text(insight.title)
                    .textRole(.body)
                    .foregroundStyle(Palette.label)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    Text(insight.figure)
                        .textRole(.heading)
                        .monospacedDigit()
                        .foregroundStyle(Palette.label)
                    if let note = insight.note {
                        Text(note)
                            .textRole(.captionStrong)
                            .foregroundStyle(insight.noteColor)
                    }
                }
                if let week = insight.week {
                    WeekBars(values: week)
                        .padding(.top, Spacing.xs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            RowChevron()
                .frame(maxHeight: tile)
        }
        .padding(RowMetrics.horizontal)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Seven bars, Monday to Sunday, the weekend in the chart's second shade and the weekdays pale.
private struct WeekBars: View {
    let values: [Double]

    private static let height: CGFloat = 36
    private static let days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    var body: some View {
        let top = max(values.max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            ForEach(values.indices, id: \.self) { index in
                VStack(spacing: Spacing.xxs) {
                    RoundedRectangle(cornerRadius: Spacing.xs, style: .continuous)
                        .fill(index >= 5 ? Palette.chart[1] : Palette.chart[1].opacity(0.22))
                        .frame(height: max(Self.height * values[index] / top, Spacing.xs))
                    Text(Self.days[index])
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
        .frame(height: Self.height + 18, alignment: .bottom)
        .accessibilityHidden(true)
    }
}
