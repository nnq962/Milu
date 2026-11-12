import SwiftUI

/// "Câu hỏi thường gặp" (Cài đặt → Hỗ trợ), pushed: each question in ink and bold, its answer
/// under it in grey, one card (review 2026-11-09: one block of grey text in a note, the questions
/// looking like the answers, read by VoiceOver as one long element). Laid out by
/// `ReadingListView`, like the legal pages. Every answer says what the app does today.
struct FAQView: View {
    private let entries = [
        ReadingEntry("Dữ liệu của tôi lưu ở đâu?",
                     "Chỉ trên máy này. Milu chưa tự sao lưu hay đồng bộ lên máy chủ nào."),
        ReadingEntry("Hạn mức chi tiêu tính thế nào?",
                     "Cộng mọi khoản chi trong tháng, cả phí chuyển khoản và lãi vay; không tính các khoản bạn đánh dấu không tính vào báo cáo và các tài khoản đang khoá. Đặt ở Cài đặt → Hạn mức chi tiêu."),
        ReadingEntry("Lượt AI là gì?",
                     "Mỗi câu hỏi gửi Milu AI dùng một lượt; nhờ Milu ghi hay xoá giao dịch thì không tốn lượt, và câu Milu không trả lời được (mất mạng, bấm dừng) được trả lại lượt. Mỗi tuần có \(AIQuota.weeklyFree) lượt miễn phí, làm mới lúc 0 giờ thứ Hai. Mỗi bước Làm quen với Milu bạn làm xong được thêm \(AIQuota.stepBonus) lượt thưởng, dùng trong \(AIQuota.bonusDays) ngày."),
        ReadingEntry("Chuyển tiền giữa các tài khoản có tính là chi không?",
                     "Không. Chỉ phí chuyển khoản (nếu có) được tính là chi."),
    ]

    var body: some View {
        ReadingListView(title: "Câu hỏi thường gặp", entries: entries)
    }
}
