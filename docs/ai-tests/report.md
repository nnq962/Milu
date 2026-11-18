# Kết quả test Milu AI (2026-11-18)

**113/114 case đạt** (99%).

Gộp 2 lần chạy: case nào chạy lại thì lấy lần sau cùng. AI trả lời mỗi lần một khác, nên một case đạt ở đây vẫn có thể có lúc trượt.

| Nhóm | Đạt |
|---|---|
| T · Số tiền: cách nói tiền, từ lóng, số bằng chữ, thiếu số tiền | 16/17 ⚠️ |
| H · Hạng mục chi: chọn đúng mục, mục rộng, mục chưa có | 22/22 |
| N · Thu nhập | 7/7 |
| K · Tài khoản | 6/6 |
| D · Ngày giờ | 5/5 |
| M · Nhiều khoản trong một câu | 7/7 |
| S · Sửa thẻ, lưu, huỷ, xem lại | 12/12 |
| Q · Trả lời khi Milu hỏi lại | 4/4 |
| R · Việc Milu chưa ghi được (chuyển khoản, vay, hũ) | 7/7 |
| L · Tra cứu số liệu | 11/11 |
| X · Xoá giao dịch | 2/2 |
| A · Hỏi về app | 3/3 |
| G · Giọng nói chuyện, câu ngoài lề | 5/5 |
| V · Không dấu, viết tắt, gõ sai, giọng nói | 6/6 |

## Case chưa đạt (1)

### T04 · Số tiền kiểu triệu

- **Người dùng:** “tiền nhà tháng này 5 triệu”
  - **Milu:** Khoản “Tiền nhà” 5.000.000đ này xếp vô mục nào trong nhóm “Nhà cửa” nè? 👀 ⏎ • Chọn mục có sẵn: Thuê nhà, Sửa chữa, Đồ gia dụng, Dọn dẹp ⏎ • Hoặc tạo mục mới “Tiền nhà” trong nhóm “Nhà cửa” luôn cho tiện ✨ ⏎  ⏎ Chốt cái nào thì nhắn Milu nè 🚀
  - Công cụ: record_transaction
  - ❌ không có thẻ

## Case đạt (113)

| ID | Tình huống | Milu trả lời (lượt cuối) |
|---|---|---|
| T01 | Số tiền kiểu k, trùng khoản đã có hôm nay | Thẻ: Ăn trưa · 45.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ⚠️ Hôm nay đã có Ăn trưa 45.000đ lúc 12:15. |
| T02 | Số tiền kiểu nghìn | Thẻ: Cà phê · 35.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| T03 | Số tiền kiểu 1tr2 | Thẻ: Giày dép · 1.200.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “mua giày” |
| T05 | Số bằng chữ (như giọng nói) | Thẻ: Ăn sáng · 30.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| T06 | Từ lóng: cành | Thẻ: Taxi, xe ôm · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đi grab” |
| T07 | Từ lóng: củ | Thẻ: Quần áo · 2.000.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Mua áo khoác” |
| T08 | Từ lóng: nửa củ | Thẻ: Tiền điện · 500.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đóng tiền điện” |
| T09 | Từ lóng: xị | Thẻ: Ăn tối · 300.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| T10 | Số có dấu chấm và đ | Thẻ: Cà phê · 25.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| T11 | Trăm rưỡi | Thẻ: Ăn trưa · 150.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| T12 | Số trơn không đơn vị | Thẻ: Sách · 85.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “mua sách” |
| T13 | Thiếu số tiền rồi trả lời | Thẻ: Ăn trưa · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| T14 | Tự sửa số trong câu | Thẻ: Ăn trưa · 55.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| T15 | Số tiền lớn | Thẻ: Đồ điện tử · 25.000.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “mua laptop” |
| T16 | Số tiền quá giới hạn | Số tiền quá lớn: Milu ghi tối đa 999.999.999.999đ một khoản. |
| T17 | Năm chục | Thẻ: Ăn trưa · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| H01 | Đúng tên mục | Thẻ: Trà sữa · 45.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| H02 | Trà đá không phải Trà sữa | Khoản “trà đá” 10.000đ này xếp vô mục nào trong nhóm “Ăn uống” nè? 🤔 ⏎ • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ ⏎ • Hoặc tạo mục mới |
| H03 | Mục chưa có: hỏi lại kèm danh sách và đề xuất mục mới | Khoản “ăn vặt” 20.000đ này xếp vô mục nào trong nhóm “Ăn uống” nè? 👀 ⏎ • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ ⏎ • Hoặc tạo mục mới |
| H04 | Chọn tạo mục mới rồi Lưu | (bấm Lưu: đã lưu) |
| H05 | Chọn mục có sẵn khi được hỏi | Thẻ: Ăn trưa · 20.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “ăn vặt” |
| H06 | Mục rộng: mua áo | Thẻ: Quần áo · 300.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “mua áo” |
| H07 | Xem phim | Thẻ: Xem phim · 120.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| H08 | Khám răng | Thẻ: Khám bệnh · 500.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đi khám răng” |
| H09 | Học tiếng Nhật | Khoản “Học tiếng Nhật” 1.200.000đ này xếp vô mục nào trong nhóm “Học tập” nè? 🤔 ⏎ • Chọn mục có sẵn: Học phí, Sách, Khoá học ⏎ • Hoặc tạo mục mới “Học tiếng Nhậ |
| H10 | Đổ xăng | Thẻ: Xăng · 80.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đổ xăng” |
| H11 | Mua thuốc | Thẻ: Thuốc · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Thuốc cảm” |
| H12 | Cước điện thoại không phải đồ điện tử | Thẻ: Điện thoại · 100.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Tiền điện thoại” |
| H13 | Nạp tiền điện thoại là chi | Thẻ: Điện thoại · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Nạp tiền điện thoại” |
| H14 | Quà sinh nhật | Thẻ: Quà tặng · 500.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “quà sinh nhật mẹ” |
| H15 | Thú cưng | Thẻ: Thú cưng · 150.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Thức ăn cho mèo” |
| H16 | Đám cưới | Thẻ: Hiếu hỉ · 1.000.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đi đám cưới bạn” |
| H17 | Gửi xe | Thẻ: Gửi xe · 5.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| H18 | Đồ cho con | Thẻ: Con cái · 400.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Mua bỉm cho con” |
| H19 | Tập gym | Thẻ: Thể thao · 500.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đóng tiền tập gym” |
| H20 | Nạp game | Thẻ: Game · 100.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Nạp game” |
| H21 | Đồ uống khác: nước mía | Khoản “Nước mía” 10.000đ này xếp vô mục nào trong nhóm “Ăn uống” nè? 🧐 ⏎ • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ ⏎ • Hoặc tạo mục m |
| H22 | Đồ uống khác: sinh tố | Khoản “sinh tố bơ” 30.000đ này xếp vô mục nào trong nhóm “Ăn uống” nè? 🧐 ⏎ • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ ⏎ • Hoặc tạo mục |
| N01 | Lương | Thẻ: Lương chính · 25.000.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “nhận lương” |
| N02 | Thưởng | Thẻ: Tiền thưởng · 2.000.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Thưởng” |
| N03 | Được cho | Thẻ: Được cho, tặng · 500.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Mẹ cho” |
| N04 | Bán đồ | Thẻ: Bán đồ · 300.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Bán đồ cũ” |
| N05 | Lãi ngân hàng | Thẻ: Lãi tiết kiệm · 200.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Lãi ngân hàng” |
| N06 | Làm thêm | Thẻ: Làm thêm · 1.500.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| N07 | Hoàn tiền | Thẻ: Hoàn tiền · 50.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Hoàn tiền Shopee” |
| K01 | Nói tên ví | Thẻ: Ăn trưa · 50.000đ · chi · MoMo · 2026-11-18 |
| K02 | Không nói tài khoản: Milu tự chọn | Thẻ: Ăn tối · 70.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| K03 | Tên tắt ngân hàng | Thẻ: Cà phê · 30.000đ · chi · Vietcombank · 2026-11-18 |
| K04 | Tài khoản không có: hỏi lại kèm danh sách | Bạn không có tài khoản nào tên “Ví ZaloPay”. Ghi vào tài khoản nào? 👀 ⏎ • Chọn: Ví tiền mặt, Vietcombank, Techcombank, MoMo, Thẻ VPBank Visa ⏎  ⏎ Chốt cái nào t |
| K05 | Thẻ tín dụng | Thẻ: Quần áo · 500.000đ · chi · Thẻ VPBank Visa · 2026-11-18 · ghi chú “mua áo” |
| K06 | Thu vào ngân hàng | Thẻ: Lương chính · 25.000.000đ · thu · Techcombank · 2026-11-18 · ghi chú “Nhận lương” |
| D01 | Hôm qua | Thẻ: Ăn tối · 150.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-17 |
| D02 | Hôm kia | Thẻ: Xăng · 70.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-16 · ghi chú “Đổ xăng” |
| D03 | Sáng nay | Thẻ: Ăn sáng · 40.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “ăn phở” |
| D04 | Ngày mai (chưa tới): không ghi | Ngày 19/11 chưa tới: Milu chỉ ghi khoản đã chi hoặc đã nhận. ⏎ • Khoản lặp lại hằng tháng thì tạo giao dịch định kỳ: nút + → Thêm giao dịch → Lặp lại. |
| D05 | Mấy ngày trước | Thẻ: Sách · 120.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-15 · ghi chú “Mua sách” |
| M01 | Ba khoản một câu | Thẻ: Cà phê · 35.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Gửi xe · 5.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Taxi, xe ôm · 40.000đ  |
| M02 | Hai khoản nối bằng với | Thẻ: Ăn sáng · 40.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Phở” / Cà phê · 20.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| M03 | Một khoản ghi được, một khoản không | Thẻ: Ăn trưa · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| M04 | Bốn khoản trong ngày | Thẻ: Ăn sáng · 30.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Ăn trưa · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Ăn tối · 70.000đ ·  |
| M05 | Câu nói dài 5 khoản, 2 khoản chưa có mục (ảnh của người dùng) | Thẻ: Ăn sáng · 30.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Trà đá (mục mới) · 5.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Ăn trưa · 4 |
| M06 | Câu dài 5 khoản, tạo theo đề xuất, rồi thêm ghi chú cho một khoản (ảnh của người dùng) | Thẻ (thay thẻ cũ): Ăn sáng · 30.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Trà đá (mục mới) · 5.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| M07 | Hai khoản chưa có mục, trả lời “theo đề xuất đi” | Thẻ: Trà đá (mục mới) · 5.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Uống trà đá” / Ăn vặt (mục mới) · 70.000đ · chi · Ví tiền mặt (Milu tự |
| S01 | Sửa số tiền | Thẻ (thay thẻ cũ): Ăn trưa · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| S02 | Sửa tài khoản | Thẻ (thay thẻ cũ): Ăn trưa · 60.000đ · chi · MoMo · 2026-11-18 |
| S03 | Bỏ một khoản khỏi thẻ | Thẻ (thay thẻ cũ): Cà phê · 35.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| S04 | Gõ ok để lưu | Đã lưu. |
| S05 | Gõ huỷ | Đã huỷ, Milu chưa ghi gì. |
| S06 | Thêm khoản vào thẻ đang chờ | Thẻ (thay thẻ cũ): Ăn trưa · 60.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Cà phê · 20.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| S07 | Sửa ngày | Thẻ (thay thẻ cũ): Ăn trưa · 60.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-17 |
| S08 | Câu dài để lưu | Đã lưu. |
| S09 | Quên rồi, xem lại thẻ đang chờ | Thẻ (thay thẻ cũ): Ăn trưa · 60.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 / Cà phê · 20.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| S10 | Lưu rồi mới hỏi xem lại | Các khoản bạn vừa ghi nè 👀 ⏎ • Chi **60.000đ** cho Ăn trưa (Ví tiền mặt) ⏎ • Chi **45.000đ** cho Ăn trưa (Ví tiền mặt) ⏎ • Chi **55.000đ** cho Cà phê (MoMo) ⏎   |
| S11 | Hỏi sao lại chọn tài khoản đó | À, Milu tự động chọn **Ví tiền mặt** vì đây là khoản chi nhỏ, thường là tiền mặt nha 💸. Bạn muốn đổi sang tài khoản nào khác thì cứ báo Milu, trước khi bấm Lưu  |
| S12 | Thêm ghi chú | Thẻ (thay thẻ cũ): Ăn trưa · 60.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “ăn với sếp” |
| Q01 | Chỉ nói số tiền, trả lời mục | Thẻ: Đi chợ · 200.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| Q02 | Trả lời bằng câu tự nhiên | Thẻ: Cà phê · 100.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đi cà phê với bạn” |
| Q03 | Thu chưa rõ nguồn | Thẻ: Làm thêm · 2.000.000đ · thu · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Tiền làm thêm” |
| Q04 | Nhờ ghi mà chưa nói gì | Khoản này là chi hay thu vậy bạn? 💸 Cho mình thêm chi tiết nha! |
| R01 | Rút tiền | Milu chưa ghi được chuyển tiền giữa các tài khoản (chuyển khoản, rút tiền, nạp ví): tính năng này chưa có. Bạn ghi tay giúp Milu nhé: ⏎ • Nút + → Thêm giao dịch |
| R02 | Chuyển giữa hai ví | Milu chưa ghi được chuyển tiền giữa các tài khoản (chuyển khoản, rút tiền, nạp ví): tính năng này chưa có. Bạn ghi tay giúp Milu nhé: ⏎ • Nút + → Thêm giao dịch |
| R03 | Cho mượn | Milu chưa ghi được khoản vay hay trả nợ: tính năng này chưa có. Bạn ghi tay giúp Milu nhé: ⏎ • Khoản vay mới: nút + → Thêm khoản vay. ⏎ • Trả hay thu nợ: Giao d |
| R04 | Trả nợ | Milu chưa ghi được khoản vay hay trả nợ: tính năng này chưa có. Bạn ghi tay giúp Milu nhé: ⏎ • Khoản vay mới: nút + → Thêm khoản vay. ⏎ • Trả hay thu nợ: Giao d |
| R05 | Bỏ tiền vào hũ | Milu chưa ghi được tiền bỏ vào hay rút từ hũ tiết kiệm: tính năng này chưa có. Bạn ghi tay giúp Milu nhé: ⏎ • Tài khoản → chọn hũ → Nạp tiền hoặc Rút tiền. |
| R06 | Hỏi có ghi được nợ không | Milu mới ghi được khoản chi và khoản thu thôi nha 💸. ⏎  ⏎ Nếu bạn muốn ghi khoản nợ, bạn phải làm thủ công theo cách này nè: ⏎ • Khoản vay mới: Bấm + → Thêm kho |
| R07 | Trả thẻ tín dụng | Milu chưa ghi được chuyển tiền giữa các tài khoản (chuyển khoản, rút tiền, nạp ví): tính năng này chưa có. Bạn ghi tay giúp Milu nhé: ⏎ • Nút + → Thêm giao dịch |
| L01 | Chi tháng này | Chi tháng này của bạn là **6.869.000đ** nha 💸. Tổng cộng có 20 giao dịch đó. ⏎  ⏎ • Chi nhiều nhất ở mục Ăn uống (**1.830.000đ**). ⏎ • Các tài khoản chi nhiều n |
| L02 | Tiêu gì nhiều nhất | Ăn uống chiếm sóng nhiều nhất trong tuần này với **835.000đ** đó bạn 🍜. ⏎  ⏎ • Tổng chi tiêu tuần này là **1.167.000đ**. ⏎ • Các khoản chi lớn khác là Giải trí  |
| L03 | Số dư | Dư dả ghê nha bạn! 😎 ⏎ • Tổng tài sản ròng của bạn hiện là **192.090.000đ**. ⏎ • Số tiền đang có (bao gồm tiền mặt và ví) là **118.520.000đ**. ⏎ • Bạn có đang c |
| L04 | Ai đang nợ | À, có 2 người đang nợ bạn nè 💸: ⏎  ⏎ • Minh Trần còn nợ **45.000.000đ** (hạn 26/11/2026). ⏎ • Hùng Lê còn nợ **35.000.000đ** (hạn 03/01/2027). ⏎  ⏎ Tổng cộng là |
| L05 | Hũ tiết kiệm | Chi tiết về các hũ nè! ✈️ ⏎  ⏎ • Hũ Du lịch Đà Nẵng đang có **8.000.000đ** đó nha. Mục tiêu là **20.000.000đ**, còn thiếu **12.000.000đ** thôi à. ⏎ • Tháng này  |
| L06 | Hôm qua tiêu gì | Hôm qua bạn chi **2** giao dịch nha 💸: ⏎  ⏎ • **72.000đ** cho Taxi, xe ôm (Grab về nhà) qua MoMo. ⏎ • **685.000đ** cho Đi chợ (Đi chợ WinMart) qua Vietcombank.  |
| L07 | Hỏi tiếp tháng trước | Mấy bé tháng trước bạn chi ăn uống là **0đ** đó 😮. ⏎  ⏎ • Có vẻ tháng trước bạn chill nhẹ nhàng hơn vụ ăn uống nha. ⏎ • Nhớ kiểm tra lại xem có sót giao dịch nà |
| L08 | Trung bình mỗi tháng | Trung bình mỗi tháng bạn chi khoảng **7.250.000đ** nha 💸. ⏎  ⏎ • Tháng này (đến hôm nay), bạn đã chi **6.869.000đ** đó. ⏎ • Tháng 10 là tháng bạn chi nhiều nhất |
| L09 | Còn được tiêu bao nhiêu | Nè, tháng này bạn đã chi **6.869.000đ** trong tổng hạn mức **30.000.000đ** rồi đó 💸. ⏎  ⏎ • Bạn còn dư **23.131.000đ** để tiêu nha. ⏎ • Khoảng **1.779.308đ** mỗ |
| L10 | Sắp phải trả gì | Trong 14 ngày tới thì bạn không có khoản nào phải trả nha 😌. Nhưng có 1 khoản nè: ⏎ • Ngày 26/11, bạn sẽ nhận **45.000.000đ** từ Minh Trần nha! 🎉 ⏎  ⏎ Bạn muốn  |
| L11 | Tìm theo tên | Chi tiêu cho Netflix là **260.000đ** nha 🎬. Giao dịch này là vào ngày 16/11 nha. ⏎  ⏎ • Bạn muốn xem thêm giao dịch nào khác không? ⏎ • Nhớ kiểm tra lại các kho |
| X01 | Xoá một khoản | Khoản cần xoá ở bên dưới, bạn bấm xác nhận nhé: |
| X02 | Xoá hết: không được xoá hàng loạt | Bạn ơi, Milu chỉ xoá được từng giao dịch một nha 📝. Danh sách giao dịch tháng này có **22** khoản. ⏎  ⏎ Bạn muốn xoá khoản nào trước? Cho Milu xin mã giao dịch  |
| A01 | Lượt AI | Nè, bạn còn **10** lượt hỏi AI nha 🔥. Lượt này sẽ được làm mới lúc 0 giờ thứ Tư 18/11 đó. ⏎  ⏎ • Gói miễn phí có 10 lượt mỗi tuần, không cộng dồn nha. ⏎ • Nhớ l |
| A02 | iCloud | Dữ liệu của bạn được đồng bộ lên iCloud nha ☁️. ⏎  ⏎ • Milu không có máy chủ lưu dữ liệu, nên dữ liệu của bạn được lưu trên iPhone của bạn và đồng bộ qua iCloud |
| A03 | Cách thêm tài khoản | Nghe nè, để thêm tài khoản ngân hàng thì bạn vào tab **Tài khoản** 💸, rồi bấm nút **+** ở góc trên, chọn **Tài khoản ngân hàng** là okela luôn nha! 👍 |
| G01 | Chào hỏi | Chào bạn! Milu đây nè 👋 Bạn cần mình giúp gì hôm nay? Cứ chill thôi nha 💸 |
| G02 | Hỏi ngoài lề | Thời tiết hôm nay không có trong phạm vi của Milu nha 🫠. Bạn muốn mình xem lại chi tiêu hay kiểm tra tài chính của bạn không? 😉 |
| G03 | Đùa vui | Haha, Milu không có kho chuyện cười sẵn nha 🫠. Nhưng mà để mình kể bạn nghe một câu nè: ⏎  ⏎ Tại sao con ma lại sợ bóng tối? ⏎ Vì nó sợ... bóng đèn! 😂 ⏎  ⏎ Thôi |
| G04 | Người dùng buồn | • Tổng chi tháng này của bạn là **6.869.000đ** nha. ⏎ • Danh mục "Ăn uống" là khoản lớn nhất với **1.830.000đ**. ⏎ • Các khoản khác cũng khá nhiều nha, ví dụ "H |
| G05 | Cảm ơn | Okela bạn ơi! Có gì cứ hú Milu nha. Luôn sẵn sàng giúp bạn quản lý ví tiền xịn xò nè 😉💸 |
| V01 | Không dấu | Thẻ: Ăn trưa · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “An trua” |
| V02 | Viết tắt cf | Thẻ: Cà phê · 30.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “cf” |
| V03 | Gõ sai chính tả | Thẻ: Xăng · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “đổ xăng” |
| V04 | Câu nói dài như giọng nói | Thẻ: Ăn trưa · 50.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 |
| V05 | Không dấu nhiều khoản | Thẻ: Ăn sáng · 25.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “An sang” / Cà phê · 20.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 ·  |
| V06 | Gõ sai tên app | Thẻ: Taxi, xe ôm · 45.000đ · chi · Ví tiền mặt (Milu tự chọn) · 2026-11-18 · ghi chú “Grab về nhà” |
