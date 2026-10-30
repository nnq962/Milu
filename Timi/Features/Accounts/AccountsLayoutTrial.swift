import SwiftUI

/// Layouts of Tài khoản to compare in the app (user request 2026-10-30), picked in Cài đặt →
/// Nhà phát triển: the plain list, A (the total in a card with a bar of where the money is),
/// B (goals as tiles scrolling sideways), or both. Both is the default (user choice 2026-10-30).
enum AccountsLayout: String, CaseIterable, Identifiable {
    case list, balanceCard, goalCarousel, both

    var id: Self { self }

    var title: String {
        switch self {
        case .list: "Hiện tại"
        case .balanceCard: "Kiểu A"
        case .goalCarousel: "Kiểu B"
        case .both: "A + B"
        }
    }

    var showsBalanceCard: Bool { self == .balanceCard || self == .both }
    var showsGoalCarousel: Bool { self == .goalCarousel || self == .both }
}

/// "Kiểu trang Tài khoản" in Cài đặt → Nhà phát triển.
struct AccountsLayoutTrialRow: View {
    @AppStorage(StorageKey.accountsLayout) private var layout = AccountsLayout.both

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Kiểu trang Tài khoản (thử)")
                .textRole(.body)
            Picker("Kiểu trang Tài khoản", selection: $layout) {
                ForEach(AccountsLayout.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
    }
}
