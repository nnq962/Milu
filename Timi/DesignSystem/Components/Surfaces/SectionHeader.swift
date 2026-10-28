import SwiftUI

/// A heading over a card, `Spacing.headerGap` above it. Two weights (user choice 2026-10-28):
/// - `.section` names a part of a main screen ("Hũ tiết kiệm", "Hôm nay, 28/10"): 17 SemiBold
///   ink, so it stands out among the cards on the page.
/// - `.group` names a group of rows inside a sheet or form ("THÔNG BÁO" in Settings): small grey
///   capitals (`overline`); the sheet title above is already the strong one.
struct SectionHeader<Trailing: View>: View {
    enum Style { case section, group }

    let title: String
    var style: Style = .section
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            switch style {
            case .section:
                Text(title)
                    .textRole(.title)
            case .group:
                Text(title)
                    .textRole(.overline)
                    .foregroundStyle(Palette.secondaryText)
            }
            Spacer(minLength: Spacing.s)
            trailing
        }
        // Starts where the rows inside the card start: at the icon, or at the text when the
        // rows have none (Claude app style, user request 2026-10-28).
        .padding(.horizontal, RowMetrics.horizontal)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, style: Style = .section) {
        self.init(title: title, style: style) { EmptyView() }
    }
}
