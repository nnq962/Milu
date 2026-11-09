import SwiftUI

/// "Câu hỏi thường gặp" (Cài đặt → Hỗ trợ), pushed: each question in ink and bold, its answer
/// under it in grey, one card (review 2026-11-09: one block of grey text in a note, the questions
/// looking like the answers, read by VoiceOver as one long element). Every answer says what the
/// app does today.
struct FAQView: View {
    private struct Entry: Identifiable {
        let question: String
        let answer: String
        var id: String { question }
    }

    private let entries = [
        Entry(question: "Dữ liệu của tôi lưu ở đâu?",
              answer: "Chỉ trên máy này. Milu chưa tự sao lưu hay đồng bộ lên máy chủ nào."),
        Entry(question: "Hạn mức chi tiêu tính thế nào?",
              answer: "Cộng mọi khoản chi trong tháng, cả phí chuyển khoản và lãi vay; không tính các khoản bạn đánh dấu không tính vào báo cáo và các tài khoản đang khoá. Đặt ở Cài đặt → Hạn mức chi tiêu."),
        Entry(question: "Lượt AI là gì?",
              answer: "Mỗi câu hỏi gửi Milu AI dùng một lượt. Mỗi tháng có \(AIQuota.monthlyFree) lượt miễn phí, thêm \(AIQuota.stepBonus) lượt thưởng cho mỗi bước Làm quen với Milu bạn làm xong."),
        Entry(question: "Chuyển tiền giữa các tài khoản có tính là chi không?",
              answer: "Không. Chỉ phí chuyển khoản (nếu có) được tính là chi."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(entry.question)
                            .textRole(.bodyStrong)
                            .foregroundStyle(Palette.label)
                        Text(entry.answer)
                            .textRole(.body)
                            .foregroundStyle(Palette.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, RowMetrics.horizontal)
                    .padding(.vertical, Spacing.l)
                    .overlay(alignment: .top) { if index > 0 { FormDivider(hasIcon: false) } }
                    .accessibilityElement(children: .combine)
                }
            }
            .listCard()
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Câu hỏi thường gặp")
        .navigationBarTitleDisplayMode(.inline)
    }
}
