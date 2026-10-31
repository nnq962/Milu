import SwiftUI

/// Section headings as the app draws them: `.section` on a main page, `.group` in a form or sheet,
/// and a control on the heading's row in plain moss words (`HeaderCapsuleLabel`).
struct HeadingsPart: View {
    @Environment(FinanceStore.self) private var store
    @State private var tapped: String?

    var body: some View {
        PartSection(part: .headings) {
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: "Hũ tiết kiệm") {
                    Button { tapped = "Lưu trữ" } label: {
                        HeaderCapsuleLabel(title: "Lưu trữ (2)", opensPage: true)
                    }
                    .headerCapsuleGlass()
                }
                // A goal as the app draws one: `GoalRow` (re-review 2026-10-31: a ListRow here).
                if let goal = store.activeGoals.first {
                    GoalRow(goal: goal)
                        .listCard()
                }
            }

            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: "Thông báo", style: .group)
                FormGroup {
                    FormNavigationRow(title: "Nhắc ghi chi tiêu", icon: "hugeicons-notification-01", value: "21:00") {}
                }
            }

            SampleCard(label: "Quy tắc") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(".section \(Int(TextRole.title.size))pt cho trang chính; .group chữ hoa nhỏ \(Int(TextRole.overline.size))pt cho form và sheet.")
                    Text("Lùi \(Int(RowMetrics.horizontal)) như dòng trong thẻ; tiêu đề → thẻ \(Int(Spacing.headerGap)).")
                    if let tapped {
                        Text("Đã chạm: \(tapped)")
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
                .textRole(.body)
            }
        }
    }
}
