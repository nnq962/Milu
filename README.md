# Timi

Ứng dụng quản lý tài chính cá nhân cho iPhone, viết bằng SwiftUI, với giao diện tiếng Việt và định dạng tiền VND.

## Tính năng

- Tổng quan tài sản, dư nợ, thu chi và biểu đồ chi tiêu.
- Danh sách tài khoản và lịch sử giao dịch theo tài khoản.
- Thêm, xoá, tìm kiếm và lọc giao dịch thu/chi.
- Trợ lý tài chính giả lập, trả lời từ dữ liệu trong ứng dụng.

## Chạy project

1. Clone repository và mở `Timi.xcodeproj` bằng Xcode (project được tạo bằng Xcode 26.3).
2. Chọn scheme `Timi` và một iPhone Simulator, sau đó nhấn Run (`⌘R`).
3. Nếu chạy trên iPhone thật, chọn Development Team của bạn trong Signing & Capabilities.

Deployment target hiện tại là iOS 17.6. Project không dùng thư viện bên ngoài.

## Cấu trúc

- `Timi/Models`: model, dữ liệu mẫu và store dùng chung.
- `Timi/Features`: màn hình tổng quan, tài khoản, giao dịch và trợ lý.
- `Timi/Shared`: component giao diện và hàm định dạng.

## Trạng thái

Project hiện là bản prototype với dữ liệu mẫu. Dữ liệu chỉ lưu trong bộ nhớ và sẽ được đặt lại khi khởi động lại ứng dụng. Chưa tích hợp backend hoặc dịch vụ AI thật.
