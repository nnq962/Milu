import SwiftUI

/// An account in a list, the same on every page that lists accounts (tab Tài khoản, Lưu trữ,
/// Tài sản ròng, Nợ): a `ListRow` with its logo or glyph on a tile in the icon column, the
/// name, the balance in short form, › (strict review 2026-10-31: the same account was drawn
/// three ways; review 2026-10-31: then the row itself was drawn by hand).
struct AccountRow: View {
    let account: Account
    var showsChevron = true
    /// A line under the name ("Đã lưu trữ 3/10").
    var subtitle: String? = nil
    /// The balance in grey: money that no longer counts (an archived account).
    var isMuted = false

    /// How far the lock hangs out past the logo's corner, a third of the badge (re-review
    /// 2026-10-31: named instead of written in place).
    static let lockOverhang: CGFloat = LockBadge.size / 3

    var body: some View {
        ListRow(title: account.name, subtitle: subtitle, showsChevron: showsChevron) {
            RowIcon(name: account.iconName, size: RowMetrics.listLogo, tiled: true)
                .overlay(alignment: .bottomTrailing) {
                    if account.isLocked { LockBadge().offset(x: Self.lockOverhang, y: Self.lockOverhang) }
                }
        } trailing: {
            ListRowAmount(amount: account.balance, tone: account.isLocked || isMuted ? .muted : .balance)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([account.name, account.balance.vnd, account.isLocked ? "đã khoá" : nil, subtitle]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(showsChevron ? "Xem tài khoản" : "")
    }
}
