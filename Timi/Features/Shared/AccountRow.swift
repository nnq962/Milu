import SwiftUI

/// An account in a list, the same on every page that lists accounts (tab Tài khoản, Lưu trữ,
/// Tài sản ròng, Nợ): its logo or glyph on a white tile, the name, the balance in short form, ›
/// (strict review 2026-10-31: the same account was drawn three ways). At the accessibility text
/// sizes the balance goes under the name, which one line cut short.
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

    @ScaledMetric(relativeTo: .body) private var iconSize = RowMetrics.listLogo
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Where the hairline between account rows starts: under the names.
    static func dividerInset(iconSize: CGFloat = RowMetrics.listLogo) -> CGFloat {
        RowMetrics.horizontal + iconSize + RowMetrics.gap
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.s))
        HStack(spacing: RowMetrics.gap) {
            RowIcon(name: account.iconName, size: iconSize, tiled: true)
                .overlay(alignment: .bottomTrailing) {
                    if account.isLocked { LockBadge().offset(x: Self.lockOverhang, y: Self.lockOverhang) }
                }
            layout {
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(account.name)
                        .textRole(.body)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    if let subtitle {
                        Text(subtitle)
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(1)
                    }
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                MoneyText(amount: account.balance, tone: account.isLocked || isMuted ? .muted : .negativeRed, compact: true)
                    .fixedSize()
            }
            // Stacked, the words take the row's width so every row starts at the same edge.
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
            if showsChevron { RowChevron() }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([account.name, account.balance.vnd, account.isLocked ? "đã khoá" : nil, subtitle]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(showsChevron ? "Xem tài khoản" : "")
    }
}

/// The hairline between `AccountRow`s, from where the names start.
struct AccountRowDivider: View {
    var body: some View { RowDivider(column: .logo) }
}
