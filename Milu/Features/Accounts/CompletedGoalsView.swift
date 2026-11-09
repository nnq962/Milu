import SwiftUI

/// "Hũ đã hoàn thành": every closed goal (spent or taken out after reaching its target), the most
/// recent first, as rows: its picture, name, how and when it ended, and the target it met. Tapping one
/// opens it (read-only history; the pencil offers "Mở lại hũ" and "Xoá hũ").
struct CompletedGoalsView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let goals = store.completedGoals
        // Laid out as "Tài khoản đã lưu trữ": one scroll view, the same margins, empty or not.
        SheetPage(title: "Hũ đã hoàn thành", showsClose: true, canEdit: false, onEdit: {}) {
            if goals.isEmpty {
                // Reopening the last goal empties this list while the screen is open.
                EmptyStateCard(title: "Chưa có hũ nào hoàn thành",
                               message: "Hũ đã đủ mục tiêu sẽ hiện ở đây.",
                               picture: IconCatalog.emojiName("🏆"))
            } else {
                CompletedGoalsList()
            }
        }
        // Gone with its last item, as "Lưu trữ & hoàn thành" (review 2026-11-07): the row that
        // opened it has left the page.
        .onChange(of: store.completedGoals.isEmpty) { _, isEmpty in if isEmpty { dismiss() } }
    }
}

/// The closed goals as rows on one card, each opening its goal over the list; with a `title`,
/// under that heading (the "Lưu trữ & hoàn thành" sheet holds this and the archived accounts).
struct CompletedGoalsList: View {
    var title: String? = nil

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let goals = store.completedGoals
        // At the card's edge, as every heading over its card (`OutsideHeaderSection`, review
        // 2026-11-07).
        if let title {
            OutsideHeaderSection(title: title) { list(goals) }
        } else {
            list(goals)
        }
    }

    private func list(_ goals: [SavingsGoal]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                // Slides over the list inside the same sheet, ‹ back to it (user choice
                // 2026-11-01: one sheet, not one on top of another).
                NavigationLink { GoalDetailView(goalID: goal.id) } label: {
                    CompletedGoalRow(goal: goal, subtitle: completedText(goal))
                }
                .buttonStyle(.row)
                .overlay(alignment: .top) { if index > 0 { LedgerDivider() } }
            }
        }
        .cardSurface(radius: CardCorners.card)
    }

    /// "Đã dùng: Mua xe · 29/10": how it ended and the day it closed.
    private func completedText(_ goal: SavingsGoal) -> String {
        let day = goal.closedAt?.shortDay
        return [goal.closingNote.isEmpty ? "Đã hoàn thành" : goal.closingNote, day]
            .compactMap { $0 }.joined(separator: " · ")
    }
}

/// A closed goal as a row of Sổ ví (`LedgerRow`), beside the archived wallets: its picture, the
/// name over how it ended, the target it met, ›.
private struct CompletedGoalRow: View {
    let goal: SavingsGoal
    let subtitle: String

    var body: some View {
        LedgerRow(title: goal.name, subtitle: subtitle, figure: goal.target.vnd,
                  spoken: [goal.name, FormDateRow.spokenDays(in: subtitle), "mục tiêu \(MoneyText.spoken(goal.target))"].joined(separator: ", "),
                  hint: "Xem hũ") {
            // Its Fluent Flat picture, 32, as the wallets beside it (user request 2026-11-05).
            GoalPictureMark(goal: goal)
        }
    }
}

/// The row at the foot of Tài khoản, with closed goals only: the list in a sheet, as a goal opens (user choice 2026-11-01).
struct CompletedGoalsSheet: View {
    var body: some View {
        NavigationStack { CompletedGoalsView() }
            // Half height first, as "Lưu trữ & hoàn thành" opens (review 2026-11-06).
            .miluSheetStyle([.medium, .large])
    }
}

/// A goal's picture in a list's logo column: 32, growing with the text no further than 1.6 times.
private struct GoalPictureMark: View {
    let goal: SavingsGoal

    @ScaledMetric(relativeTo: .body) private var scaled = RowMetrics.listLogo

    var body: some View {
        let size = RowMetrics.capped(scaled, base: RowMetrics.listLogo)
        Image(GoalArtwork.name(for: goal.icon))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
