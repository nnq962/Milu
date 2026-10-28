import SwiftUI

struct ProgressPart: View {
    var body: some View {
        PartSection(part: .progress) {
            SampleCard(label: "Chi theo ngày · Swift Charts") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    DailySpendingChart(month: .now, totals: Self.sampleTotals)
                    Text("Nhấn giữ rồi kéo trên cột để xem số tiền từng ngày (như app Sức khoẻ); hôm nay màu chanh.")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            SampleCard(label: "Tiến độ · mặc định đen") {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    progressSample("Hũ tiết kiệm · 70%", value: 0.7, color: Palette.primary)
                    progressSample("Khoản cho vay đã thu · 40%", value: 0.4, color: Palette.primary)
                }
            }
            SampleCard(label: "Hạn mức · đổi màu theo mức") {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    progressSample("Còn thoải mái · 47%", value: 0.47, color: ProgressBar.budgetColor(0.47))
                    progressSample("Sắp chạm hạn mức · 86%", value: 0.86, color: ProgressBar.budgetColor(0.86))
                    progressSample("Vượt hạn mức · 126%", value: 1.26, color: ProgressBar.budgetColor(1.26))
                    Text("Xanh dưới 80% · cam từ 80% · đỏ khi chạm hoặc vượt 100%.")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
    }

    /// A month of made-up spending, up to today.
    private static let sampleTotals: [Int: Double] = {
        let today = Calendar.current.component(.day, from: .now)
        let pattern: [Double] = [120, 45, 0, 310, 85, 60, 0, 540, 95, 150, 30, 0, 260, 75]
        return Dictionary(uniqueKeysWithValues: (1...today).map { ($0, pattern[$0 % pattern.count] * 1_000) })
    }()

    private func progressSample(_ title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title).textRole(.label)
            ProgressBar(value: value, color: color)
        }
    }
}
