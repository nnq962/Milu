import SwiftUI

/// "Làm quen với Timi": four first steps, ticked from what is really in the app. Each step not done
/// yet is a row that starts it (user request 2026-10-29): add an account, a transaction or a loan,
/// or go to Trợ lý AI. The card goes away once all four are done.
struct OnboardingCard: View {
    @Binding var selectedTab: AppTab

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
        let hasAccount = !store.accounts.isEmpty
        let hasTransaction = !store.transactions.isEmpty
        let hasLoan = !store.loans.isEmpty
        let completed = [hasAccount, hasTransaction, hasLoan, hasAskedAI].filter { $0 }.count
        if completed < 4 {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Làm quen với Timi")
                            .textRole(.title)
                        Text("Hoàn thành để nhận thêm lượt AI")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    Spacer()
                    StatusBadge(text: "\(completed)/4", showsDot: false)
                }
                ProgressBar(value: Double(completed) / 4)
                    .padding(.top, 4)
                VStack(spacing: 0) {
                    row("Thêm ví đầu tiên", completed: hasAccount) { step = .account }
                    row("Ghi một khoản thu chi", completed: hasTransaction) { step = .transaction }
                    row("Ghi một khoản cho vay", completed: hasLoan) { step = .loan }
                    row("Hỏi AI một câu hỏi", completed: hasAskedAI) { selectedTab = .assistant }
                }
                .accessibilityElement(children: .contain)
            }
            .overviewCard()
            .sheet(item: $step) { step in
                switch step {
                case .account: AddAccountView(type: .bank)
                case .transaction: AddTransactionView()
                case .loan: LoanEditorView(loan: nil)
                }
            }
        }
    }

    /// A step: ticked and greyed when done; otherwise a row with a chevron that starts it.
    private func row(_ title: String, completed: Bool, action: @escaping () -> Void) -> some View {
        // Not `disabled`: that would grey the black tick too.
        Button { if !completed { action() } } label: {
            HStack(spacing: 10) {
                ZStack {
                    if completed {
                        Circle().fill(Palette.primary)
                        TimiIcon("hugeicons-checkmark-circle-02", size: 12).foregroundStyle(Palette.onPrimary)
                    } else {
                        Circle().strokeBorder(Palette.border, lineWidth: 2)
                    }
                }
                .frame(width: 20, height: 20)
                Text(title)
                    .textRole(completed ? .caption : .captionStrong)
                    .foregroundStyle(completed ? Palette.secondaryText : Palette.ink)
                    .strikethrough(completed, color: Palette.secondaryText)
                Spacer(minLength: 4)
                Text("+5")
                    .textRole(.footnote)
                    .foregroundStyle(completed ? Palette.secondaryText : Palette.ink)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(completed ? Palette.fill1 : Palette.fill2, in: Capsule())
                if !completed {
                    TimiIcon("hugeicons-arrow-right-01", size: 14)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), +5")
        .accessibilityValue(completed ? "Đã hoàn thành" : "Chưa hoàn thành")
        .accessibilityAddTraits(completed ? [] : .isButton)
    }
}
