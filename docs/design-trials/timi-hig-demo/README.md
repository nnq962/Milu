# Timi — bản thử thiết kế theo hướng iOS

Mở **Timi-Design-Demo.html** bằng Safari/Chrome. File này chứa toàn bộ HTML, CSS và JavaScript, chạy offline, không cần cài đặt.

Để sửa: chỉnh `index.html`, `style.css`, `app.js`, rồi chạy `python3 bundle.py` để đóng gói lại.

Để xem qua HTTP từ thư mục này:

```sh
python3 -m http.server 5177 --bind 127.0.0.1
```

Mở http://127.0.0.1:5177. Trên desktop có bảng điều khiển chọn màn, màu nhấn và chế độ tối; trên mobile các lựa chọn giao diện nằm trong Cài đặt (avatar Q).

## Có thể thử

- Bốn tab, chi tiết tài sản ròng, tài khoản, hũ, khoản vay, báo cáo và hạn mức.
- Thêm/sửa/xoá thu chi, chuyển khoản, tự cập nhật số dư và thống kê.
- Tìm giao dịch không dấu, lọc loại và tháng, trạng thái chưa có dữ liệu.
- Nạp/rút hũ; điều chỉnh hạn mức; hỏi trợ lý giả lập.
- Ba màu nhấn; giao diện sáng/tối; form có kiểm tra dữ liệu và xác nhận xoá.

## Phạm vi

Đây là đề xuất trực quan dựa trên Apple HIG, **chưa phải giao diện SwiftUI đã triển khai hoặc được chứng nhận phù hợp HIG**. Thanh kính, sheet và icon là mô phỏng bằng web. Khi đưa sang app cần dùng thành phần native, SF Symbols, semantic colors, Dynamic Type và kiểm tra VoiceOver/safe areas trên thiết bị.

Toàn bộ số liệu là dữ liệu minh hoạ. Giao dịch chỉ tồn tại trong phiên trang hiện tại, tải lại sẽ đặt lại. Biểu đồ tài sản ròng dùng mốc quá khứ minh hoạ; mọi cột thu/chi trong báo cáo đều lấy từ giao dịch demo thuộc đúng tháng ghi bên dưới. Trợ lý trả lời theo quy tắc, không gửi dữ liệu đi đâu. Không kết nối ngân hàng, thanh toán, dịch vụ AI hay backend.

Không có file Swift hoặc quy tắc thiết kế đang áp dụng của app bị thay đổi.

## Kiểm tra đã thực hiện

- Trình duyệt ở 1280×900, 390×844 và 320×740; kiểm tra sáng/tối và trạng thái form lỗi.
- Khoản chi 200.000đ: tổng chi 7.800.000đ → 8.000.000đ, tài sản ròng giảm tương ứng. Sửa thành 100.000đ rồi xoá: tổng chi trở lại 7.800.000đ.
- Chuyển 1.000.000đ: hai tài khoản đổi số dư đối ứng, tổng không đổi; từ/đến cùng tài khoản bị chặn.
- Nạp hũ 1.000.000đ: hũ tăng từ 12 lên 13 triệu, tài sản ròng không đổi.
- Hạn mức 18 triệu: phần còn lại và phần trăm cập nhật; tìm “ca phe” ra “Cà phê”; tháng chưa có dữ liệu có trạng thái trống.
- Không thấy lỗi JavaScript trong console trong các luồng trên.

Chưa kiểm tra như app native: bàn phím iOS trên thiết bị thật, VoiceOver, Dynamic Type và hiệu ứng Liquid Glass thực tế.

## Tài liệu tham chiếu

- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
