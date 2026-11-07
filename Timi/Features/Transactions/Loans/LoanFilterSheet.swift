import SwiftUI

/// "Bộ lọc" of the search on "Vay nợ": the kind only, Tất cả / Cho vay / Đi vay (user choice
/// 2026-10-29). Laid out as Thu chi's "Bộ lọc" (re-review 2026-10-31: both open from the same
/// search, so they read the same): native bar with ✕ and ✓, the kind a row of "Phạm vi" opening its choices. The
/// change is applied on ✓.
struct LoanFilterSheet: View {
    @Binding var kind: LoanFilter

    @Environment(\.dismiss) private var dismiss
    @State private var draft: LoanFilter

    init(kind: Binding<LoanFilter>) {
        _kind = kind
        _draft = State(initialValue: kind.wrappedValue)
    }

    var body: some View {
        // As tall as its one row: half the screen left a large empty sheet (review 2026-11-07).
        SheetScaffold(title: "Bộ lọc", onConfirm: {
            kind = draft
            dismiss()
        }, fitsContent: true) {
            // One row in a card, as "Loại" in Thu chi's filter (user request 2026-11-07).
            FormGroup(title: "Phạm vi") {
                FormPickerRow(title: "Loại", selection: $draft, options: LoanFilter.allCases) { $0.title }
            }
            if draft != .all {
                FormGroup {
                    // Not ✕, which reads as closing the sheet; as Thu chi's filter (strict review 2026-10-31).
                    FormActionRow(title: "Đặt lại bộ lọc", icon: "hugeicons-filter-horizontal") {
                        withAnimation(Motion.gentle(.smooth(duration: 0.25))) { draft = .all }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(Motion.gentle(.smooth(duration: 0.25)), value: draft)
    }
}
