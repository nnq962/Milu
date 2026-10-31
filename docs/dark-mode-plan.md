# Kế hoạch dark mode — 2026-10-31

> **Đã làm cùng ngày** đúng như dưới đây, trừ `chartRest` tối giữ #8E8E93 (3:1 trên thẻ tối; #636366 chỉ 2,8:1) và `secondaryLabel` tối #A1A1A6. Viết sau khi design system đã dọn (token theo vai trò, mọi màu đi qua `Palette`), nên dark mode gần như chỉ là việc của một file. Ước lượng: một buổi làm + một buổi xem từng màn.

## Tại sao giờ làm được

- Mọi màu trong app lấy từ 23 token của `Palette`, không còn màu viết cứng trong `Features/`. Đổi giá trị token là đổi cả app.
- Token đặt theo vai trò (`label`, `surface`, `separator`, `negative`…) nên mỗi token có một nghĩa rõ để chọn giá trị tối.
- Chỗ duy nhất ngoài `Palette` có màu: `AccentColor` trong Assets, `UIColor(Palette.…)` trong `Typography.configureNativeAppearance`, và `Color(.placeholderText)` của ô nhập (đã tự thích ứng).

## Cách làm

1. **`Palette` thích ứng.** Mỗi token thành `Color(light:dark:)` qua một helper nhỏ: `Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })`. Giữ tên, giữ giá trị sáng hiện có.
2. **Bỏ khoá sáng:** xoá `INFOPLIST_KEY_UIUserInterfaceStyle = Light` ở cả hai cấu hình trong `project.pbxproj`. App theo hệ thống (HIG). Không thêm mục "Giao diện" trong Cài đặt ở bước đầu; thêm sau nếu người dùng cần ép sáng/tối.
3. **Thanh và tab bar:** `configureNativeAppearance` đang truyền `UIColor(Palette.label)` lúc khởi động. Với `Color` thích ứng, `UIColor` giữ được tính động nếu tạo từ `UIColor { traits in … }`; kiểm tra lại tiêu đề lớn và phụ đề đổi màu khi đổi chế độ.
4. **`AccentColor` trong Assets:** thêm appearance Dark = trắng (#FFFFFF), vì `primary` tối là trắng.
5. **Mép thẻ:** bóng mềm gần như vô hình trên nền tối. Trong `cardEdge`, viền trắng 1pt đổi thành viền `separator` tối (sáng hơn thẻ một chút) và bóng giữ nguyên hoặc tắt khi `colorScheme == .dark`.
6. **Logo ngân hàng** (`InstitutionLogo`): ô trắng giữ trắng trên nền tối (logo có màu riêng), chỉ viền đổi.
7. **Đồ thị Swift Charts** lấy màu từ `Palette.chart` nên tự theo; kiểm tra trục và nhãn (`footnote`, `secondaryLabel`).

## Giá trị tối đề xuất (giữ tinh thần Đơn sắc: trắng trên gần đen, màu chỉ cho nghĩa)

| Token | Sáng | Tối | Ghi chú |
|---|---|---|---|
| `background` | #FAFAFA | #000000 | Nền OLED, như Cài đặt iOS |
| `surface` | #FFFFFF | #1C1C1E | Thẻ, khối dòng (iOS secondarySystemGroupedBackground) |
| `surfaceMuted` | #F3F3F4 | #2C2C2E | Khối nhạt, ô chat, rãnh thanh |
| `separator` | #E8E8EA | #38383A | Kẻ mảnh, viền chip, viền thẻ thay cho viền trắng |
| `label` | #111111 | #F2F2F7 | |
| `secondaryLabel` | #6E6E73 | #9B9BA1 | ≥ 4,5:1 trên #1C1C1E |
| `tertiaryLabel` | #AEAEB2 | #636366 | Chevron |
| `primary` | #111111 | #F2F2F7 | Nút chính, chip chọn, Pro: viên trắng chữ đen |
| `onPrimary` | #FFFFFF | #111111 | |
| `primaryTint` / `rowPressed` | mực 10% | trắng 12% | |
| `primaryDash` | mực 35% | trắng 40% | |
| `fill` | mực 6% | trắng 8% | Nút phụ, badge trung tính |
| `negative` | #B5543F | #E8705A | Sáng hơn để đạt 4,5:1 trên #1C1C1E |
| `onNegative` | #FFFFFF | #111111 | |
| `positive` | #15803D | #4ADE80 | Chấm, mũi tên, chữ 13 |
| `warning` | #D97706 | #F59E0B | Thanh, chấm |
| `warningLabel` | #8A4B08 | #FBBF24 | Chữ cam trên nền tối |
| `chart[0…3]` | #2F7CF6 · #D97706 · #F5555D · #7C4DFF | #5A9BFF · #F5A623 · #FF6B72 · #9C7BFF | Mỗi màu ≥ 3:1 trên #1C1C1E |
| `chartRest` | #8E8E93 | #636366 | |

Tương phản tính lại bằng script như lượt rà soát trước khi chốt.

## Thứ tự làm

1. Helper `Color(light:dark:)` + bảng tối trong `Palette` (30 phút).
2. Bỏ khoá sáng, `AccentColor` dark, `cardEdge` theo `colorScheme` (30 phút).
3. Build, bật Dark trên Simulator (`xcrun simctl ui <udid> appearance dark`), chụp Tổng quan, Tài khoản, Thu chi, Vay nợ, Báo cáo, sheet Thêm giao dịch, Cài đặt, Thư viện UI; sửa chỗ mất tương phản (một buổi).
4. Thư viện UI: thêm nút đổi sáng/tối ngay trong trang để so hai bộ.
5. Ghi `DESIGN_NOTES` (mục Giao diện: hai bộ giá trị, quy tắc viền thay bóng khi tối) và `docs/design-history.md`.

## Rủi ro

- Bóng thẻ vô hình trên nền tối: thẻ #1C1C1E trên #000000 đã tự tách, viền `separator` là đủ.
- Ảnh logo ngân hàng nền trắng trên thẻ tối: ô trắng 32pt là chủ ý, giống Wallet.
- Font Manrope không ảnh hưởng. `UIFontMetrics` không liên quan màu.
- Người dùng từng bỏ dark mode 2026-10-30 vì khó duy trì hai bảng; với token theo vai trò, chi phí duy trì là một cột trong bảng trên.
