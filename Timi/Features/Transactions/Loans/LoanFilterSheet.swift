import SwiftUI

/// "Bộ lọc" of the search on "Vay nợ": the kind only, Tất cả / Cho vay / Đi vay (user choice
/// 2026-10-29). Laid out as Thu chi's "Bộ lọc" (re-review 2026-10-31: both open from the same
/// search, so they read the same): native bar with ✕ and ✓, flat chips at the heading's 16. The
/// change is applied on ✓.
struct LoanFilterSheet: View {
    @Binding var kind: LoanFilter

    @Environment(\.dismiss) private var dismiss
    @State private var draft: LoanFilter

    init(kind: Binding<LoanFilter>) {
        _kind = kind
        _draft = State(initialValue: kind.wrappedValue)
    }

    private var kindChips: some View {
        HStack(spacing: Spacing.s) {
            ForEach(LoanFilter.allCases) { option in
                TagChip(title: option.title, isProminent: draft == option) { draft = option }
                    .accessibilityAddTraits(draft == option ? .isSelected : [])
            }
        }
        .padding(.horizontal, RowMetrics.horizontal)
    }

    var body: some View {
        SheetScaffold(title: "Bộ lọc", onConfirm: {
            kind = draft
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: "Loại", style: .group)
                ViewThatFits(in: .horizontal) {
                    kindChips
                    ScrollView(.horizontal) { kindChips }
                        .scrollIndicators(.hidden)
                        .scrollEdgeEffectHidden(true, for: .all)
                }
                .sensoryFeedback(.selection, trigger: draft)
            }
            if draft != .all {
                FormGroup {
                    // Not ✕, which reads as closing the sheet; as Thu chi's filter (strict review 2026-10-31).
                    FormActionRow(title: "Đặt lại bộ lọc", icon: "hugeicons-filter-horizontal") {
                        withAnimation(.smooth(duration: 0.25)) { draft = .all }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.25), value: draft)
        // One heading and a row of chips: half the screen is room enough; larger text can pull it up.
        .timiSheetStyle([.medium, .large])
    }
}
