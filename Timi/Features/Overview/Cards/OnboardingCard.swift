import SwiftUI

/// "Làm quen với Timi": four first steps, ticked from what is already in the store.
struct OnboardingCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let hasAccount = !store.accounts.isEmpty
        let hasTransaction = !store.transactions.isEmpty
        let hasLoan = !store.loans.isEmpty
        let completed = [hasAccount, hasTransaction, hasLoan].filter { $0 }.count
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
            VStack(spacing: 8) {
                row("Thêm ví đầu tiên", completed: hasAccount)
                row("Ghi một khoản thu chi", completed: hasTransaction)
                row("Ghi một khoản cho vay", completed: hasLoan)
                row("Hỏi AI một câu hỏi", completed: false)
            }
            .accessibilityElement(children: .contain)
        }
        .overviewCard()
    }

    private func row(_ title: String, completed: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                if completed {
                    Circle().fill(Palette.ink)
                    TimiIcon("hugeicons-checkmark-circle-02", size: 12).foregroundStyle(.white)
                } else {
                    Circle().strokeBorder(Palette.border, lineWidth: 2)
                }
            }
            .frame(width: 20, height: 20)
            Text(title)
                .textRole(completed ? .caption : .captionStrong)
                .foregroundStyle(completed ? Palette.secondaryText : Palette.ink)
            Spacer(minLength: 4)
            Text("+5")
                .textRole(.footnote)
                .foregroundStyle(completed ? Palette.secondaryText : Palette.ink)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(completed ? Palette.fill1 : Palette.fill2, in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), +5")
        .accessibilityValue(completed ? "Đã hoàn thành" : "Chưa hoàn thành")
    }
}
