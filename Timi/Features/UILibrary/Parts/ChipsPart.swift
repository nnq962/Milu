import SwiftUI

struct ChipsPart: View {
    @State private var filter: TransactionFilter = .all
    @State private var tagOn = true

    var body: some View {
        PartSection(part: .chips) {
            SampleCard(label: "Chip lọc · ChipRow") {
                ChipRow(options: TransactionFilter.allCases, selection: $filter) { $0.title }
            }
            SampleCard(label: "Thẻ lọc · TagChip") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        TagChip(title: "Bộ lọc · 2", icon: "hugeicons-filter-horizontal", isProminent: true) {}
                        if tagOn {
                            TagChip(title: "Chi", action: {}, onRemove: { tagOn = false })
                        } else {
                            TagChip(title: "Chi", isSuggestion: true) { tagOn = true }
                        }
                        TagChip(title: "Tháng này", isSuggestion: true) {}
                    }
                }
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
