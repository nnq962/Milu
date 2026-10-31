import SwiftUI

/// The head of Tổng quan, scrolling with the page (the user's design, 2026-10-31): today's date in
/// small grey words over a greeting for the time of day, in large type. Q and the bell stay on the
/// bar.
struct GreetingHeader: View {
    let name: String

    var body: some View {
        let now = Date.now
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam)).capitalizedFirstLetter)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
            Text("\(Self.salutation(at: now)), \(name)")
                .textRole(.pageTitle)
                .foregroundStyle(Palette.label)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        // In from the page edge as every heading, in line with the words inside the cards.
        .padding(.horizontal, RowMetrics.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func salutation(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Chào buổi sáng"
        case 12..<18: "Chào buổi chiều"
        default: "Chào buổi tối"
        }
    }
}
