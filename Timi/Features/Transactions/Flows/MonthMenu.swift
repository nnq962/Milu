import SwiftUI

/// Month button from the design: "Tháng 5" + chevron on a muted capsule.
struct MonthMenu: View {
    @Binding var month: Date

    var body: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let number = calendar.component(.month, from: month)
        let isCurrentYear = year == calendar.component(.year, from: .now)
        Menu {
            Button("Tháng trước") { shift(-1) }
            Button("Tháng hiện tại") { month = .now }
            Button("Tháng sau") { shift(1) }
            Divider()
            ForEach((year - 1)...(year + 1), id: \.self) { targetYear in
                Menu(String(targetYear)) {
                    ForEach(1...12, id: \.self) { targetMonth in
                        Button("Tháng \(targetMonth)") {
                            if let date = calendar.date(from: DateComponents(year: targetYear, month: targetMonth, day: 1)) {
                                month = date
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(isCurrentYear ? "Tháng \(number)" : "T\(number)/\(year.formatted(.number.grouping(.never)))")
                    .textRole(.body)
                    .monospacedDigit()
                SolarIcon("solar-alt-arrow-down-linear", size: 14)
            }
            .foregroundStyle(Palette.ink)
        }
        .menuIndicator(.hidden)
        .nativeGlassButton(tint: Palette.muted)
        .buttonBorderShape(.capsule)
        .accessibilityLabel("Chọn tháng, tháng \(number) năm \(String(year))")
    }

    private func shift(_ delta: Int) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        month = calendar.date(byAdding: .month, value: delta, to: start) ?? start
    }
}
