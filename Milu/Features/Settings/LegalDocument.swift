import SwiftUI

/// A legal page under Cài đặt → Về Milu: Chính sách quyền riêng tư or Điều khoản sử dụng
/// (user request 2026-11-12: two short notes became full pages), laid out like Câu hỏi thường
/// gặp (`ReadingListView`). Every line says what the app does today; when the app changes (an
/// account to sign in to is coming), the text and `updated` change with it.
struct LegalDocument {
    let title: String
    let updated: String
    let entries: [ReadingEntry]

    private static let supportEmail = "support@milu.nnqlab.dev"

    static let privacy = LegalDocument(
        title: "Chính sách quyền riêng tư",
        updated: "12/11/2026",
        entries: [
            ReadingEntry("Tóm tắt",
                         "Số liệu bạn ghi trong Milu được lưu trên iPhone này và trong iCloud của chính bạn. Chỉ khi bạn hỏi Milu AI hoặc nói bằng giọng, phần dữ liệu cần thiết mới được gửi tới máy chủ riêng của Milu, xử lý xong là bỏ, không lưu lại.",
                         "Milu không hiện quảng cáo, không dùng công cụ theo dõi hay phân tích, và không bán hay chia sẻ dữ liệu của bạn cho ai."),
            ReadingEntry("Dữ liệu bạn ghi trong Milu",
                         "Tài khoản, giao dịch, hũ tiết kiệm, khoản vay, hạng mục và danh bạ được lưu trên iPhone này. Khi iPhone đăng nhập iCloud, chúng được đồng bộ vào iCloud riêng của bạn (do Apple giữ, tính vào dung lượng iCloud của bạn), để các thiết bị dùng chung Apple ID có cùng dữ liệu và dữ liệu tự về khi bạn cài lại app hay đổi máy. Milu không có máy chủ lưu dữ liệu này và không xem được iCloud của bạn.",
                         "Hạn mức, tên hiển thị và các cài đặt khác hiện chỉ lưu trên iPhone này.",
                         "Nếu bạn bật sao lưu iCloud hoặc sao lưu iPhone vào máy tính, dữ liệu cũng có thể nằm trong bản sao lưu đó, do Apple và bạn quản lý."),
            ReadingEntry("Khi bạn hỏi Milu AI",
                         "Để trả lời, app gửi tới máy chủ của Milu câu hỏi của bạn cùng tối đa 6 tin nhắn gần nhất trong cuộc trò chuyện, tên hạng mục và tài khoản, tên hiển thị của bạn (nếu có đặt) và ngày hôm nay.",
                         "Khi cần số liệu, app tự tra trên máy rồi chỉ gửi đúng phần cần cho câu trả lời, ví dụ một khoản tổng hay các giao dịch khớp câu hỏi kèm ghi chú của chúng. Toàn bộ sổ sách không bao giờ được gửi đi.",
                         "Dữ liệu đi bằng kết nối mã hoá (HTTPS) qua mạng của Cloudflare tới máy chủ riêng của Milu. AI chạy ngay trên máy chủ đó, không qua dịch vụ AI bên ngoài. Nội dung được xử lý trong bộ nhớ rồi bỏ đi: không lưu, không ghi nhật ký, không dùng để huấn luyện AI. Máy chủ chỉ đếm số lần gọi để chống lạm dụng.",
                         "Lịch sử trò chuyện với Milu AI được lưu trên iPhone này."),
            ReadingEntry("Khi bạn nói bằng giọng",
                         "Đoạn ghi âm được gửi tới máy chủ của Milu, kèm tên hạng mục và tài khoản để nhận đúng chữ, chuyển thành chữ rồi bỏ đi, không lưu lại.",
                         "Khi không kết nối được máy chủ, iPhone tự nhận giọng bằng công cụ của Apple: ngay trên máy nếu iPhone hỗ trợ, nếu không thì qua máy chủ của Apple, theo chính sách quyền riêng tư của Apple."),
            ReadingEntry("Quyền truy cập trên iPhone",
                         "Milu chỉ xin quyền Micro và Nhận dạng giọng nói, và chỉ dùng khi bạn chạm nút micro để nói. Milu không xin quyền vị trí, ảnh hay danh bạ của iPhone. Bạn có thể tắt các quyền này bất cứ lúc nào trong Cài đặt của iPhone."),
            ReadingEntry("Quyền của bạn",
                         "Bạn xem, sửa hoặc xoá được từng mục ngay trong app.",
                         "\"Xoá toàn bộ dữ liệu\" ở cuối Cài đặt xoá mọi số liệu (cả trong iCloud và trên các thiết bị khác của bạn), cùng cài đặt và lịch sử trò chuyện trên máy này. Lượt AI còn lại và các bước Làm quen đã xong vẫn được giữ trên máy, để lượt thưởng không bị nhận lại nhiều lần.",
                         "Xoá app khỏi iPhone chỉ xoá dữ liệu trên máy đó; bản trong iCloud vẫn còn. Bạn có thể xoá hẳn trong Cài đặt của iPhone → tên bạn → iCloud → Quản lý dung lượng."),
            ReadingEntry("Thay đổi chính sách",
                         "Khi Milu thêm tính năng mới làm thay đổi cách xử lý dữ liệu, chẳng hạn tài khoản đăng nhập, chính sách này sẽ được cập nhật trước, kèm ngày cập nhật ở cuối trang. Thay đổi quan trọng sẽ được báo trong app."),
            ReadingEntry("Liên hệ",
                         "Mọi câu hỏi về quyền riêng tư, bạn gửi thư tới \(supportEmail)."),
        ]
    )

    static let terms = LegalDocument(
        title: "Điều khoản sử dụng",
        updated: "12/11/2026",
        entries: [
            ReadingEntry("Đồng ý điều khoản",
                         "Khi dùng Milu, bạn đồng ý với các điều khoản dưới đây. Nếu không đồng ý, bạn có thể ngừng dùng và xoá app bất cứ lúc nào."),
            ReadingEntry("Milu là gì",
                         "Milu là app giúp bạn tự ghi chép và theo dõi thu chi cá nhân. Milu không phải ngân hàng hay ví điện tử: không giữ tiền, không chuyển tiền, không kết nối với tài khoản ngân hàng của bạn.",
                         "Mọi con số, biểu đồ và câu trả lời trong Milu chỉ để bạn tham khảo, không phải lời khuyên tài chính, đầu tư, pháp lý hay thuế."),
            ReadingEntry("Dữ liệu của bạn",
                         "Bạn tự nhập dữ liệu và chịu trách nhiệm về độ chính xác của nó. Dữ liệu thuộc về bạn; cách Milu lưu và xử lý được nói rõ trong Chính sách quyền riêng tư.",
                         "Khi iPhone đăng nhập iCloud, dữ liệu được đồng bộ qua iCloud của bạn. Nếu bạn không dùng iCloud, dữ liệu chỉ nằm trên máy: hãy sao lưu iPhone để không mất dữ liệu khi đổi máy, mất máy hay xoá app."),
            ReadingEntry("Milu AI",
                         "Milu AI trả lời dựa trên số liệu bạn đã ghi, nhưng AI có thể hiểu sai câu hỏi hoặc trả lời sai. Hãy kiểm tra lại trước khi dựa vào câu trả lời để quyết định. Khi bạn nhờ Milu AI ghi hoặc xoá giao dịch, hãy xem lại kết quả trong app; bạn luôn sửa hoặc xoá được.",
                         "Không dùng Milu AI cho việc trái pháp luật, để quấy rối, hay cố làm quá tải, dò lỗi hoặc truy cập trái phép máy chủ của Milu."),
            ReadingEntry("Lượt AI",
                         "Gói miễn phí có \(AIQuota.weeklyFree) lượt hỏi mỗi tuần, làm mới lúc 0 giờ thứ Hai; lượt không dùng hết không cộng dồn sang tuần sau. Mỗi bước Làm quen với Milu bạn hoàn thành được tặng \(AIQuota.stepBonus) lượt thưởng một lần, dùng trong \(AIQuota.bonusDays) ngày và được dùng trước lượt của tuần.",
                         "Nhờ Milu AI ghi hay xoá giao dịch không tốn lượt. Câu Milu không trả lời được (mất mạng, máy chủ lỗi, bạn bấm dừng) được trả lại lượt.",
                         "Lượt AI không quy đổi thành tiền và không chuyển cho người khác được. Milu có thể thay đổi số lượt hoặc cách tính lượt và sẽ báo trong app trước khi áp dụng; khi thấy dấu hiệu lạm dụng, Milu có thể tạm giới hạn việc dùng Milu AI."),
            ReadingEntry("Milu Pro",
                         "Milu Pro chưa mở bán. Khi mở bán, giá, quyền lợi và cách huỷ sẽ được nêu rõ trước khi bạn mua, và việc thanh toán do App Store xử lý theo điều khoản của Apple."),
            ReadingEntry("Sở hữu trí tuệ",
                         "Tên, giao diện, hình ảnh và mã nguồn của Milu thuộc về nhà phát triển Milu. Bạn được dùng app cho mục đích cá nhân, không được sao chép, bán lại hay dịch ngược app.",
                         "Một số thành phần (biểu tượng, phông chữ, hình emoji) thuộc bên thứ ba và dùng theo giấy phép riêng, liệt kê ở Giấy phép mã nguồn mở."),
            ReadingEntry("Giới hạn trách nhiệm",
                         "Milu được cung cấp theo hiện trạng. Nhà phát triển cố gắng để app chạy đúng và ổn định nhưng không cam kết app không bao giờ lỗi hay Milu AI luôn sẵn sàng.",
                         "Trong phạm vi pháp luật cho phép, nhà phát triển Milu không chịu trách nhiệm về thiệt hại phát sinh từ quyết định bạn đưa ra dựa trên số liệu hoặc câu trả lời trong app, hay từ việc mất dữ liệu trên thiết bị."),
            ReadingEntry("Thay đổi và chấm dứt",
                         "Milu có thể cập nhật app và các điều khoản này. Thay đổi quan trọng sẽ được báo trong app; bạn tiếp tục dùng nghĩa là đồng ý với bản mới. Bạn có thể ngừng dùng Milu bất cứ lúc nào bằng cách xoá app."),
            ReadingEntry("Luật áp dụng",
                         "Các điều khoản này theo pháp luật Việt Nam."),
            ReadingEntry("Liên hệ",
                         "Mọi câu hỏi hay góp ý, bạn gửi thư tới \(supportEmail)."),
        ]
    )
}

/// A `LegalDocument`, pushed: laid out like Câu hỏi thường gặp, when it was updated under it.
struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ReadingListView(title: document.title, entries: document.entries,
                        note: "Cập nhật ngày \(document.updated)")
    }
}

#Preview {
    NavigationStack { LegalDocumentView(document: .privacy) }
}
