# Milu

Ứng dụng quản lý tài chính cá nhân cho iPhone, viết bằng SwiftUI, với giao diện tiếng Việt và định dạng tiền VND.

## Tính năng

- Tổng quan tài sản, dư nợ, thu chi và biểu đồ chi tiêu.
- Danh sách tài khoản và lịch sử giao dịch theo tài khoản.
- Thêm, xoá, tìm kiếm và lọc giao dịch thu/chi.
- Trợ lý tài chính giả lập, trả lời từ dữ liệu trong ứng dụng.

## Chạy project

1. Clone repository và mở `Milu.xcodeproj` bằng Xcode (project được tạo bằng Xcode 26.3).
2. Chọn scheme `Milu` và một iPhone Simulator, sau đó nhấn Run (`⌘R`).
3. Nếu chạy trên iPhone thật, chọn Development Team của bạn trong Signing & Capabilities.

Deployment target là iOS 26.0 (Liquid Glass, `Tab(role: .search)`); không có nhánh tương thích iOS cũ. Project không dùng thư viện bên ngoài.

Chạy test: `⌘U` trong Xcode (scheme `Milu`), hoặc:

```bash
xcodebuild test -project Milu.xcodeproj -scheme Milu -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Cấu trúc

Mỗi file chứa một thành phần chính; file mới trong `Milu/` được Xcode tự nhận (thư mục đồng bộ).

- `Milu/App`: điểm vào app, thanh tab, các khoá lưu cài đặt (`StorageKey`).
- `Milu/Models`: kiểu dữ liệu (tài khoản, hũ, giao dịch, vay nợ, lịch thanh toán).
- `Milu/Store`: `FinanceStore` (trạng thái dùng chung), chia file theo mảng (`FinanceStore+Accounts`, `+Goals`, `+Transfers`, `+Loans`, `+Contacts`, `+Transactions`, `+Categories`, `+Reports`); `AIQuota` (lượt AI); dữ liệu mẫu.
- `Milu/Persistence`: database SwiftData trên máy (schema, chuyển đổi, đọc/ghi). Xem [docs/DATABASE.md](docs/DATABASE.md).
- `Milu/Utilities`: định dạng tiền, ngày.
- `Milu/DesignSystem`: hệ thống thiết kế.
  - `Foundations`: màu, chữ (`TextRole`), khoảng cách, bo góc, icon.
  - `Components`: nút, form, sheet, chip, danh sách, biểu đồ, thẻ.
  - `Interaction`: bàn phím, rung.
- `Tests`: test Swift Testing cho logic tiền (số dư, chuyển khoản, vay nợ, khoá/lưu trữ) và lượt AI.
- `Milu/Features`: mỗi tab một thư mục (Overview, Accounts, Transactions), Assistant (trang Trợ lý AI mở từ Tổng quan), cùng Reports, Settings, Shared và `UILibrary` (màn Thư viện UI, mở từ Cài đặt → Nhà phát triển). Màn lớn chia thư mục con: `Cards`, `Sheets`, `Views`, `Services`…

## Trạng thái

Project hiện là bản prototype. Dữ liệu lưu trên máy bằng SwiftData; lần mở đầu tiên nạp dữ liệu mẫu, đặt lại được trong Cài đặt → Nhà phát triển. Chưa tích hợp backend hoặc dịch vụ AI thật.
