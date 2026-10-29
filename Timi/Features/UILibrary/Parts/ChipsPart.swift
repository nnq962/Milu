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
                        ForEach(BadgeTone.allCases.suffix(3)) { StatusBadge(text: $0.name, tone: $0) }
                    }
                    StatusBadge(text: "2 sắp đến hạn", showsDot: false)
                }
            }
        }
    }
}
