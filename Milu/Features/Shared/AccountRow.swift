import SwiftUI

/// An account in a list on the pages Tổng quan opens (Tài sản ròng's Tài khoản, Nợ); the tab
/// Tài khoản and Lưu trữ draw theirs as `WalletRow` / `LedgerRow`: a `ListRow` with its logo or glyph on a tile in the icon column, the
/// name, the balance in full (shortened only where it does not fit), › (strict review 2026-10-31: the same account was drawn
/// three ways; review 2026-10-31: then the row itself was drawn by hand).
struct AccountRow: View {
    let account: Account
    var showsChevron = true
    /// A line under the name ("Đã lưu trữ 3/10").
    var subtitle: String? = nil
    /// How the balance is coloured; the default is a balance's (red below zero). Nợ lists money
    /// owed as every list of money out does, "−" in ink (`.outflow`).
    var amountTone: MoneyText.Tone? = nil

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
            // A step stronger than the name, as in Wallet: the figure is what the row is for
            // (Tài khoản review 2026-11-03: name and amount read the same).
            ListRowTrailing(note: nil) {
                MoneyText(amount: account.balance, size: .rowStrong,
                          tone: account.isLocked ? .muted : amountTone ?? .balance)
            }
        }
        .accessibilityElement(children: .ignore)
        // Money in words ("trừ 5.000.000 đồng"), not "-5.000.000đ" (review 2026-11-08).
        .accessibilityLabel([account.name,
                             "số dư " + (account.balance < 0 ? "trừ " : "") + MoneyText.spoken(abs(account.balance)),
                             account.isLocked ? "đã khoá" : nil, subtitle.map { FormDateRow.spokenDays(in: $0) }]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(showsChevron ? "Xem ví" : "")
    }
}
