import SwiftUI

/// "Làm quen với Timi": four first steps, ticked from what is really in the app, on a white card
/// (the user's pick "2B", 2026-11-02: no grey). The title and "+5 AI mỗi bước" head it; the steps
/// done fold into one quiet line, "✓ Xong 3/4 bước", and only the next step is drawn, in ink with
/// an empty ring and a chevron (Overview review 2026-11-02: three struck-through rows for one step
/// left, and lime on every tick). Tapping it opens the steps in a sheet, empty for now (user
/// request 2026-10-31). It goes away once all four are done.
struct OnboardingCard: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    @State private var isShowingSteps = false
    /// A step's tick disc; it grows with the words beside it.
    @ScaledMetric(relativeTo: .body) private var tickSize: CGFloat = 20

    /// The steps done, by name; each pays its +5 lượt AI once (`AIQuota.claim`).
    static func completedSteps(_ store: FinanceStore, askedAI: Bool) -> [String] {
        [("account", !store.accounts.isEmpty), ("transaction", !store.transactions.isEmpty),
         ("loan", !store.loans.isEmpty), ("askAI", askedAI)].filter(\.1).map(\.0)
    }

    var body: some View {
        let steps: [(title: String, done: Bool)] = [
            ("Thêm tài khoản đầu tiên", !store.accounts.isEmpty),
            ("Ghi một khoản thu chi", !store.transactions.isEmpty),
            ("Ghi một khoản cho vay", !store.loans.isEmpty),
            ("Hỏi AI một câu hỏi", hasAskedAI),
        ]
        let completed = steps.filter(\.done).count
        if let nextIndex = steps.firstIndex(where: { !$0.done }) {
            let shape = RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
            Button { isShowingSteps = true } label: {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        Text("Làm quen với Timi")
                            .textRole(.title)
                            .foregroundStyle(Palette.label)
                        Spacer(minLength: 0)
                        Text("+5 AI mỗi bước")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                    }
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        if completed > 0 {
                            doneLine(completed: completed, total: steps.count)
                        }
                        nextRow(steps[nextIndex].title)
                    }
                }
                .card()
                .contentShape(shape)
            }
            .buttonStyle(.card)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Làm quen với Timi, xong \(completed) trên \(steps.count) bước")
            .accessibilityHint("Bước tiếp theo: \(steps[nextIndex].title), thêm 5 lượt AI")
            .sheet(isPresented: $isShowingSteps) {
                // Empty for now: the steps come later (user request 2026-10-31).
                SheetScaffold(title: "Làm quen với Timi") { EmptyView() }
                    .timiSheetStyle([.medium, .large])
            }
        }
    }

    /// The steps done, as one line: a tick in the faint colour and "Xong 3/4 bước".
    private func doneLine(completed: Int, total: Int) -> some View {
        HStack(spacing: Spacing.m) {
            TimiIcon("hugeicons-tick-02", size: RowMetrics.inlineGlyph)
                .foregroundStyle(Palette.secondaryLabel)
                .frame(width: tickSize, height: tickSize)
            Text("Xong \(completed)/\(total) bước")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
        }
    }

    /// The next step: an empty ring in the secondary colour (over 3:1 on the card, as a graphic
    /// must be; lime was 1.2:1, the faint colour 2.4:1), its words in ink and the chevron.
    private func nextRow(_ title: String) -> some View {
        HStack(spacing: Spacing.m) {
            Circle()
                .strokeBorder(Palette.secondaryLabel, lineWidth: 1.5)
                .frame(width: tickSize, height: tickSize)
            Text(title)
                .textRole(.bodyStrong)
                .foregroundStyle(Palette.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            RowChevron()
        }
    }
}
