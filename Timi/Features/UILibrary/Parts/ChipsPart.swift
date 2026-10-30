import SwiftUI

struct ChipsPart: View {
    @State private var filter: TransactionFilter = .all

    var body: some View {
        PartSection(part: .chips) {
            SampleCard(label: "Chip lọc · ChipRow") {
                ChipRow(options: TransactionFilter.allCases, selection: $filter) { $0.title }
            }
            SampleCard(label: "Badge · StatusBadge") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        ForEach(BadgeTone.allCases.prefix(3)) { StatusBadge(text: $0.name, tone: $0) }
                    }
                    HStack(spacing: Spacing.s) {
                        ForEach(BadgeTone.allCases.suffix(2)) { StatusBadge(text: $0.name, tone: $0) }
                        // The same Trung tính tone, without the dot: counts such as "3/4".
                        StatusBadge(text: "3/4", showsDot: false)
                    }
                }
            }
        }
    }
}
