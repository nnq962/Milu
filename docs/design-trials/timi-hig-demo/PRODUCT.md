# Timi — phạm vi bản demo

## Platform
web — bản HTML mô phỏng app iPhone SwiftUI. Đây là đề xuất thiết kế, chưa thay đổi app.

## Product truth
Timi là ứng dụng quản lý tài chính cá nhân bằng tiếng Việt, dùng tiền VND. Bốn tab: Tổng quan, Tài khoản, Giao dịch và Trợ lý AI. Chức năng hiện có gồm thu chi, chuyển khoản, hũ tiết kiệm, vay nợ, hạn mức và báo cáo. Bản iOS lưu trên máy, trợ lý hiện là giả lập. Nguồn: README.md, DESIGN_NOTES.md và mã nguồn project.

## Requested work
Người dùng yêu cầu demo HTML có phong cách màu và layout chuyên nghiệp hơn, theo Apple HIG. Chọn hướng iOS native là ràng buộc trực tiếp của yêu cầu. Bản demo dùng dữ liệu minh hoạ, giữ bốn tab và tiếng Việt; không kết nối ngân hàng hoặc AI. Không thay đổi quy tắc thiết kế của bản SwiftUI đang chạy.

## Stack
HTML, CSS, JavaScript thuần, không cần cài dependency hoặc tải font từ bên ngoài. Mở trực tiếp hoặc phục vụ qua HTTP.

## Operating context
Xem trên desktop dưới dạng khung điện thoại; mở trên mobile dùng toàn màn hình. Dữ liệu chỉ tồn tại trong phiên demo và đặt lại khi tải lại.
