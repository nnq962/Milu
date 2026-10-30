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
            ("Thêm ví đầu tiên", !store.accounts.isEmpty, { step = .account }),
            ("Ghi một khoản thu chi", !store.transactions.isEmpty, { step = .transaction }),
            ("Ghi một khoản cho vay", !store.loans.isEmpty, { step = .loan }),
            ("Hỏi AI một câu hỏi", hasAskedAI, onAskAI),
        ]
        let completed = steps.filter(\.done).count
        if let next = steps.first(where: { !$0.done }) {
            let shape = RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
            Button(action: next.start) {
                HStack(spacing: Spacing.m) {
                    progressRing(completed: completed, total: steps.count)
                    VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                        Text("Làm quen với Timi")
                            .textRole(.label)
                            .foregroundStyle(Palette.ink)
                        Text(next.title)
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer(minLength: Spacing.s)
                    Text("+5 AI")
                        .textRole(.footnote)
                        .foregroundStyle(Palette.onLime)
                        .padding(.horizontal, Spacing.s).padding(.vertical, 3)
                        .background(Palette.lime, in: Capsule())
                    TimiIcon("hugeicons-arrow-right-01", size: 14)
                        .foregroundStyle(Palette.secondary)
                }
                .padding(Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.muted, in: shape)
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

    /// How many steps are done, "3/4" inside a moss ring.
    private func progressRing(completed: Int, total: Int) -> some View {
        ZStack {
            Circle().stroke(Palette.primary.opacity(0.15), lineWidth: 4)
            Circle().trim(from: 0, to: Double(completed) / Double(total))
                .stroke(Palette.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(completed)/\(total)")
                .textRole(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.primary)
        }
        .frame(width: 44, height: 44)
    }
}
