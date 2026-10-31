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

/// "Kiểu trang Tài khoản" in Cài đặt → Nhà phát triển: labelled like its neighbours, the switch
/// under the title, so the group's rows all start at the icon column (strict review 2026-10-31).
struct AccountsLayoutTrialRow: View {
    @AppStorage(StorageKey.accountsLayout) private var layout = AccountsLayout.both

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            FormRowLabel(title: "Kiểu trang Tài khoản (thử)", icon: "hugeicons-wallet-01")
                .frame(minHeight: RowMetrics.minHeight - 2 * RowMetrics.vertical)
            ScaledSegmentedPicker(title: "Kiểu trang Tài khoản", selection: $layout,
                                  options: AccountsLayout.allCases) { $0.title }
                .labelsHidden()
                .padding(.leading, RowMetrics.dividerInset - RowMetrics.horizontal)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
    }
}
