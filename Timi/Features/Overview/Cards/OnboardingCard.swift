import SwiftUI

/// "Làm quen với Timi": four first steps, ticked from what is really in the app, as one slim row
/// on a warm block (user request 2026-10-30: fewer words, no mint): a ring with how many are done,
/// the next step not done yet, and +5 lượt AI. Tapping it starts that step: add an account, a
/// transaction or a loan, or open Trợ lý AI. It goes away once all four are done.
struct OnboardingCard: View {
    let onAskAI: () -> Void

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    @State private var step: Step?
    /// The ring grows with the "3/4" inside it, which spilled out of a fixed 44 at large sizes (HIG
    /// review 2026-10-30).
    @ScaledMetric(relativeTo: .caption2) private var ringSize: CGFloat = 44
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The steps done, by name; each pays its +5 lượt AI once (`AIQuota.claim`).
    static func completedSteps(_ store: FinanceStore, askedAI: Bool) -> [String] {
        [("account", !store.accounts.isEmpty), ("transaction", !store.transactions.isEmpty),
         ("loan", !store.loans.isEmpty), ("askAI", askedAI)].filter(\.1).map(\.0)
    }

    private enum Step: String, Identifiable {
        case account, transaction, loan
        var id: Self { self }
    }

    var body: some View {
        let steps: [(title: String, done: Bool, start: () -> Void)] = [
            // "tài khoản": it opens the bank account form (re-review 2026-10-31: said "ví").
            ("Thêm tài khoản đầu tiên", !store.accounts.isEmpty, { step = .account }),
            ("Ghi một khoản thu chi", !store.transactions.isEmpty, { step = .transaction }),
            ("Ghi một khoản cho vay", !store.loans.isEmpty, { step = .loan }),
            ("Hỏi AI một câu hỏi", hasAskedAI, onAskAI),
        ]
        let completed = steps.filter(\.done).count
        if let next = steps.first(where: { !$0.done }) {
            let shape = RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
            Button(action: next.start) {
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
                // A white card, as every card of Tổng quan (HIG pass 2026-10-31).
                .card()
                .contentShape(shape)
            }
            .buttonStyle(.card)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Làm quen với Timi, xong \(completed) trên \(steps.count) bước")
            .accessibilityHint("Bước tiếp theo: \(next.title), thêm 5 lượt AI")
            .sheet(item: $step) { step in
                switch step {
                case .account: AddAccountView(type: .bank)
                case .transaction: AddTransactionView()
                case .loan: LoanEditorView(loan: nil)
                }
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
            StatusBadge(title: "+5 AI", tone: .pro, showsDot: false)
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
