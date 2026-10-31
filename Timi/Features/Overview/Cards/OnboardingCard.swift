import SwiftUI

/// "Làm quen với Timi": four first steps, ticked from what is really in the app, as one slim row
/// on a warm block (user request 2026-10-30: fewer words, no mint): a ring with how many are done,
/// the next step not done yet, and +5 lượt AI. Tapping it opens the steps in a sheet, empty for
/// now (user request 2026-10-31). It goes away once all four are done.
struct OnboardingCard: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    @State private var isShowingSteps = false
    /// The ring grows with the "3/4" inside it, which spilled out of a fixed 44 at large sizes (HIG
    /// review 2026-10-30).
    @ScaledMetric(relativeTo: .caption2) private var ringSize = RowMetrics.featureIcon
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        if let next = steps.first(where: { !$0.done }) {
            let shape = RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
            Button { isShowingSteps = true } label: {
                Group {
                    // At the accessibility sizes the words go under the ring and the reward, which
                    // squeezed them into a narrow column in one row (HIG review 2026-10-30).
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            HStack(spacing: Spacing.m) {
                                progressRing(completed: completed, total: steps.count)
                                Spacer(minLength: Spacing.s)
                                reward
                            }
                            words(next.title)
                        }
                    } else {
                        HStack(spacing: Spacing.m) {
                            progressRing(completed: completed, total: steps.count)
                            words(next.title)
                            Spacer(minLength: Spacing.s)
                            reward
                        }
                    }
                }
                // A card, as every card of Tổng quan (HIG pass 2026-10-31).
                .card()
                .contentShape(shape)
            }
            .buttonStyle(.card)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Làm quen với Timi, xong \(completed) trên \(steps.count) bước")
            .accessibilityHint("Bước tiếp theo: \(next.title), thêm 5 lượt AI")
            .sheet(isPresented: $isShowingSteps) {
                // Empty for now: the steps come later (user request 2026-10-31).
                SheetScaffold(title: "Làm quen với Timi") { EmptyView() }
                    .timiSheetStyle([.medium, .large])
            }
        }
    }

    private func words(_ nextStep: String) -> some View {
        VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
            Text("Làm quen với Timi")
                .textRole(.body)
                .foregroundStyle(Palette.label)
            Text(nextStep)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .lineLimit(2)
        }
    }

    /// "+5 AI" and the chevron.
    private var reward: some View {
        HStack(spacing: Spacing.m) {
            // The shared badge and ›, not a hand-made pill (strict review 2026-10-31).
            // Neutral, so the reward does not outweigh the title (review 2026-10-31: the black pill
            // was the heaviest thing on the card).
            StatusBadge(title: "+5 AI", tone: .neutral, showsDot: false)
            RowChevron()
        }
    }

    /// How many steps are done, "3/4" inside a ring in the primary colour.
    private func progressRing(completed: Int, total: Int) -> some View {
        ZStack {
            ProgressRing(progress: Double(completed) / Double(total))
            Text("\(completed)/\(total)")
                .textRole(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.primary)
        }
        .frame(width: ringSize, height: ringSize)
    }
}
