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

Mỗi file chứa một thành phần chính; file mới trong `Timi/` được Xcode tự nhận (thư mục đồng bộ).

- `Timi/App`: điểm vào app, thanh tab.
- `Timi/Models`: kiểu dữ liệu (tài khoản, hũ, giao dịch, vay nợ, lịch thanh toán).
- `Timi/Store`: `FinanceStore` (trạng thái dùng chung) và dữ liệu mẫu.
- `Timi/Persistence`: database SwiftData trên máy (schema, chuyển đổi, đọc/ghi). Xem [docs/DATABASE.md](docs/DATABASE.md).
- `Timi/Utilities`: định dạng tiền, ngày.
- `Timi/DesignSystem`: hệ thống thiết kế.
  - `Foundations`: màu, chữ (`TextRole`), khoảng cách, bo góc, icon.
  - `Components`: nút, form, sheet, chip, danh sách, biểu đồ, thẻ.
  - `Interaction`: bàn phím, rung.
  - `Legacy`: component đời đầu, bỏ dần khi các màn chuyển sang design system.
- `Timi/Features`: mỗi tab một thư mục (Overview, Accounts, Transactions, Assistant) và `UILibrary` (màn Thư viện UI, mở từ avatar). Màn lớn chia thư mục con: `Cards`, `Sheets`, `Views`, `Services`…

## Trạng thái

Project hiện là bản prototype. Dữ liệu lưu trên máy bằng SwiftData; lần mở đầu tiên nạp dữ liệu mẫu, đặt lại được trong Cài đặt → Nhà phát triển. Chưa tích hợp backend hoặc dịch vụ AI thật.
