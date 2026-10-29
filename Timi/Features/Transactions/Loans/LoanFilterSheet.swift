import SwiftUI

/// "Bộ lọc" of the search on "Vay nợ": the kind only, Tất cả / Cho vay / Đi vay (user choice
/// 2026-10-29). As tall as its content; the change is applied on ✓.
struct LoanFilterSheet: View {
    @Binding var kind: LoanFilter

    @Environment(\.dismiss) private var dismiss
    @State private var draft: LoanFilter

    init(kind: Binding<LoanFilter>) {
        _kind = kind
        _draft = State(initialValue: kind.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            SheetHeader(title: "Bộ lọc") {
                kind = draft
                dismiss()
            }
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: "Loại", style: .group)
                ChipRow(options: LoanFilter.kinds, selection: $draft) { $0.title }
            }
            if draft != .all {
                FormGroup {
                    FormActionRow(title: "Đặt lại bộ lọc", icon: "hugeicons-cancel-01") {
                        withAnimation(.smooth(duration: 0.25)) { draft = .all }
                    }
                }
                .transition(.opacity)
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .animation(.smooth(duration: 0.25), value: draft)
        .timiFittedSheet()
    }
}
