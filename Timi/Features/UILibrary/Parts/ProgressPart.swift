import SwiftUI

struct ProgressPart: View {
    var body: some View {
        PartSection(part: .progress) {
            SampleCard(label: "Tiến độ · màu chính") {
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
                    // As `ProgressBar.budgetColor` does (strict review 2026-10-31: it said green).
                    Text("Mực dưới 80% · cam từ 80% · đỏ khi chạm hoặc vượt 100%.")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                }
            }
            // The one line for where a limit stands, wherever a limit is shown.
            SampleCard(label: "Dòng hạn mức · BudgetStatusLine") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    BudgetStatusLine(level: .fine, message: "Đã dùng 42% hạn mức, còn 2,9tr")
                    BudgetStatusLine(level: .nearing, message: "Đã dùng 86% hạn mức, còn 700k")
                    BudgetStatusLine(level: .over, message: "Vượt hạn mức 1,3tr")
                }
            }
            SampleCard(label: "Vòng · ProgressRing") {
                HStack(spacing: Spacing.xl) {
                    ring(0.25)
                    ring(0.6)
                    ring(1)
                }
            }
        }
    }

    private func progressSample(_ title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title).textRole(.body)
            ProgressBar(value: value, color: color)
        }
    }

    /// A ring round a goal's icon, as on Tài khoản.
    private func ring(_ progress: Double) -> some View {
        ProgressRing(progress: progress)
            .frame(width: RowMetrics.listLogo, height: RowMetrics.listLogo)
            .overlay {
                TimiIcon("hugeicons-piggy-bank", size: RowMetrics.listLogo / 2)
                    .foregroundStyle(Palette.label)
            }
    }
}
