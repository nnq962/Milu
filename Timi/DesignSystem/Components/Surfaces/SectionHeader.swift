import SwiftUI

/// A heading: over a card on main screens (`OutsideHeaderSection`, 2026-11-07) or inside its top
/// (`HeaderCard`), over a group of rows in sheets and forms. Two weights (user choice 2026-10-28):
/// - `.section` names a part of a main screen ("Hũ tiết kiệm", "Hôm nay, 28/10"): 17 `title`
///   ink, so it stands out among the cards on the page.
/// - `.group` names a group of rows inside a sheet or form ("THÔNG BÁO" in Settings): small grey
///   capitals (`overline`); the sheet title above is already the strong one.
struct SectionHeader<Trailing: View>: View {
    enum Style { case section, group }

    let title: String
    var style: Style = .section
    @ViewBuilder var trailing: Trailing

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // On one baseline with what is beside it ("Cho vay" 17, "Còn 65tr" 13); stacked at the
        // accessibility sizes, where the two crowded one line (strict review 2026-10-31).
        AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            heading
                .accessibilityAddTraits(.isHeader)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            trailing
        }
        // Starts where the rows inside the card start: at the icon, or at the text when the
        // rows have none (Claude app style, user request 2026-10-28). Every page, cards or none
        // (user choice 2026-10-31: Tổng quan and Tài khoản sat at the page margin).
        .padding(.horizontal, RowMetrics.horizontal)
    }

    @ViewBuilder
    private var heading: some View {
        switch style {
        case .section:
            Text(title)
                .textRole(.title)
        case .group:
            // Small capitals again (user request 2026-10-30): in sentence case the heading read
            // just like the caption under a group.
            Text(title)
                .textRole(.overline)
                .foregroundStyle(Palette.secondaryLabel)
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, style: Style = .section) {
        self.init(title: title, style: style) { EmptyView() }
    }
}
