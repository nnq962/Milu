import SwiftUI

/// "Hũ đã hoàn thành": every closed goal (spent or taken out after reaching its target), the most
/// recent first, as rows: ring, name, how and when it ended, and the target it met. Tapping one
/// opens it (read-only history; the pencil offers "Mở lại hũ" and "Xoá hũ").
struct CompletedGoalsView: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let goals = store.completedGoals
        // Laid out as "Tài khoản đã lưu trữ": one scroll view, the same margins, empty or not.
        ScrollView {
            if goals.isEmpty {
                // Reopening the last goal empties this list while the screen is open.
                EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa có hũ nào hoàn thành",
                               message: "Hũ đã đủ mục tiêu sẽ hiện ở đây.")
            } else {
                CompletedGoalsList()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Hũ đã hoàn thành")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
        }
    }
}

/// The closed goals as rows on one card, each opening its goal over the list; with a `title`,
/// under that heading (the "Lưu trữ & hoàn thành" sheet holds this and the archived accounts).
struct CompletedGoalsList: View {
    var title: String? = nil

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let goals = store.completedGoals
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let title {
                Text(title)
                    .textRole(.title)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    // Slides over the list inside the same sheet, ‹ back to it (user choice
                    // 2026-11-01: one sheet, not one on top of another).
                    NavigationLink { GoalDetailView(goalID: goal.id) } label: {
                        CompletedGoalRow(goal: goal, subtitle: completedText(goal))
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                }
            }
            .listCard()
        }
    }

    /// "Đã dùng: Mua xe · 29/10": how it ended and the day it closed.
    private func completedText(_ goal: SavingsGoal) -> String {
        let day = goal.closedAt?.shortDay
        return [goal.closingNote.isEmpty ? "Đã hoàn thành" : goal.closingNote, day]
            .compactMap { $0 }.joined(separator: " · ")
    }
}

/// A closed goal drawn as a goal on the tab (`GoalRow`), not as a transaction (re-review
/// 2026-10-31: a 24 glyph here, a 32 ring there): its full ring in the logo column, the name and
/// how it ended, the target it met, ›.
private struct CompletedGoalRow: View {
    let goal: SavingsGoal
    let subtitle: String

    var body: some View {
        ListRow(title: goal.name, subtitle: subtitle) {
            // Its Fluent Flat picture, 32, as the wallets beside it (user request 2026-11-05: the
            // full ring read as a line icon).
            GoalPictureMark(goal: goal)
        } trailing: {
            ListRowAmount(amount: goal.target)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, subtitle, "mục tiêu \(goal.target.vnd)"].joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }
}

/// The row at the foot of Tài khoản, with closed goals only: the list in a sheet, as a goal opens (user choice 2026-11-01).
struct CompletedGoalsSheet: View {
    var body: some View {
        NavigationStack { CompletedGoalsView() }
            .timiSheetStyle()
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
