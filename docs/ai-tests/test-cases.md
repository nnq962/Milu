# Bộ test Milu AI

Mỗi case là một cuộc chat mới trên dữ liệu mẫu của app. Chạy bằng `Tests/AILiveTests.swift` (xem README.md). Mọi câu trả lời còn được kiểm chung: không mở đầu bằng “Ủa”/“Ê”, không lộ mã thẻ hay lời nhắc hệ thống, không nói “thẻ” với người dùng (trừ thẻ tín dụng), không trống.

## T · Số tiền: cách nói tiền, từ lóng, số bằng chữ, thiếu số tiền (17 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| T01 | Số tiền kiểu k, trùng khoản đã có hôm nay | “ăn trưa 45k” | thẻ chờ Lưu: 1 khoản, 45.000đ, mục Ăn trưa, cảnh báo trùng |
| T02 | Số tiền kiểu nghìn | “cà phê 35 nghìn” | thẻ chờ Lưu: 35.000đ, mục Cà phê |
| T03 | Số tiền kiểu 1tr2 | “mua giày 1tr2” | thẻ chờ Lưu: 1.200.000đ, mục Giày dép |
| T04 | Số tiền kiểu triệu | “tiền nhà tháng này 5 triệu” | thẻ chờ Lưu: 5.000.000đ, mục Thuê nhà |
| T05 | Số bằng chữ (như giọng nói) | “ăn sáng ba mươi nghìn” | thẻ chờ Lưu: 30.000đ, mục Ăn sáng |
| T06 | Từ lóng: cành | “đi grab 50 cành” | thẻ chờ Lưu: 50.000đ, mục Taxi, xe ôm |
| T07 | Từ lóng: củ | “mua áo khoác 2 củ” | thẻ chờ Lưu: 2.000.000đ, mục Quần áo |
| T08 | Từ lóng: nửa củ | “đóng tiền điện nửa củ” | thẻ chờ Lưu: 500.000đ, mục Tiền điện |
| T09 | Từ lóng: xị | “ăn tối 3 xị” | thẻ chờ Lưu: 300.000đ, mục Ăn tối |
| T10 | Số có dấu chấm và đ | “cà phê 25.000đ” | thẻ chờ Lưu: 25.000đ, mục Cà phê |
| T11 | Trăm rưỡi | “ăn trưa 1 trăm rưỡi” | thẻ chờ Lưu: 150.000đ, mục Ăn trưa |
| T12 | Số trơn không đơn vị | “mua sách 85000” | thẻ chờ Lưu: 85.000đ, mục Sách |
| T13 | Thiếu số tiền rồi trả lời | “ghi ăn trưa” | không ra thẻ; hỏi lại; nói “bao nhiêu” hoặc “bao nhieu” hoặc “số tiền” |
|  | ↳ | “50k” | thẻ chờ Lưu: 50.000đ, mục Ăn trưa |
| T14 | Tự sửa số trong câu | “ăn trưa 60k à nhầm 55k” | thẻ chờ Lưu: 55.000đ |
| T15 | Số tiền lớn | “mua laptop 25 triệu” | thẻ chờ Lưu: 25.000.000đ, mục Đồ điện tử |
| T16 | Số tiền quá giới hạn | “mua nhà 2000 tỷ” | không ra thẻ |
| T17 | Năm chục | “ăn trưa năm chục” | thẻ chờ Lưu: 50.000đ, mục Ăn trưa |

## H · Hạng mục chi: chọn đúng mục, mục rộng, mục chưa có (22 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| H01 | Đúng tên mục | “trà sữa 45k” | thẻ chờ Lưu: mục Trà sữa |
| H02 | Trà đá không phải Trà sữa | “trà đá 10k” | hỏi lại; nói “Trà đá” **hoặc** thẻ chờ Lưu: 10.000đ, không phải mục Trà sữa |
| H03 | Mục chưa có: hỏi lại kèm danh sách và đề xuất mục mới | “ăn vặt 20k” | không ra thẻ; hỏi lại; nói “Ăn vặt”; nói “Ăn sáng” hoặc “Ăn trưa” hoặc “Cà phê” |
| H04 | Chọn tạo mục mới rồi Lưu | “ăn vặt 20k” | hỏi lại |
|  | ↳ | “tạo mục Ăn vặt đi” | thẻ chờ Lưu: 20.000đ, đề xuất mục mới “Ăn vặt” |
|  | ↳ | *(bấm Lưu)* | đã lưu 1 khoản; đã tạo mục “Ăn vặt” |
| H05 | Chọn mục có sẵn khi được hỏi | “ăn vặt 20k” | hỏi lại |
|  | ↳ | “cho vào Ăn trưa” | thẻ chờ Lưu: 20.000đ, mục Ăn trưa |
| H06 | Mục rộng: mua áo | “mua áo 300k” | thẻ chờ Lưu: mục Quần áo |
| H07 | Xem phim | “xem phim 120k” | thẻ chờ Lưu: mục Xem phim |
| H08 | Khám răng | “đi khám răng 500k” | thẻ chờ Lưu: mục Khám bệnh |
| H09 | Học tiếng Nhật | “học tiếng Nhật 1tr2” | thẻ chờ Lưu: 1.200.000đ, mục Khoá học hoặc Học phí **hoặc** hỏi lại; nói “Học tiếng Nhật” |
| H10 | Đổ xăng | “đổ xăng 80k” | thẻ chờ Lưu: mục Xăng |
| H11 | Mua thuốc | “mua thuốc cảm 50k” | thẻ chờ Lưu: mục Thuốc |
| H12 | Cước điện thoại không phải đồ điện tử | “tiền điện thoại tháng này 100k” | thẻ chờ Lưu: mục Điện thoại |
| H13 | Nạp tiền điện thoại là chi | “nạp tiền điện thoại 50k” | thẻ chờ Lưu: mục Điện thoại |
| H14 | Quà sinh nhật | “mua quà sinh nhật mẹ 500k” | thẻ chờ Lưu: mục Quà tặng |
| H15 | Thú cưng | “mua thức ăn cho mèo 150k” | thẻ chờ Lưu: mục Thú cưng |
| H16 | Đám cưới | “đi đám cưới bạn 1 triệu” | thẻ chờ Lưu: mục Hiếu hỉ |
| H17 | Gửi xe | “gửi xe 5k” | thẻ chờ Lưu: mục Gửi xe |
| H18 | Đồ cho con | “mua bỉm cho con 400k” | thẻ chờ Lưu: mục Con cái |
| H19 | Tập gym | “đóng tiền tập gym 500k” | thẻ chờ Lưu: mục Thể thao |
| H20 | Nạp game | “nạp game 100k” | thẻ chờ Lưu: mục Game |
| H21 | Đồ uống khác: nước mía | “nước mía 10k” | hỏi lại; nói “Nước mía” **hoặc** thẻ chờ Lưu: 10.000đ, không phải mục Trà sữa / Cà phê |
| H22 | Đồ uống khác: sinh tố | “sinh tố bơ 30k” | hỏi lại; nói “Sinh tố” **hoặc** thẻ chờ Lưu: 30.000đ, không phải mục Trà sữa / Cà phê |

## N · Thu nhập (7 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| N01 | Lương | “nhận lương 25 triệu” | thẻ chờ Lưu: 25.000.000đ, khoản thu, mục Lương chính |
| N02 | Thưởng | “được thưởng 2 triệu” | thẻ chờ Lưu: khoản thu, mục Tiền thưởng |
| N03 | Được cho | “mẹ cho 500k” | thẻ chờ Lưu: khoản thu, mục Được cho, tặng |
| N04 | Bán đồ | “bán đồ cũ được 300k” | thẻ chờ Lưu: khoản thu, mục Bán đồ |
| N05 | Lãi ngân hàng | “lãi ngân hàng tháng này 200k” | thẻ chờ Lưu: khoản thu, mục Lãi tiết kiệm |
| N06 | Làm thêm | “làm thêm được 1tr5” | thẻ chờ Lưu: 1.500.000đ, khoản thu, mục Làm thêm |
| N07 | Hoàn tiền | “được hoàn tiền shopee 50k” | thẻ chờ Lưu: khoản thu, mục Hoàn tiền |

## K · Tài khoản (6 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| K01 | Nói tên ví | “ăn trưa 50k bằng momo” | thẻ chờ Lưu: tài khoản MoMo |
| K02 | Không nói tài khoản: Milu tự chọn | “ăn tối 70k” | thẻ chờ Lưu: ghi “Milu tự chọn” tài khoản |
| K03 | Tên tắt ngân hàng | “cà phê 30k quẹt thẻ VCB” | thẻ chờ Lưu: tài khoản Vietcombank |
| K04 | Tài khoản không có: hỏi lại kèm danh sách | “ăn trưa 50k bằng ví ZaloPay” | không ra thẻ; hỏi lại; nói “Ví tiền mặt” hoặc “MoMo” hoặc “Vietcombank” |
| K05 | Thẻ tín dụng | “mua áo 500k bằng thẻ tín dụng” | thẻ chờ Lưu: tài khoản Thẻ VPBank Visa |
| K06 | Thu vào ngân hàng | “nhận lương 25 triệu vào techcombank” | thẻ chờ Lưu: khoản thu, tài khoản Techcombank |

## D · Ngày giờ (5 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| D01 | Hôm qua | “hôm qua ăn tối 150k” | thẻ chờ Lưu: 150.000đ, hôm qua |
| D02 | Hôm kia | “hôm kia đổ xăng 70k” | thẻ chờ Lưu: ngày -2 |
| D03 | Sáng nay | “sáng nay ăn phở 40k” | thẻ chờ Lưu: mục Ăn sáng, hôm nay |
| D04 | Ngày mai (chưa tới): không ghi | “ngày mai đóng tiền nhà 5 triệu” | không ra thẻ |
| D05 | Mấy ngày trước | “3 ngày trước mua sách 120k” | thẻ chờ Lưu: mục Sách, ngày -3 |

## M · Nhiều khoản trong một câu (7 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| M01 | Ba khoản một câu | “cà phê 35k, gửi xe 5k, grab 40k” | thẻ chờ Lưu: 3 khoản, 35.000đ, 5.000đ, 40.000đ |
| M02 | Hai khoản nối bằng với | “sáng ăn phở 40k với cà phê 20k” | thẻ chờ Lưu: 2 khoản, 40.000đ, 20.000đ |
| M03 | Một khoản ghi được, một khoản không | “ăn trưa 50k và rút 2 triệu ở VCB” | thẻ chờ Lưu: 1 khoản, 50.000đ; nói thật chưa ghi được chuyển tiền, chỉ cách ghi tay; nói “Chuyển khoản” |
| M04 | Bốn khoản trong ngày | “hôm nay tiêu: ăn sáng 30k, ăn trưa 50k, ăn tối 70k, trà sữa 45k” | thẻ chờ Lưu: 4 khoản, 30.000đ, 50.000đ, 70.000đ, 45.000đ |
| M05 | Câu nói dài 5 khoản, 2 khoản chưa có mục (ảnh của người dùng) | “Sáng nay tôi ăn sáng hết ba mươi nghìn uống trà đá hết năm nghìn xong rồi buổi trưa tôi ăn trưa hết bốn mươi nghìn buổi chiều ăn vặt hết bảy mươi nghìn tối ăn cơm hết năm mươi nghìn” | không ra thẻ; hỏi lại; nói “Trà đá”; nói “Ăn vặt”; “Chọn mục có sẵn” chỉ nói một lần |
|  | ↳ | “trà đá tạo mới, ăn vặt tạo mới” | thẻ chờ Lưu: 5 khoản, 30.000đ, 5.000đ, 40.000đ, 70.000đ, 50.000đ |
| M06 | Câu dài 5 khoản, tạo theo đề xuất, rồi thêm ghi chú cho một khoản (ảnh của người dùng) | “Sáng nay tôi ăn sáng hết ba mươi nghìn uống trà đá hết năm nghìn xong rồi buổi trưa tôi ăn trưa hết bốn mươi nghìn buổi chiều ăn vặt hết bảy mươi nghìn tối ăn cơm hết năm mươi nghìn” | không ra thẻ; hỏi lại; “Chọn mục có sẵn” chỉ nói một lần |
|  | ↳ | “ok tạo theo đề xuất đi” | thẻ chờ Lưu: 5 khoản, 30.000đ, 5.000đ, 40.000đ, 70.000đ, 50.000đ |
|  | ↳ | “sửa cho tôi khoản ăn tối thêm ghi chú được giảm giá” | thẻ chờ Lưu: 5 khoản, 30.000đ, 5.000đ, 40.000đ, 70.000đ, 50.000đ, ghi chú có “giảm giá”, thay thẻ cũ |
| M07 | Hai khoản chưa có mục, trả lời “theo đề xuất đi” | “uống trà đá 5k, ăn vặt 70k” | không ra thẻ; hỏi lại; “Chọn mục có sẵn” chỉ nói một lần |
|  | ↳ | “theo đề xuất đi” | thẻ chờ Lưu: 2 khoản, 5.000đ, 70.000đ |

## S · Sửa thẻ, lưu, huỷ, xem lại (12 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| S01 | Sửa số tiền | “ăn trưa 60k” | thẻ chờ Lưu: 60.000đ |
|  | ↳ | “à không, 50k thôi” | thẻ chờ Lưu: 50.000đ, ghi “Milu tự chọn” tài khoản, thay thẻ cũ |
| S02 | Sửa tài khoản | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | “đổi sang momo” | thẻ chờ Lưu: 60.000đ, tài khoản MoMo, thay thẻ cũ |
| S03 | Bỏ một khoản khỏi thẻ | “cà phê 35k, gửi xe 5k” | thẻ chờ Lưu: 2 khoản |
|  | ↳ | “bỏ khoản gửi xe đi” | thẻ chờ Lưu: 1 khoản, 35.000đ, thay thẻ cũ |
| S04 | Gõ ok để lưu | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | “ok” | nói “Đã lưu”; đã lưu 1 khoản |
| S05 | Gõ huỷ | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | “huỷ” | nói “Đã huỷ”; đã lưu 0 khoản |
| S06 | Thêm khoản vào thẻ đang chờ | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | “thêm cà phê 20k nữa” | thẻ chờ Lưu: có 20.000đ |
| S07 | Sửa ngày | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | “hôm qua chứ không phải hôm nay” | thẻ chờ Lưu: 60.000đ, hôm qua, thay thẻ cũ |
| S08 | Câu dài để lưu | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | “đúng rồi lưu đi” | đã lưu 1 khoản |
| S09 | Quên rồi, xem lại thẻ đang chờ | “ăn trưa 60k, cà phê 20k” | thẻ chờ Lưu: 2 khoản |
|  | ↳ | “tôi quên mất list rồi, cho tôi xem lại” | thẻ chờ Lưu: 2 khoản, 60.000đ, 20.000đ, thay thẻ cũ |
| S10 | Lưu rồi mới hỏi xem lại | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | *(bấm Lưu)* | đã lưu 1 khoản |
|  | ↳ | “liệt kê mấy khoản vừa ghi” | tra bằng list_transactions; nói “60.000” hoặc “60k” |
| S11 | Hỏi sao lại chọn tài khoản đó | “ăn trưa 60k” | thẻ chờ Lưu: ghi “Milu tự chọn” tài khoản |
|  | ↳ | “sao lại chọn tài khoản đó?” | không ra thẻ; nói “gần nhất” hoặc “dùng gần” hoặc “tự chọn” hoặc “tự động chọn” hoặc “tự đoán” hoặc “chọn sẵn” hoặc “lần trước” hoặc “không nói” |
| S12 | Thêm ghi chú | “ăn trưa 60k” | thẻ chờ Lưu |
|  | ↳ | “ghi chú là ăn với sếp” | thẻ chờ Lưu: 60.000đ, ghi chú có “sếp”, thay thẻ cũ |

## Q · Trả lời khi Milu hỏi lại (4 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| Q01 | Chỉ nói số tiền, trả lời mục | “ghi khoản chi 200k” | không ra thẻ; hỏi lại |
|  | ↳ | “đi chợ” | thẻ chờ Lưu: 200.000đ, mục Đi chợ |
| Q02 | Trả lời bằng câu tự nhiên | “chi 100k” | không ra thẻ; hỏi lại |
|  | ↳ | “đi cà phê với bạn” | thẻ chờ Lưu: 100.000đ, mục Cà phê |
| Q03 | Thu chưa rõ nguồn | “nhận 2 triệu” | không ra thẻ; hỏi lại |
|  | ↳ | “tiền làm thêm” | thẻ chờ Lưu: 2.000.000đ, khoản thu, mục Làm thêm |
| Q04 | Nhờ ghi mà chưa nói gì | “ghi giúp mình 1 khoản” | không ra thẻ |

## R · Việc Milu chưa ghi được (chuyển khoản, vay, hũ) (7 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| R01 | Rút tiền | “rút 2 triệu ở VCB” | không ra thẻ; nói thật chưa ghi được chuyển tiền, chỉ cách ghi tay; nói “Chuyển khoản” |
| R02 | Chuyển giữa hai ví | “chuyển 500k từ VCB sang MoMo” | không ra thẻ; nói thật chưa ghi được chuyển tiền, chỉ cách ghi tay |
| R03 | Cho mượn | “cho Tuấn mượn 500k” | không ra thẻ; nói thật chưa ghi được vay nợ, chỉ cách ghi tay; nói “khoản vay” hoặc “Vay nợ” |
| R04 | Trả nợ | “trả nợ anh Minh 1 triệu” | không ra thẻ; nói thật chưa ghi được vay nợ, chỉ cách ghi tay |
| R05 | Bỏ tiền vào hũ | “bỏ 1 triệu vào hũ du lịch” | không ra thẻ; nói thật chưa ghi được hũ, chỉ cách ghi tay |
| R06 | Hỏi có ghi được nợ không | “có ghi được khoản nợ không?” | không ra thẻ; nói “chưa” hoặc “chỉ ghi được” hoặc “mới ghi được”; không nói “được chứ”, “được luôn” |
| R07 | Trả thẻ tín dụng | “trả thẻ tín dụng 3 triệu” | không ra thẻ; nói thật chưa ghi được chuyển tiền, chỉ cách ghi tay |

## L · Tra cứu số liệu (11 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| L01 | Chi tháng này | “tháng này mình chi bao nhiêu?” | tra bằng summarize_transactions; nói “đ” hoặc “triệu”; không nói “tuần này” |
| L02 | Tiêu gì nhiều nhất | “tuần này tiêu gì nhiều nhất?” | tra bằng summarize_transactions / list_transactions |
| L03 | Số dư | “mình còn bao nhiêu tiền?” | tra bằng get_accounts |
| L04 | Ai đang nợ | “ai đang nợ mình?” | tra bằng get_loans; nói “Minh” |
| L05 | Hũ tiết kiệm | “hũ du lịch được bao nhiêu rồi?” | tra bằng get_savings_goals; nói “8.000.000” hoặc “8 triệu” hoặc “8tr” |
| L06 | Hôm qua tiêu gì | “hôm qua mình tiêu những gì?” | tra bằng list_transactions / summarize_transactions; nói “Grab” hoặc “chợ” hoặc “WinMart” hoặc “72.000” hoặc “685.000” |
| L07 | Hỏi tiếp tháng trước | “tháng này chi ăn uống bao nhiêu?” | tra bằng summarize_transactions |
|  | ↳ | “còn tháng trước?” | tra bằng summarize_transactions |
| L08 | Trung bình mỗi tháng | “trung bình mỗi tháng mình tiêu bao nhiêu?” | tra bằng get_monthly_trend |
| L09 | Còn được tiêu bao nhiêu | “tháng này còn được tiêu bao nhiêu?” | tra bằng get_budget |
| L10 | Sắp phải trả gì | “sắp tới có khoản nào phải trả không?” | tra bằng get_upcoming / get_recurring / get_loans |
| L11 | Tìm theo tên | “tìm giao dịch Netflix” | tra bằng list_transactions; nói “260.000” hoặc “Netflix” |

## X · Xoá giao dịch (2 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| X01 | Xoá một khoản | “xoá khoản cà phê hôm nay” | hiện thẻ xác nhận xoá; không nói “xong rồi”, “đã xoá”, “đã xóa” |
| X02 | Xoá hết: không được xoá hàng loạt | “xoá hết giao dịch tháng này” | không hiện thẻ xoá; không nói “đã xoá hết”, “đã xóa hết”; đã lưu 0 khoản |

## A · Hỏi về app (3 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| A01 | Lượt AI | “còn bao nhiêu lượt hỏi AI?” | tra bằng get_app_info |
| A02 | iCloud | “dữ liệu của mình có lên iCloud không?” | tra bằng get_app_info |
| A03 | Cách thêm tài khoản | “làm sao để thêm tài khoản ngân hàng?” | tra bằng get_app_info |

## G · Giọng nói chuyện, câu ngoài lề (5 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| G01 | Chào hỏi | “chào Milu” | không ra thẻ |
| G02 | Hỏi ngoài lề | “hôm nay thời tiết thế nào?” | không ra thẻ; không nói “độ C”, “nắng đẹp”, “trời mưa” |
| G03 | Đùa vui | “kể chuyện cười đi” | không ra thẻ |
| G04 | Người dùng buồn | “tháng này tiêu hoang quá, buồn ghê” | không ra thẻ; không nói “tuần này” |
| G05 | Cảm ơn | “cảm ơn nha” | không ra thẻ; không gọi công cụ |

## V · Không dấu, viết tắt, gõ sai, giọng nói (6 case)

| ID | Tình huống | Người dùng | Milu phải |
|---|---|---|---|
| V01 | Không dấu | “an trua 50k” | thẻ chờ Lưu: 50.000đ, mục Ăn trưa |
| V02 | Viết tắt cf | “cf 30k” | thẻ chờ Lưu: 30.000đ, mục Cà phê |
| V03 | Gõ sai chính tả | “đổ săng 50k” | thẻ chờ Lưu: 50.000đ, mục Xăng |
| V04 | Câu nói dài như giọng nói | “ừm ghi cho mình khoản ăn trưa năm mươi nghìn nha” | thẻ chờ Lưu: 50.000đ, mục Ăn trưa |
| V05 | Không dấu nhiều khoản | “an sang 25k, cafe 20k” | thẻ chờ Lưu: 2 khoản, 25.000đ, 20.000đ |
| V06 | Gõ sai tên app | “grap ve nha 45k” | thẻ chờ Lưu: 45.000đ, mục Taxi, xe ôm |

