# Ghi chú thiết kế Timi

Tệp dùng chung để ghi lại góp ý, ý tưởng, quyết định và các việc cần chỉnh trong quá trình triển khai giao diện. Người dùng có thể sửa trực tiếp hoặc nhờ Codex cập nhật từ nội dung trao đổi.

## Quy tắc đang áp dụng — ưu tiên cho mọi màn hình

**Đã được người dùng duyệt ngày 2026-10-27. Áp dụng cả khi sửa các màn hiện có và làm màn mới.** Các ghi chú thử nghiệm bên dưới là lịch sử; nếu mâu thuẫn, ưu tiên quy tắc hiện hành này và quyết định mới hơn của người dùng.

### Hiệu ứng mờ native iOS

- Dùng navigation bar / toolbar và tab bar **native iOS**, để hệ thống tự xử lý nền mờ và hiệu ứng scroll-edge khi nội dung cuộn bên dưới. Màn Tổng quan hiện tại là bản tham chiếu đã được duyệt.
- Đặt các nút cần cố định phía trên trong `ToolbarItem` của `NavigationStack`; giữ navigation bar hiển thị. Dùng `TabView` cho thanh tab mặc định.
- Không tự dựng header mờ bằng `Material`, blur radius, gradient, mask, overlay hay opacity theo scroll offset. Không ép màu nền/độ trong suốt của toolbar để giả lập hiệu ứng hệ thống.
- Button giữ Liquid Glass native trên iOS hỗ trợ. Chỉ chỉnh màu, font, kích thước và hình dáng theo vai trò. Nếu nút tròn 44pt dùng glass riêng bên trong toolbar, ẩn shared background của item trên iOS 26 để tránh nền kép; vẫn giữ backdrop của navigation bar do hệ thống quản lý.
- Card và ô dữ liệu dùng nền đặc, continuous corners và shadow theo thiết kế; không Liquid Glass. Ô ngày lịch là vùng dữ liệu phẳng có thể chạm, không có kính riêng.
- Khi sửa màn khác, kiểm tra cả đầu trang và khi đã cuộn: hiệu ứng mờ do iOS điều khiển, nút rõ và dùng được, nội dung không che status bar. Không thay các màn còn lại chỉ để tái tạo một lớp blur tự viết.

### Các nền tảng giao diện đã chốt

- Manrope; light theme; Solar Icons; tiền tệ liền số và cùng cỡ/font/weight/baseline (`10.000.000đ`, `10,3tr`).
- Góc continuous dùng token theo vai trò: card lớn 32pt, ô tài sản 28pt, ô thu/chi 18pt, nền icon 12pt, ô lịch 8pt. Không dùng một radius chung cho mọi tỷ lệ card.
- Mẫu nguồn trong `examples`; các điều chỉnh đã được duyệt được ghi tại đây. Không tự thêm CTA ngoài thiết kế.

## Bối cảnh

- App iPhone viết bằng SwiftUI, giao diện tiếng Việt, tiền tệ VND.
- Có 4 màn chính: Tổng quan, Tài khoản, Giao dịch và Trợ lý AI.
- Đã nhận prompt Sleek gồm 9 mục: 3 mẫu Tổng quan, Tài khoản, Thu chi, Vay nợ, Trợ lý AI, Cài đặt và bộ thành phần giao diện. Đã chọn Tổng quan mẫu 1, nhận hai ảnh giống nhau (phần đầu tới Cần chú ý).
- Project hiện dùng dữ liệu mẫu, lưu trong bộ nhớ.

## Ghi chú cần xử lý

Ý tưởng chưa chốt không mặc nhiên là yêu cầu triển khai.

- **2026-10-27 — Cần kiểm tra:** Người dùng xem thanh tab mới trên iPhone để đánh giá icon và font; kích thước và bố cục tab do iOS quản lý.

### Mẫu ghi chú

- **Ngày:** YYYY-MM-DD
- **Màn hình / phạm vi:** Toàn app hoặc tên màn hình
- **Nội dung:** Góp ý hoặc vấn đề cần xử lý
- **Trạng thái:** Ý tưởng / Cần làm / Đang làm / Cần kiểm tra / Hoàn tất / Không áp dụng
- **Quyết định / kết quả:** Ghi cách xử lý, lý do hoặc nội dung còn cần làm rõ

## Quyết định đã chốt

- **2026-10-27:** Dùng tệp này để lưu các ghi chú phát sinh khi làm giao diện.

- **2026-10-27:** Dùng Manrope làm font của app.
- **2026-10-27:** Ưu tiên thanh tab mặc định iOS, không dựng thanh tab riêng; dùng font Manrope và bỏ màu xanh ở trạng thái chọn. Icon cần gọn, thanh hơn. Giữ 4 tab hiện có trong lần chỉnh này.

## Lịch sử hoàn tất

- **2026-10-27:** Thêm Manrope kèm giấy phép OFL; áp dụng cho nội dung và tiêu đề. Thanh tab vẫn dùng `TabView`, nhãn Manrope, màu chọn đen/trắng theo giao diện hệ thống và SF Symbols nét viền. Chờ người dùng đánh giá trực quan.

## Tổng quan mẫu 1 — 2026-10-27

- **Đã triển khai:** Nền trắng ngà, thẻ tài sản với ba ô, dải Pro/làm quen app cuộn ngang, tổng quan tháng, hạn mức, Cần chú ý và lịch thu chi. Dùng Manrope và thanh tab native hiện tại.
- **Dữ liệu:** Tài sản, dư nợ, thu chi và các ngày trong lịch đọc FinanceStore. Ngày tháng/lời chào theo thời gian thiết bị. Số liệu khác mockup vì vẫn dùng dữ liệu mẫu hiện có.
- **Hạn mức:** Người dùng tự đặt; lưu cục bộ bằng AppStorage, áp dụng cùng mức mỗi tháng; mặc định chưa đặt. Không dùng thu nhập làm hạn mức.
- **Tương tác:** Mở form thêm giao dịch, chuyển sang trợ lý, xem tài khoản đang nợ, chuyển tháng và xem giao dịch của từng ngày.
- **Chưa có chức năng:** Cho vay hiển thị “—”; chưa có ngày đến hạn, thông báo, gói Pro, lượt AI thưởng hay dùng thử thật. Pro mở nội dung giới thiệu sắp ra mắt. Không tự tạo các khoản vay hoặc ngày đến hạn từ ảnh.
- **Cần tài nguyên:** Avatar tạm dùng chữ Q; cần ảnh gốc nếu muốn giống avatar trong mockup.
- **Cần đối chiếu:** Phần Cần chú ý và lịch chưa có ảnh đầy đủ; hiện dựng theo cấu trúc prompt Sleek, điều chỉnh cho dữ liệu app.
- **Điều chỉnh có chủ đích:** Nút Pro là “Tìm hiểu thêm” khi chưa mở đăng ký; nhiệm vụ làm quen dẫn tới chức năng hiện có; không hiện chấm thông báo đỏ khi chưa có thông báo. Bản đầu tăng vùng bấm làm thẻ quá cao; đã sửa lại ở vòng đối chiếu bên dưới.

### Kiểm tra bản Tổng quan

- Build Debug cho iPhone Simulator thành công; `git diff --check` sạch.
- Đã xem giao diện trên iPhone 17 / iOS 26.3.
- Đã kiểm tra chuyển lịch sang tháng 11/2026 và mở ngày 1/11: hiển thị trạng thái chưa có giao dịch.
- Đã kiểm tra hạn mức: trường trống không cho áp dụng; nhập 30.000.000 và áp dụng thành công, giao diện hiển thị 47% (14.119.000 / 30.000.000). Simulator hiện giữ hạn mức mẫu này để xem trước; cài mới mặc định chưa đặt.
- Chưa kiểm tra đầy đủ trên iPhone thật, iOS 17.6, Dark Mode hoặc cỡ chữ trợ năng lớn.

### Vòng sửa độ sát mẫu — 2026-10-27

- **Phản hồi người dùng:** Chữ của bản triển khai mỏng hơn design; nhiều chi tiết chưa sát mẫu. Không coi việc build thành công là đã đạt yêu cầu về hình thức.
- **Đã sửa:** Dùng trực tiếp các named instance Manrope Medium (500), SemiBold (600), Bold (700), ExtraBold (800) cho màn Tổng quan. Chữ phụ dùng màu #6B7280 từ thiết kế thay cho `.secondary` của iOS.
- **Đã sửa:** Thẻ Pro/làm quen trở về khoảng 122pt thay vì 178pt; rộng 200/220pt, khoảng cách 12pt, padding 14pt. Giảm khoảng cách trong thẻ tài sản, nhãn 11pt Medium và số tiền 14pt SemiBold. Hạn mức dày 8pt. Các số rút gọn trong thẻ bỏ khoảng trắng trước “tr”.
- **Cách đối chiếu:** So ảnh mẫu và ảnh Simulator ở cùng chiều rộng 402pt. Mẫu không vẽ status bar/Dynamic Island, app chừa safe area thật nên điểm bắt đầu nội dung khác. Giữ thanh tab native như đã chốt.
- **Còn khác:** Avatar, icon Solar trong thẻ so với SF Symbols, nội dung từ dữ liệu hiện có và trạng thái tính năng chưa triển khai. Chưa có ảnh đủ phần dưới để xác nhận độ sát từng chi tiết.

## Quy ước button native — 2026-10-27

- **Yêu cầu đã chốt:** Giữ hiệu ứng và trạng thái button mặc định của Apple. Chỉ chỉnh màu, cỡ và font; chỉnh hình dáng khi có nhu cầu cụ thể (ví dụ nút chuông, nút gửi hình tròn).
- Dùng `Button` và các style hệ thống (`automatic`, `bordered`, `borderedProminent`) theo ngữ cảnh. Để hệ điều hành xử lý hiệu ứng nhấn, focus và disabled; không tự thêm scale, animation, shadow hoặc nền mô phỏng button.
- Ưu tiên quy ước này hơn việc sao chép hiệu ứng button trong mockup Sleek. Hình thức có thể khác giữa các phiên bản iOS.
- **Đã áp dụng:** Bỏ nền/nút Pro tự vẽ; chuyển chuông, ô lịch, gợi ý chat và nút gửi sang style hệ thống. Các nút dạng dòng dùng automatic; nút toolbar tiếp tục dùng mặc định.

### Sửa quy ước Liquid Glass — 2026-10-27

- **Phản hồi:** Bản trước mất Liquid Glass, nút chuông nhỏ hơn avatar và tự thêm nút Thêm giao dịch ở cuối ngoài thiết kế.
- **Đính chính:** `bordered` / `borderedProminent` không thay thế cho Liquid Glass. Trên iOS 26 dùng trực tiếp `glass` / `glassProminent` của Apple; chỉ dùng style bordered để tương thích iOS cũ.
- **Đã sửa:** Nút chuông hình tròn 44 × 44 pt bằng avatar, nền glass hệ thống; nút Pro dạng capsule compact theo mẫu. Các button có nền ở lịch và chat dùng style glass native. Không thêm hiệu ứng nhấn tự viết.
- **Đã bỏ:** Nút Thêm giao dịch ở cuối Tổng quan. Không tự thêm CTA hoặc thay đổi vị trí nút ngoài thiết kế.
- Kích thước button phải đối chiếu theo từng vai trò trong mẫu, không áp cùng controlSize một cách máy móc.

## Quy ước giao diện và tiền tệ — 2026-10-27

- **Avatar:** Là button Liquid Glass native, 44pt như nút chuông; nhấn mở hồ sơ. Chữ Q vẫn là ảnh đại diện tạm.
- **Cho vay:** Khôi phục 80tr từ dữ liệu mẫu Sleek (Minh 45tr, Hùng 35tr). Store tính tổng từ các khoản phải thu và cộng vào tổng tài sản ròng. Thay thế ghi chú “Cho vay chưa có dữ liệu” của bản trước; đây vẫn là dữ liệu mẫu.
- **Theme:** App luôn dùng light theme, kể cả khi thiết bị bật Dark Mode.
- **Cuộn:** Ẩn chỉ báo cuộn dọc toàn app; nội dung vẫn cuộn bình thường.
- **Tiền tệ — đã xác nhận:** Dạng đầy đủ `10.000.000đ`; dạng rút gọn `10,3tr` (người dùng xác nhận “10m3tr” là gõ nhầm). Các đơn vị `đ`, `k`, `tr`, `tỷ` viết sát số, không có khoảng trắng. Dùng dấu chấm phân nhóm và dấu phẩy cho phần thập phân.
- Đơn vị và số tiền phải cùng font, cùng cỡ, cùng weight và cùng baseline. Không dùng ký hiệu `₫`, không thu nhỏ hoặc nâng đơn vị. Dùng chung formatter `vnd` / `vndCompact` cho các màn hình và nội dung trợ lý.

## Thử card Liquid Glass mặc định — 2026-10-27

- **Yêu cầu:** Chỉ chỉnh layout bên trong card; thử vật liệu và bo góc mặc định của Apple.
- **Phạm vi thử:** Các card Tổng quan, gồm thẻ lớn, Pro/làm quen và các ô Số dư/Cho vay/Nợ, Tiền vào/Tiền ra.
- **Cách triển khai:** iOS 26 dùng `glassEffect()` không truyền shape, tint hay shadow. Apple mặc định dùng capsule, không có bán kính mặc định riêng cho “card” tự dựng. iOS cũ dùng regular material với capsule để tương thích.
- Bỏ nền màu và bo góc tự đặt trên các bề mặt card (bao gồm nền xanh của thẻ Pro trong bản thử). Giữ dữ liệu, font, màu chữ và layout nội dung. Button tiếp tục dùng glass native riêng.
- Đây là bản thử hình thức, chưa phải quyết định thay thế thiết kế Sleek vĩnh viễn.
- **Kiểm tra:** Build Simulator thành công; đã xem trên iPhone 17 Pro / iOS 26.3. Capsule mặc định khiến chữ ở góc của các card lớn sát/vượt vùng nền cong khi giữ layout cũ. Bản thử này chưa đạt chất lượng bố cục cuối; cần cân nhắc đổi padding/layout hoặc chọn hình chữ nhật bo góc nếu người dùng không muốn capsule.

## Card theo examples + Liquid Glass — 2026-10-27

- **Nguồn chuẩn mới:** HTML Tổng quan mẫu 1 trong `examples/`. File này khác ảnh cũ: Pro và Làm quen app là hai thẻ full-width xếp dọc.
- **Đã chốt:** Hình dáng/bo góc theo design, giữ hiệu ứng Liquid Glass native. Thay thế bản thử capsule mặc định.
- HTML dùng `corner-shape: squircle`, `--radius: 16px`, `rounded-2xl = 24px`, `rounded-xl = 20px` và hệ số 2.5 khi trình duyệt hỗ trợ squircle. SwiftUI dùng shape superellipse exponent 4 với các token này, truyền trực tiếp vào `glassEffect`; không dùng capsule cho card.
- Thẻ Pro dùng màu tối và CTA xanh như HTML; các ô Số dư/Cho vay/Nợ và Tiền vào/Tiền ra lấy màu theo design qua glass tint. Vật liệu kính có thể làm màu nhìn khác nền CSS đặc.
- Làm quen app hiển thị 3/4 dựa trên dữ liệu mẫu đang có ví, giao dịch và khoản cho vay. Badge +5 là nội dung giao diện theo mẫu, chưa có hệ thống cấp lượt AI. Nút Pro vẫn mở thông tin sắp ra mắt, không thanh toán.
- Đã build và xem trên iPhone 17 Pro / iOS 26.3; card không còn bị bo thành capsule lớn.

### Sửa độ mượt card và thẻ Pro — 2026-10-27

- **Phản hồi:** Góc card gợn, CTA nâng cấp nhỏ, thiếu chi tiết trang trí nền Pro.
- Thay đường viền squircle ghép đoạn thẳng bằng các cung Bézier cubic có tiếp tuyến liên tục. Giữ các token bo góc từ HTML và vật liệu glass native.
- Nút Nâng cấp ngay giữ full-width, tăng chiều cao label để đạt tỷ lệ gần `text-xs` + `py-2.5` của mẫu; chữ tối trên nền xanh, hiệu ứng nhấn vẫn do Apple xử lý.
- Thêm quầng xanh phía trên phải theo HTML: đường kính 144pt, độ mờ 25%, blur 40pt, lệch x +40 / y -40. Quầng nằm sau nội dung, được giới hạn trong góc card và không nhận thao tác chạm.
- Build Debug Simulator thành công; đã kiểm tra trực quan cả ba thay đổi trên iPhone 17 Pro / iOS 26.3.

### Thử bo góc continuous native — 2026-10-27

- Theo yêu cầu mới, bỏ hoàn toàn `SleekCardShape` và các đường path/Bézier tự dựng.
- Card lớn dùng `RoundedRectangle(cornerRadius: 24, style: .continuous)`; ô nhỏ dùng 20pt. Bán kính là giá trị trực tiếp, không nhân hệ số squircle CSS 2.5.
- Cả nền glass, vùng cắt quầng sáng Pro và nền biểu tượng dùng đường cong continuous của Apple, với bán kính tương ứng.
- Giữ Liquid Glass, bố cục, nội dung, nút và quầng sáng Pro hiện tại. Đây là bản thử để người dùng đánh giá đường bo native.

### Hiệu chỉnh token bo góc native theo mẫu — 2026-10-27

- Giữ `RoundedRectangle(..., style: .continuous)` để Apple xử lý đường cong mượt.
- Bản thử mới: `CardCorners.large = 32pt`, `inset = 28pt`, `icon = 12pt` cho nền icon 40pt. Thay thế bản thử 24/20pt; icon không còn thành hình tròn do radius bằng nửa chiều rộng.
- Đây là ánh xạ thị giác từ squircle CSS sang continuous iOS, không khẳng định hai hình học giống hệt nhau. Toàn bộ nền card và vùng cắt Pro dùng chung token để không lệch đường viền.
- Chỉ đổi token bo góc; giữ layout, font, màu, button và Liquid Glass.

## Quy tắc đang chốt tạm — 2026-10-27

- **Bo góc:** Người dùng đồng ý tạm giữ bản hiện tại. Dùng `RoundedRectangle` với `.continuous` native; `CardCorners.large = 32pt`, `inset = 28pt`, `icon = 12pt`. Dùng chung token cho nền và vùng cắt. Không quay lại path squircle tự vẽ hoặc capsule mặc định cho card.
- **Card:** Bố cục/màu tham chiếu HTML trong `examples`; giữ Liquid Glass native. Thẻ Pro giữ quầng sáng xanh trên phải.
- **Button:** Dùng Liquid Glass native, không tự tạo hiệu ứng nhấn. Màu, font, kích thước và hình dáng theo thiết kế; avatar/nút chuông cùng cỡ 44pt. Không tự thêm CTA ngoài mẫu.
- **Toàn app:** Manrope, light theme, ẩn thanh cuộn dọc. Giữ thanh tab mặc định iOS.
- **Tiền tệ:** `10.000.000đ`, `10,3tr`; đơn vị liền số, cùng font/cỡ/weight/baseline.
- **Icon — đang chọn:** Người dùng không hài lòng về thẩm mỹ SF Symbols và muốn xem bộ thay thế. Chưa chốt bộ mới, chưa thay icon. Thiết kế Sleek trong examples đang tham chiếu Solar Icons (linear/bold).

## Solar Icons được chọn — 2026-10-27

- Người dùng chốt dùng Solar, bao gồm toàn bộ icon tab bar. Thay các icon do app quản lý bằng Solar; các dấu hiệu của control hệ thống (back/search/picker) vẫn do iOS quản lý.
- Tab chưa chọn dùng Linear, tab đang chọn dùng Bold, vector 24pt: Tổng quan = home-2; Tài khoản = card; Giao dịch = transfer-horizontal; Trợ lý AI = magic-wand-2.
- Nội dung dùng Linear, riêng vương miện Pro dùng Bold theo mẫu. Cho vay dùng hand-money đúng thiết kế.
- Asset SVG được đóng gói offline, template rendering để nhận màu từ giao diện. Không đổi TabView/native button/Liquid Glass, bo góc, layout hay quy tắc font.
- Nguồn Solar / 480 Design từ Iconify, CC BY 4.0; ghi nhận tác giả và giấy phép trong `Timi/Resources/Solar-LICENSE.txt`.

## Rà soát font và màu Tổng quan — 2026-10-27

Nguồn đối chiếu: HTML trong `examples/tổng-quan---mẫu-1`, không ước lượng màu từ ảnh.

- **Font đã xác minh trên iOS Simulator:** SwiftUI `Font.resolve` trả về Manrope-Medium 12pt / trục wght 500; Manrope-SemiBold 24pt / 600; Manrope-ExtraBold 34pt / 800. Không có fallback về font hệ thống ở ba trường hợp này. Giữ các weight đúng HTML, không tăng đậm cảm tính.
- **Chiều cao dòng:** ngày và nhãn Tổng tài sản 16pt; lời chào 32pt; số tổng tài sản 42,5pt (HTML leading-tight). Trước đó dòng số tiền dùng metric tự nhiên của Manrope ~46,444pt. Quy tắc mới scale theo Dynamic Type trên iOS 26; iOS cũ dùng min-height và metric native.
- **Màu:** nền trang #FAFAF7 vốn đã đúng; card #FFFFFF; chữ chính #111827; phụ #6B7280; đỏ #DC2626. Các token light không phụ thuộc màu động của hệ thống.
- **Ba ô Số dư / Cho vay / Nợ:** cùng màu bg-muted/60, tức #F1F1EC ở alpha 60% trên trắng, thành khoảng #F7F7F4. Không dùng màu này như tint của regular glass vì làm ô tối hơn mẫu.
- **Giữ Liquid Glass:** card sáng/ô nhỏ dùng màu nền thật + native clear glass; card Pro và các button giữ cấu hình riêng. Giữ nguyên corner token 32/28/12.
- **Kiểm chứng ảnh Simulator (pixel sRGB thô, tránh chuyển profile thêm lần nữa):** nền trang (250,250,247); card trước (249,249,246), sau (255,255,255); ô nhỏ trước (237,237,232), sau (247,247,244), tại vùng nền không có chữ/viền.
- Dùng min-height 20pt cho số tiền trong ô nhỏ: exact line-height kết hợp minimumScaleFactor trên iOS gây co chữ ngoài ý muốn; đã kiểm tra và loại bỏ tổ hợp này.
- Build Debug iOS Simulator thành công, kiểm tra ảnh sau sửa tại `/tmp/Timi-preview/audit-after.png`. Đây là kiểm chứng token/font và màu vùng phẳng; không khẳng định mọi pixel của kính native giống CSS.


## Quy tắc mới nhất: Liquid Glass chỉ trên button — 2026-10-27

- Bỏ Liquid Glass khỏi toàn bộ card và ô thông tin bên trong, bao gồm card Pro. Quy tắc này thay thế các thử nghiệm giữ kính trên card ở trên.
- Card dùng nền màu đặc theo design, giữ đường cong continuous và token 32/28/12pt. Giữ phần trang trí quầng xanh trên card Pro.
- Button tiếp tục dùng Liquid Glass native của Apple. Tab bar vẫn là control mặc định iOS.
- Không đổi font, nội dung, kích thước hay bố cục trong lần chỉnh này.


## Shadow card và chữ nhỏ — 2026-10-27

- Sau khi bỏ kính, các card trắng bị thiếu shadow. Khôi phục bóng riêng cho mặt nền card theo tham chiếu HTML `0 2px 16px rgba(28,36,48,0.05)`; SwiftUI dùng radius 8pt, y 2pt, opacity 5%. Đây là ánh xạ blur giữa hai nền tảng, không cam kết đồng nhất pixel.
- Chỉ card trắng lớn dùng shadow; ô nhỏ không có bóng riêng, card Pro giữ nền tối/quầng xanh như HTML. Shadow áp trên shape nền, không áp lên chữ hoặc cả cây nội dung. Không đưa Liquid Glass trở lại card.
- Người dùng thấy chữ nhỏ nhạt hơn mẫu: đổi token chữ phụ Tổng quan từ #6B7280 sang #596171. Đây là điều chỉnh thị giác được yêu cầu, không phải mã màu gốc HTML. Tách token chữ khỏi màu tint control/viền.
- Mô tả nhỏ trên Pro tăng trắng từ 75% lên 85%. Giữ font weight, cỡ chữ, màu số tiền, nền và bo góc.

## Làm quen, tổng quan tháng và Cần chú ý — 2026-10-27

- Đổi tiêu đề thành **Làm quen với Timi**. Cả bốn nhiệm vụ là nội dung tĩnh, không còn Button, đổi tab hay mở sheet. Trạng thái vẫn phản ánh dữ liệu mẫu hiện có (3/4). Bỏ gạch ngang; nhiệm vụ xong dùng chữ xám và dấu check. Điểm +5 chỉ là hiển thị.
- Tổng quan tháng: header căn giữa theo trục dọc; nhãn thu/chi và hạn mức 11pt, giá trị thu/chi 16pt Bold; line box và khoảng cách 16/12/8pt theo HTML. Hai vùng màu giữ accent 30% trên trắng và muted đặc; không Liquid Glass.
- Hạn mức demo mặc định 30.000.000đ từ SampleData, chỉ khi chưa có giá trị lưu. Không ghi đè AppStorage của người dùng; giá trị 0 đã lưu vẫn là chưa đặt hạn mức. Phần trăm/tổng thu chi lấy dữ liệu app, không hard-code 63% hay số tiền trong mẫu. Sheet sửa hạn mức vẫn hoạt động.
- Cần chú ý: badge nền muted dạng capsule; hai dòng trả nợ/thu khoản vay, icon Solar calendar/user 20pt trong nền tròn 40pt; tiêu đề 14pt SemiBold, ngày hạn 11pt Regular, số tiền đầy đủ 14pt Bold. Divider #E5E5E0 lùi trái 52pt, cách mỗi hàng 12pt.
- Thêm PaymentReminder và hai fixture mẫu riêng trong SampleData (trả dư nợ mẫu thẻ sau 4 ngày; thu 5tr của Minh sau 8 ngày). Đây là lịch giả lập để xem design, không phải lịch ngân hàng thật, không gửi thông báo hay tự thay đổi số dư. Các dòng nhắc hiển thị tĩnh, chưa có màn chi tiết lịch nhắc.
- Giữ các quyết định trước: Manrope, Solar, màu chữ nhỏ tối hơn, shadow card, góc continuous; không kính trên card.

## Góc hai ô Tiền vào / Tiền ra — 2026-10-27

- Tham chiếu ảnh crop CleanShot 10.56.14 PM@2x do người dùng gửi. Ô mẫu khoảng 174 × 66,5pt; không dùng chung radius 28pt của ba ô tài sản cao hơn.
- Thêm `CardCorners.flow = 18pt` riêng cho hai ô thu/chi, vẫn là RoundedRectangle continuous native. So khớp silhouette native với vùng màu ảnh @2x: 18pt gần nhất trong dải 12–28pt (bước 0,5pt); đây là ánh xạ hình dáng, không phải sao chép radius CSS.
- Chỉ đổi góc hai ô này; giữ card lớn, ba ô tài sản, màu/font/padding, shadow và quy tắc không kính trên card.

## Làm lại Lịch thu chi — 2026-10-27

- Đối chiếu HTML hiện tại trong examples: tiêu đề và nút chọn tháng cùng hàng; bỏ hàng tháng riêng và hai nút mũi tên lớn.
- Nút tháng: Solar calendar 14pt + Manrope 12pt SemiBold + chevron 12pt, capsule; giữ native Liquid Glass cho control này theo quyết định trước. Menu có tháng trước/hiện tại/sau và chọn tháng theo năm.
- Lưới bắt đầu T2, 7 cột đều, gap 4pt, cách header 16pt. Tính đủ hàng với ô trống đầu/cuối tháng; chuyển tháng dựa ngày đầu tháng để tránh lỗi ngày 29–31.
- Ô ngày nền phẳng, continuous radius 8pt, padding 4pt, min-height 52pt (scale với Dynamic Type). Không kính/shadow riêng trên ô. Nút ngày dùng plain để giữ mặt ô theo design; chạm vẫn mở chi tiết giao dịch.
- Chữ thứ 10pt Medium, ngày 11pt Medium (hôm nay Bold); số tiền 9pt SemiBold, tabular, căn trái, thu #111827 và chi #DC2626. Không có thu/chi thì không vẽ dòng số tương ứng; không điền số tiền giả.
- Ngày hôm nay nền accent #C6F432 theo HTML hiện tại. Ba mức nền ngày khác: muted 40%, muted, muted-foreground 25%. HTML chỉ có ví dụ màu, chưa định nghĩa ngưỡng: tạm ánh xạ tổng thu+chi dưới 1tr / từ 1tr / từ 3tr; đây là lựa chọn triển khai để kiểm tra giao diện, không phải quy tắc được xác nhận bởi thiết kế.
- Build thành công; đã kiểm tra đổi tháng 10 → 9 → tháng hiện tại, mở ngày 18/10 đúng giao dịch Internet 220.000đ, ngày 31/10 hiển thị trạng thái trống. Kiểm tra ảnh toàn bộ lịch: `/tmp/Timi-preview/overview-calendar-redesign.png`.

## Cố định avatar và thông báo — 2026-10-27

- Tách hàng avatar/chuông khỏi nội dung cuộn và ghim bằng top safe-area inset của ScrollView.
- Hàng nút nằm dưới status bar/Dynamic Island, giữ nút tròn 44pt và Liquid Glass; nền đặc #FAFAF7 phủ cả safe area trên để nội dung không đè lên nút hay giờ hệ thống.
- Ngày, lời chào và toàn bộ card vẫn cuộn bình thường. Giữ khoảng cách ban đầu: top 12pt, lề ngang 20pt, cách lời chào 16pt.
- Build thành công, đã kiểm tra khi cuộn xuống: hàng avatar/thông báo vẫn giữ nguyên phía trên. Ảnh `/tmp/Timi-preview/overview-pinned-header.png`.

## Chuyển tiếp mờ dưới header cố định — 2026-10-27

- Thêm dải material mỏng cao 24pt ở mép dưới vùng avatar/chuông, mask gradient tan dần vào nội dung.
- Opacity tăng từ 0 đến 1 theo 24pt cuộn đầu tiên; trở về đầu trang thì ẩn. Lấy vị trí từ nội dung ScrollView để hỗ trợ cả iOS 17.6.
- Dải mờ là overlay, không chiếm chiều cao, không nhận chạm và không thêm kính vào các card. Respect Reduce Transparency bằng gradient màu nền.
- Build thành công và kiểm tra trên Simulator; ảnh `/tmp/Timi-preview/overview-header-fade.png`.

## Mờ toàn bộ nền header — 2026-10-27

- Thay thử nghiệm dải mờ riêng 24pt bằng một lớp ultraThinMaterial liền mạch phía sau toàn bộ hàng avatar/chuông và status bar khi cuộn.
- Nền không còn là mảng màu đặc khi đã cuộn; nội dung phía dưới xuyên nhẹ qua blur. Mép dưới tan dần thêm 32pt, không có đường nối giữa nền header và dải chuyển tiếp.
- Hai button luôn sắc nét, cố định và giữ native Liquid Glass. Ở đầu trang trở về nền trang; Reduce Transparency dùng nền đặc. Card vẫn không có kính.
- Build thành công, đã xác nhận trên Simulator: `/tmp/Timi-preview/overview-full-header-blur.png`.

## Header dùng hiệu ứng native iOS — 2026-10-27

- Người dùng muốn độ mờ như các trang native chưa chỉnh, không thích blur toàn header quá mạnh. Bỏ toàn bộ material/gradient/mask tự tạo, theo dõi offset và safe-area header cũ.
- Chuyển avatar/chuông vào ToolbarItem leading/trailing của navigation bar inline. Để iOS quản lý scroll-edge backdrop mặc định giống các NavigationStack khác; không đặt opacity, blur radius hoặc toolbar background riêng.
- Giữ hai nút tròn 44pt bằng nativeCircleButton. Trên iOS 26, ẩn shared background của từng toolbar item để tránh lớp kính chồng và avatar chữ Q bị native toolbar kéo thành capsule. Nền scroll-edge của navigation bar vẫn do hệ thống quản lý.
- Greeting và card tiếp tục cuộn; card vẫn không kính. Build thành công và kiểm tra hình tròn/hiệu ứng khi cuộn tại `/tmp/Timi-preview/overview-native-header.png`.

## Màn Tài khoản theo Sleek — 2026-10-27

- **Nguồn chuẩn:** HTML `examples/tài-khoản`. Bố cục: tiêu đề "Tài khoản" 24pt SemiBold và nút + tròn 44pt cùng hàng trên toolbar native (Liquid Glass), thẻ Tổng số dư, mục Tài khoản thanh toán và Mục tiêu tiết kiệm.
- **Quyết định dữ liệu (người dùng chọn):** thêm model `SavingsGoal` và 3 hũ mẫu từ Sleek (Hũ tiết kiệm 28/40tr, Mua xe 15/50tr, Du lịch Đà Nẵng 8/20tr). Bỏ "Sổ tiết kiệm 12 tháng" và loại tài khoản Tiết kiệm; hũ thay thế. Thẻ tín dụng không hiện ở màn Tài khoản, để dành cho màn Vay nợ; vẫn tính vào Nợ ở Tổng quan.
- **Số liệu:** Tổng số dư = tài khoản thanh toán (tiền mặt, ngân hàng, ví) + tiền trong hũ. Tổng tài sản/Số dư ở Tổng quan cũng cộng tiền trong hũ để Số dư + Cho vay − Nợ = Tổng tài sản. Mỗi dòng thanh toán là một tài khoản riêng (VD: Ví tiền mặt, Vietcombank, MoMo), xếp theo tiền mặt → ngân hàng → ví; "Cập nhật …" lấy từ giao dịch gần nhất của tài khoản đó.
- **Tương tác:** dòng tài khoản → thẳng chi tiết tài khoản (màn chi tiết vẫn kiểu List cũ); không còn màn danh sách theo nhóm. Thẻ hũ → sheet sửa/xoá hũ. Nút + mở menu Thêm tài khoản (chỉ loại thanh toán) / Thêm hũ tiết kiệm.
- **Thiết kế:** dòng dữ liệu icon tròn 44pt nền muted, divider lùi 72pt; thẻ hũ có viền #E5E5E0 + shadow, thanh tiến độ 10pt màu accent. Card dùng token bo góc 32pt, không kính. Tiền dùng `đ` thay cho `₫` của mẫu.
- **Icon mới:** Solar banknote-2, buildings-2, smartphone, add-circle; icon hũ là Material Design Icons (piggy-bank, car-outline, airplane) theo mẫu — giấy phép Apache 2.0 tại `Timi/Resources/MDI-LICENSE.txt`.
- **Màu dùng chung:** token màu chuyển từ `OverviewStyle` sang `Palette` (Shared/Palette.swift), giá trị không đổi.
- **Kiểm tra:** Build Debug thành công; đã xem trên iPhone 17 Pro / iOS 26.3: bố cục, cuộn, mở nhóm Ngân hàng → Vietcombank, sửa hũ (28tr → 30tr, 75%), thêm tài khoản VPBank. Chưa kiểm tra iOS 17.6 và cỡ chữ trợ năng lớn.

### Đơn giản hoá tài khoản thanh toán và font số tiền hũ — 2026-10-28

- **Yêu cầu:** Hiện từng tài khoản (Tiền mặt, ngân hàng A, ví B) ngay ở màn Tài khoản, không cần vào màn nhóm trung gian. Đã bỏ `AccountGroupView`; chạm dòng mở thẳng chi tiết tài khoản.
- **Design cập nhật:** số tiền trong thẻ hũ đổi từ 18pt ExtraBold sang `text-sm font-bold` = 14pt Bold, cách mũi tên 12pt (`gap-3`), giống số tiền ở dòng tài khoản.
- Build thành công; đã xem trên iPhone 17 Pro / iOS 26.3: 4 dòng Ví tiền mặt / Vietcombank / Techcombank / MoMo, chạm Vietcombank mở chi tiết.

### Tiêu đề ngang hàng nút + — 2026-10-28

- **Phản hồi:** Tiêu đề "Tài khoản" phải nằm cùng hàng với nút +, như HTML (`flex justify-between` chứa h1 và nút).
- Chuyển tiêu đề vào `ToolbarItem(.topBarLeading)`, ẩn shared background trên iOS 26 để chữ không bị bọc kính; nút + vẫn ở trailing. Giữ Manrope 24pt SemiBold.
- Vì nằm trên navigation bar native, tiêu đề cố định khi cuộn và nội dung đi dưới lớp scroll-edge của iOS (giống avatar/chuông ở Tổng quan). Trong HTML tiêu đề cuộn cùng nội dung; đây là khác biệt có chủ đích theo quy tắc dùng toolbar native.
- Build thành công; đã xem trên iPhone 17 Pro / iOS 26.3 ở đầu trang và khi cuộn.

### Rà soát cuối màn Tài khoản — 2026-10-28

- **Cách đối chiếu:** render HTML ở 402pt (bằng iPhone 17 Pro), đo bằng `getBoundingClientRect` và so với ảnh Simulator cùng chiều rộng.
- **Đã sửa:** divider giữa các dòng vẽ đè (overlay) như `absolute` trong HTML, không cộng 1pt vào chiều cao — mỗi dòng 76pt. Thẻ hũ padding 21pt (p-5 + viền 1pt nằm trong hộp CSS). Thêm line-height theo HTML: dòng "Gồm … hũ" và chân thẻ hũ 16,5pt, tiêu đề mục 24pt. Khoảng cách tối thiểu chữ ↔ số tiền ở dòng tài khoản 12pt (`gap-3`), thay cho Spacer cũ (≥32pt).
- **Kết quả đo:** thẻ Tổng số dư ~127pt (HTML 127), 4 dòng thanh toán ~304pt (76/dòng), thẻ hũ ~138,5pt (HTML 140,5; trong sai số đo ảnh ±2pt), khoảng cách thẻ hũ 12pt.
- **Khác biệt có chủ đích (giữ nguyên):** `đ` liền số thay `₫`; chữ phụ #596171 (token đã duyệt) thay #6B7280; nút + là Liquid Glass native; tiêu đề cố định trên toolbar khi cuộn; thanh tab mặc định iOS và bộ 4 tab hiện tại; dữ liệu thật của app thay số mẫu.
- **Trạng thái:** Màn Tài khoản hoàn tất theo design. Màn chi tiết tài khoản vẫn kiểu List cũ, ngoài phạm vi màn này.

## Màn Giao dịch theo Sleek — 2026-10-28

- **Nguồn chuẩn:** HTML `examples/giao-dịch---thu-chi` và `examples/giao-dịch---vay-nợ`. Một màn, hai tab chuyển bằng segmented control native (font Manrope qua UIAppearance).
- **Khung chung:** tiêu đề "Giao dịch" 24pt SemiBold và nút tìm kiếm tròn 44pt cùng hàng trên toolbar native (giống màn Tài khoản). Nút tìm mở ô tìm kiếm native của iOS; huỷ thì ô biến mất và xoá từ khoá. Nút + nổi 56pt dùng `glassProminent` tint xanh chanh; tab Thu chi mở form thêm giao dịch, tab Vay nợ mở form thêm khoản vay.
- **Thu chi:** thẻ tổng hợp tháng (rounded-3xl → token `extraLarge = 40pt`) gồm nút chọn tháng (menu native như Tổng quan), Đã chi/Đã thu kèm số giao dịch, biểu đồ cột chi tiêu theo ngày của tháng (hôm nay màu accent, ngày tương lai muted), và hạn mức tổng dùng chung giá trị hạn mức của Tổng quan (xanh khi trong hạn mức, đỏ + "vượt …" khi vượt). Danh sách nhóm theo ngày ("Hôm nay, 28/10", "Thứ Hai, 12/5"), tổng ngày bên phải; dòng giao dịch icon tròn 44pt, thu nền accent, chi nền muted, số chi màu đỏ. Giữ ngón tay trên dòng để xoá.
- **Chip lọc:** Tất cả / Thu / Chi / Chuyển khoản là button Liquid Glass native; chip đang chọn dùng glass prominent màu ink. Người dùng chọn **giữ chip Chuyển khoản** dù app chưa có chuyển khoản: chọn sẽ hiện thẻ trống "Chưa có giao dịch chuyển khoản".
- **Vay nợ — dữ liệu (người dùng chọn mở rộng model):** `LoanReceivable` thay bằng `Loan` (cho vay/đi vay, số gốc, còn lại, hạn trả, đã tất toán). Mẫu theo Sleek: Minh 75tr còn 45tr (đã trả 40%), Hùng 35tr chưa trả; tổng cho vay giữ 80tr. Thẻ tín dụng hiện ở mục Đi vay với dư nợ thật, thanh tiến độ là % hạn mức đã dùng (thêm `creditLimit`, `paymentDueDate` cho Account). Khoản đi vay tính vào Nợ và tài sản ròng.
- **Vay nợ — giao diện:** thẻ "Tổng cho vay trừ nợ" + hai ô Đang cho vay (accent/30) / Đang nợ (muted), chip lọc Tất cả / Cho vay / Đi vay / Đã tất toán, mục Cần chú ý (thẻ viền không shadow), thẻ khoản vay có thanh tiến độ. Ảnh đại diện mẫu từ internet thay bằng **chữ cái đầu** trong vòng tròn 44pt (người dùng chọn). Chạm thẻ khoản vay mở form sửa / đánh dấu tất toán / xoá.
- **Icon mới:** Solar cup-hot, bag-3, wallet-money, magnifer; Material Symbols add-rounded cho nút + (Apache 2.0, `Timi/Resources/MaterialSymbols-LICENSE.txt`). Danh mục Ăn uống, Mua sắm, Lương đổi sang icon theo design. Bỏ các icon không còn dùng.
- **Thành phần dùng chung mới** (`Shared/SleekComponents.swift`): RowDivider, ProgressBar, IconCircle, InitialsAvatar, SectionHeader, ChipRow, EmptyStateCard, `sleekCard()`. Màn Tài khoản chuyển sang dùng các thành phần này, giao diện không đổi.
- **Lỗi đã sửa khi kiểm tra:** (1) `.searchable` luôn hiện ô tìm kiếm dưới tiêu đề, lệch design → chỉ gắn khi bấm nút tìm. (2) ScrollView ngang sau chip glass vẽ một dải nền sáng → chỉ cuộn khi chip tràn (`ViewThatFits`), nhóm chip bằng `GlassEffectContainer`. (3) Số Đã chi/Đã thu bị co nhỏ ở lần vẽ đầu do line-height cố định + minimumScaleFactor → dùng min-height 32pt.
- **Đo so với HTML ở 402pt:** segmented ~46pt (HTML 48), thẻ tổng hợp ~324pt (329,5), dòng giao dịch 76pt (76), chip ~30pt (34, kích thước control native), nút tháng ~32pt (36).
- **Khác biệt có chủ đích:** `đ` thay `₫`; segmented, chip, nút tháng, nút + là control native nên chiều cao do iOS quyết định; tiêu đề cố định trên toolbar; thanh tab mặc định iOS (design dùng bộ tab Thống kê/Tôi, chưa áp dụng); số liệu lấy từ dữ liệu app.
- **Đã kiểm tra trên iPhone 17 Pro / iOS 26.3:** hai tab, cuộn, chip Chuyển khoản trống, nút tìm, thêm khoản đi vay 10tr (mục Đi vay 6,4tr → 16,4tr; tổng cho vay trừ nợ 73,57tr → 63,57tr). Chưa kiểm tra iOS 17.6, cỡ chữ trợ năng lớn, form sửa khoản vay và đổi tháng.

## Màn Trợ lý AI theo Sleek — 2026-10-28

- **Nguồn chuẩn:** HTML `examples/trợ-lý-ai-timi`.
- **Đầu trang:** "Timi" 24pt SemiBold + dòng phụ 12pt trên toolbar native, cùng hàng nút đồng hồ 44pt (Liquid Glass). Dòng phụ là **"Trợ lý tài chính · Bản thử nghiệm"** thay "Còn 12 lượt AI" vì app chưa có hệ thống lượt (người dùng chọn).
- **Lịch sử (người dùng chọn):** nút đồng hồ mở menu native: "Cuộc trò chuyện mới" + mục "Trước đó" liệt kê các cuộc trò chuyện trong phiên (tiêu đề = câu hỏi đầu, kèm giờ). Chưa lưu khi tắt app, giống dữ liệu khác.
- **Tin nhắn:** chip ngày ("Hôm nay, 28/10") nền muted; avatar Timi tròn 32pt nền accent, icon Solar stars-minimalistic-bold. Bong bóng trợ lý nền trắng + shadow card, bong bóng người dùng nền ink chữ trắng; rộng tối đa 78%; góc 24pt với góc "đuôi" 8pt (rounded-2xl + rounded-tl/tr-md). Gợi ý dưới lời chào dạng chip glass xuống dòng như flex-wrap.
- **Ghi / xoá giao dịch bằng chat (người dùng chọn làm thật bằng quy tắc):** MockAssistant nhận "ghi …" / "thêm …" (tách số tiền 60.000, 60k, 1,5tr, 2 triệu; ngày hôm nay/hôm qua/hôm kia; đoán danh mục theo từ khoá; tên lấy từ câu sau khi bỏ từ lệnh) và ghi ngay vào tài khoản thanh toán đầu tiên, hiện thẻ giao dịch + nút Sửa (mở form sửa giao dịch) / Xoá. "xoá …" / "huỷ …" tìm giao dịch khớp tên + ngày, **luôn hỏi xác nhận** (Huỷ / Xoá khoản này) trước khi xoá; sau khi xử lý thẻ hiện trạng thái. Thêm câu trả lời "Ai đang nợ tôi?" từ dữ liệu vay nợ. Chưa phải AI thật: chỉ hiểu các mẫu câu phổ biến.
- **Ô nhập:** capsule nền input #F3F3EF, micro bên trái, nút gửi tròn 40pt glass prominent màu ink. Thanh ô nhập nền đặc màu trang, không blur tự dựng. **Micro nhập giọng nói thật (người dùng chọn):** `SFSpeechRecognizer` vi-VN, chữ hiện dần vào ô; lần đầu hỏi quyền micro và nhận dạng giọng nói (đã thêm hai chuỗi mô tả quyền vào build settings). Lỗi quyền/không khả dụng hiện alert.
- **Store / form:** thêm `FinanceStore.update(_:)` (sửa giao dịch, cập nhật lại số dư cả tài khoản cũ và mới), `transaction(id:)`; `delete` bỏ qua giao dịch đã xoá để không trừ số dư hai lần. AddTransactionView nhận `editing:` để dùng làm form sửa.
- **Icon mới:** Solar stars-minimalistic-bold, clock-circle, microphone-3, pen, trash-bin-minimalistic. Bỏ magic-wand-2-linear (không còn dùng).
- **Đã kiểm tra trên iPhone 17 Pro / iOS 26.3:** bố cục đầu trang/lời chào/gợi ý/ô nhập; "Ghi giúp mình: ăn trưa 60.000 hôm nay" → thẻ Ăn trưa · Ăn uống · Hôm nay · -60.000đ vào Ví tiền mặt; "Xoá khoản tiền điện" → thẻ xác nhận Tiền điện 742.000đ (23/10), bấm Xoá khoản này → đã xoá; menu lịch sử + cuộc trò chuyện mới.
- **Chưa kiểm tra:** nhập giọng nói (Simulator cần cấp quyền micro trên hộp thoại hệ thống, nên thử trên iPhone thật), nút Sửa trên thẻ chat, iOS 17.6, cỡ chữ lớn.
- **Khác biệt có chủ đích:** `đ` thay `₫`; thanh tab mặc định iOS với 4 tab hiện tại (design đặt tab "Timi"); nút/gợi ý là control native.

## Design system — 2026-10-28 (chờ người dùng duyệt)

- **Nguồn tham khảo:** design system của bản web (`finance-tracker-v2/docs/design`, route `/design`): thang chữ, khoảng cách bội 4, chiều cao điều khiển, quy tắc form/sheet/nút. Màu giữ bộ Sleek đã duyệt cho iOS (không lấy bộ xám của web). Thứ iOS có sẵn (nút Liquid Glass, segmented, switch, menu, date picker, sheet) giữ native; chỉ chuẩn hoá màu, cỡ chữ, chiều cao và khung xung quanh.
- **Truy cập:** chạm avatar "Q" ở Tổng quan → màn **Thư viện UI** (`Features/DesignSystem/DesignSystemView.swift`), 9 nhóm với mẫu chạm thử, hàng chip mục lục cố định dưới thanh điều hướng.
- **Token** (`Shared/DesignSystem/DesignTokens.swift`):
  - `TextRole` + `.textRole(_:)`: display 34 ExtraBold · hero 40 Bold · amountLarge 24 ExtraBold · pageTitle 24 SemiBold · title 16 SemiBold · body 14 · label 14 Medium · bodyStrong 14 SemiBold · amount 14 Bold · caption 12 · captionStrong 12 Medium · footnote 11 · overline 11 Medium in hoa giãn chữ · input 16 (để iOS không phóng to). Kèm line-height theo design và chữ số đều cho số tiền.
  - `Spacing`: 2/4/8/12/16/20/24/32; lề màn 20, giữa các phần 20, đệm thẻ 20.
  - `ControlHeight`: nút 36/44/56, ô nhập 44, dòng 52, nút nổi 56.
  - `Palette` thêm `fill1/2/3` (mực 4/6/10%, như systemFill và `--fill-*` của web). `CardCorners` thêm `field` 14, `sheet` 32.
- **Nút** (`TimiButton`): vai trò Chính (mực) / Phụ / Nổi bật (chanh) / Xoá (đỏ nhạt, cạnh Lưu) / Xoá vĩnh viễn (đỏ đặc); cỡ 36/44/56; icon Solar 18. Là Liquid Glass native. Glass tự đệm 7pt trên dưới, nên nhãn đặt cao = token − 14 để cả nút đúng 36/44/56 (đo trên iOS 26.3: nhãn 14pt cho nút 34pt). Nút tắt để iOS tự làm xám, không thêm độ mờ riêng.
- **Form thay cho `Form` mặc định** (`TimiForms.swift`, theo yêu cầu "form mặc định nhìn chán"):
  - `TimiTextField`: nhãn trên, ô 44 bo 14 nền mực 4%; khi nhập nền trắng + viền mực 2pt; lỗi viền đỏ + chữ đỏ dưới ô; chú thích xám; nút xoá khi có chữ.
  - `TimiAmountField`: số tiền 40 Bold ở giữa (co 40 → 30 → 22 khi dài), dấu +/− và "đ" mờ; nút xoá ở mép phải; chip gợi ý theo số đã gõ (3 → 3.000đ, 30.000đ, 300.000đ), chọn chip thì hàng đứng yên và chip được tô.
  - `FormGroup` (thẻ trắng bo 28, tiêu đề nhóm in hoa, chú thích dưới) với các dòng `FormPickerRow` (menu native), `FormDateRow` (date picker native), `FormToggleRow` (switch native màu mực), `FormNavigationRow`, `FormDestructiveRow`; `FormDivider` lùi theo icon 36.
- **Sheet** (`TimiSheets.swift`): `.timiSheetStyle(detents)` = nền trang, thanh kéo, bo 32 trên sheet native. `SheetScaffold`: ✕ (role close của iOS 26) trái, tiêu đề giữa, nội dung cuộn, chân ghim (`SheetSaveFooter`: Xoá 120 + Lưu giãn hết). `OptionSheet`: sheet ngắn "Thêm mới", chọn xong tự đóng.
- **Phản hồi & dữ liệu** (`TimiFeedback.swift`): `StatusBadge` (viên 24 có chấm; trung tính / đã thu / Pro / thông tin / cảnh báo), `MoneyText` (mọi số tiền: dấu, màu theo ý nghĩa, cỡ dòng/lớn/dẫn đầu), `ListRow` (dòng dữ liệu dùng chung; màn Tài khoản đã chuyển sang, giao diện không đổi).
- **Sửa kèm:** hàng chip cuộn ngang tắt dải scroll-edge của iOS 26 (dải sáng sau chip khi cuộn).
- **Chưa làm (chờ duyệt rồi mới áp):** chưa chuyển AddTransaction/AddAccount/GoalEditor/LoanEditor và các màn sang token/thành phần mới; chip mục lục chưa tự đổi theo vị trí cuộn (chỉ đổi khi chạm). Đã xem trên iPhone 17 Pro / iOS 26.3: Nền tảng, Nút, Lựa chọn, Ô nhập (đang nhập, lỗi, gợi ý số tiền), sheet ngắn và sheet form.

### Góp ý vòng 1 cho design system — 2026-10-28

- **Nút chính đen hoàn toàn:** thêm token `Palette.primary = #000000` cho mặt đặc của hành động chính: nút Chính, chip đang chọn, chip gợi ý số tiền đang chọn, nút gửi chat, công tắc bật. `Palette.ink` (#111827) vẫn là màu chữ và icon.
- **Form gọn hơn** (người dùng thấy control Apple trong form quá to):
  - Dòng form cao 48 (trước 52), chữ tiêu đề 14 Regular (trước SemiBold), icon 16 trong ô vuông bo 8 cỡ 28 (trước vòng tròn 36); vạch kẻ lùi theo ô 28.
  - Công tắc: bỏ switch hệ thống (63×28 trên iOS 26) thay bằng `TimiSwitchStyle` 40×24, rãnh đen khi bật / mực 10% khi tắt, núm trắng có bóng nhẹ, lò xo 0,3s, rung nhẹ khi đổi; giữ vai trò toggle cho VoiceOver.
  - Ngày: thay ô DatePicker compact của Apple (chữ to, "ngày 28 thg 10, 2026") bằng viên 32pt nền mực 6% ghi "Hôm nay" / "Hôm qua" / "25/10/2026" chữ 14; chạm mở lịch graphical của Apple trong popover, ngày chọn tô đen.
  - Sheet ngắn dùng cùng ô icon 28 và chữ 14.
- **Đóng bàn phím khi chạm ra ngoài:** `.dismissesKeyboardOnTap()` (chạm vào chỗ trống thì resign first responder, kéo nội dung thì bàn phím trượt xuống). Áp cho `SheetScaffold` (mọi sheet form) và màn Thư viện UI. Ô nhập, nút, menu bên trong vẫn nhận chạm như cũ.
- **Thanh tiến độ một cỡ:** `ProgressBar` cố định 8pt (`ProgressBar.height`), bỏ tham số height; hũ tiết kiệm từ 10 → 8pt. Các thanh tự vẽ ở Tổng quan vốn đã 8pt.
- Đã kiểm tra trên iPhone 17 Pro / iOS 26.3: nút đen, dòng form mới, công tắc, chọn ngày 25/10 qua popover, gõ vào ô rồi chạm ra ngoài thì ô thoát nhập.

### Góp ý vòng 2 cho design system — 2026-10-28

- **Chữ dày như web:** Manrope vẽ mảnh, nên giống web (`font-normal` 500, `medium` 600, `semibold` 700, `bold` 800) mọi độ đậm trên iOS giờ hiển thị nặng hơn một bậc: Regular → Medium, Medium → SemiBold, SemiBold → Bold, Bold/Heavy → ExtraBold. Đổi tập trung ở `Typography.instance(for:)`, áp cho toàn app (cả thanh tab, segmented, tiêu đề thanh điều hướng). Code vẫn ghi độ đậm theo ý nghĩa; chỉ hàm này biết phép dịch. Thay thế ghi chú cũ "giữ các weight đúng HTML, không tăng đậm cảm tính" trong mục Rà soát font Tổng quan.
- **"đ" ở số tiền lớn:** `TimiAmountField` viết "đ" liền sau số (khoảng cách 0), cùng màu, cỡ, độ đậm với số (bỏ độ mờ 40%). Khi ô trống, "đ" xám theo chữ gợi ý "0".
- **Dòng form theo `SettingsRow` của web:** ô icon `IconTile sm` 36×36 bo 10 nền mực 4% (`fill1`), icon 18; khoảng cách icon → chữ 14; đệm dọc 14, ngang 16 → dòng một hàng cao 64. Tiêu đề dòng 14 vai trò `label` (Medium, hiển thị SemiBold), mô tả 12. Sheet ngắn dùng cùng kích thước.
- **Công tắc:** bỏ công tắc tự vẽ 40×24; dùng lại `Toggle` của Apple, rãnh đen khi bật. Trên iOS 26 núm công tắc thành Liquid Glass khi chạm/kéo (đã thấy trên Simulator).
- Đã kiểm tra trên iPhone 17 Pro / iOS 26.3: chữ toàn app đậm hơn (Tổng quan, Thư viện UI), dòng form 64 với ô icon 36, công tắc Liquid Glass khi kéo, "-60.000đ" liền và cùng màu đỏ.

### Góp ý vòng 3 cho design system — 2026-10-28

- **Nền icon trong form = nền icon trong list:** ô icon của dòng form và sheet ngắn dùng `Palette.muted` (#F1F1EC) như vòng tròn icon ở `ListRow`, thay `fill1` (mực 4%) nhạt hơn. Ô chanh của Hũ tiết kiệm giữ nguyên.
- **Kiểu không nền icon (để so sánh):** `.formIconStyle(.plain)` bỏ nền sau icon trong mọi dòng form và `ListRow` bên trong; icon 20 (form) / 22 (list) đứng riêng như Cài đặt iOS, vạch kẻ lùi theo cột icon hẹp hơn. Thư viện UI đặt hai kiểu cạnh nhau ở mục Lựa chọn và Danh sách. **Chờ người dùng chọn một kiểu làm mặc định.**
- **Ô nhập kiểu iOS (`FormTextRow`, `FormNoteRow`):** các ô chung một thẻ trắng như Danh bạ / Cài đặt iOS: nhãn bên trái, giá trị gõ bên phải canh phải, chữ gợi ý xám ("Bắt buộc", "Không bắt buộc"), nút xoá khi đang nhập; có thể kèm ô icon; ghi chú nhiều dòng chiếm cả dòng. Là phương án thay/đi cùng `TimiTextField` (nhãn trên, ô riêng). **Chờ người dùng chọn.**
- **Sheet ngắn tràn mép (`.timiBottomSheet`):** iOS 26 cho sheet native chiều cao thấp nổi lơ lửng cách hai mép, nên sheet ngắn giờ tự dựng: trượt từ đáy, rộng hết màn, chạm đáy (nền kéo xuống dưới thanh home), bo 32 hai góc trên, thanh kéo, nền tối 30%. Chạm ra ngoài hoặc kéo xuống để đóng; chọn một dòng thì trượt xuống rồi mới gọi hành động. Cao vừa nội dung. Giảm chuyển động: hiện ra 150ms không nảy. Sheet form (✕, Lưu ở chân) vẫn là sheet native toàn chiều cao.
- Đã kiểm tra trên iPhone 17 Pro / iOS 26.3: hai kiểu icon ở form và list, card ô nhập kiểu iOS, sheet ngắn mở / kéo xuống đóng / mở lại / chọn "Ngân hàng".

### Góp ý vòng 4 cho design system — 2026-10-28 (người dùng đã chọn)

- **Cỡ chữ theo chuẩn iOS** (tham chiếu ảnh Cài đặt của app Claude iOS, chữ cân với công tắc native): thang `TextRole` chuyển sang mặc định Dynamic Type của iOS — nội dung / tiêu đề dòng / nhãn / số tiền dòng / tiêu đề nhóm / chữ trong ô **17** (line 22), chú thích / nhãn nhỏ / nhãn nhóm in hoa **13** (line 18), chữ phụ **12** (line 16). Giữ: số dẫn đầu 34, số đang nhập 40, số lớn trong thẻ 24, tên màn 24. Text style đi theo (body / footnote / caption) nên vẫn co giãn với cỡ chữ hệ thống. Chữ tiêu đề dòng form dùng độ đậm thường như iOS (hiển thị Medium vì Manrope lệch một bậc).
- **Dòng form/list:** cao ~52 (đệm dọc 12) như dòng Cài đặt iOS với chữ 17.
- **Không nền icon là mặc định** cho mọi dòng form, sheet ngắn và `ListRow` (kể cả icon chanh của khoản thu, ô chanh của Hũ tiết kiệm trong sheet ngắn); icon Solar 22 trong cột 24, vạch kẻ lùi theo cột đó. Thẻ hũ ở màn Tài khoản cũng bỏ vòng tròn nền. `.formIconStyle(.tile)` vẫn còn nếu cần ô nền ở chỗ riêng.
- **Ô nhập kiểu iOS là mặc định** (`FormTextRow`): nhãn trái, giá trị phải, chung một thẻ; **không kèm icon** — icon chỉ dùng cho dòng chọn / mở trang, ở ô nhập nó lặp lại điều nhãn đã nói, và trong một nhóm thì hoặc mọi dòng có icon hoặc không dòng nào có (để chữ thẳng hàng). `TimiTextField` (nhãn trên ô) giữ làm phương án khác cho form chỉ có một hai ô.
- Thư viện UI bỏ các mẫu so sánh, chỉ còn kiểu đã chọn; sheet form mẫu "Thêm tài khoản" dùng ô nhập iOS, không icon.
- Đã kiểm tra trên iPhone 17 Pro / iOS 26.3: Thư viện UI (dòng form 17pt với công tắc, ô nhập iOS, danh sách), sheet form, màn Tài khoản (danh sách và thẻ hũ không nền icon).

### Rà soát đồng bộ chữ, chiều cao hàng và khoảng cách — 2026-10-28

**Lỗi tìm thấy:** ~10 chỗ gõ cứng cỡ chữ ngoài thang (tiêu đề mục 16, trạng thái trống 14/12, chip 12, nút 14/16, avatar chữ 16, tiêu đề catalog 28/20, thẻ hũ 16/14/11); hàng danh sách đệm 16 + icon cao 44 (~76) trong khi hàng form ~44–57 tuỳ thứ bên phải; `minHeight` của hàng form đặt trước padding nên không có tác dụng; phụ đề danh sách 12 còn form 13; khoảng icon → chữ 12 (list) và 14 (form) nên vạch kẻ lệch nhau; tên và số tiền danh sách hiển thị Bold/ExtraBold.

**Thang chữ duy nhất (`TextRole`, mọi thành phần dùng nó):**

| Vai trò | Cỡ / dòng | Độ đậm (hiển thị) | Dùng cho |
|---|---|---|---|
| display | 34 | ExtraBold | Số dẫn đầu màn |
| hero | 40 | Bold (ExtraBold) | Số tiền đang nhập |
| amountLarge | 24 | ExtraBold | Số lớn trong thẻ |
| pageTitle | 24 / 32 | SemiBold (Bold) | Tên màn |
| heading | 20 / 26 | SemiBold (Bold) | Tiêu đề phần |
| title | 17 / 22 | SemiBold (Bold) | Tiêu đề thẻ, nhóm, sheet, trạng thái trống; nhãn nút |
| body | 17 / 22 | Regular (Medium) | Tên dòng, giá trị, nội dung, ô nhập |
| amount | 17 / 22 | Medium (SemiBold) | Số tiền cuối dòng |
| label | 17 / 22 | Medium (SemiBold) | Nhãn ô nhập kiểu nhãn-trên |
| caption | 13 / 18 | Regular (Medium) | Phụ đề dòng, chú thích, lỗi, mô tả phần |
| captionStrong | 13 / 18 | Medium (SemiBold) | Chip, badge |
| overline | 13 / 18 | Medium, in hoa | Nhãn nhóm dòng |
| footnote | 12 / 16 | Regular | Trục biểu đồ, chữ rất nhỏ |

Nút: 17 SemiBold ở cỡ 44/56, 15 ở cỡ 36. Chỉ còn hai chỗ đặt cỡ trực tiếp có lý do: cỡ chữ nút theo cỡ nút, ô số tiền lớn co 40 → 30 → 22.

**Một bộ số đo hàng (`RowMetrics`) cho form, danh sách, sheet ngắn, thẻ hũ:** lề 16, đệm dọc ≥ 10, icon 22 trong cột 24, icon → chữ 14, tên → phụ đề 2, vạch kẻ lùi 54. Hàng một dòng **đúng 52** dù bên phải là chữ, viên ngày (30) hay công tắc (31); hàng có phụ đề **~62**. Đo trên Simulator: 52 / 52 / 63 / 52 / 52 (form), 62 (list).

**Danh sách nhẹ hơn:** tên dòng `body` (không đậm), số tiền `amount` (17 Medium), phụ đề `caption` 13 — cùng kiểu chữ với hàng form.

**Khoảng cách (bội 4):** lề màn 20; giữa các phần 32; tiêu đề phần → mô tả 4, → mẫu đầu 16; các thẻ trong phần cách 16; đệm thẻ 20, nhãn thẻ → nội dung 12; nhãn nhóm → thẻ 8, thẻ → chú thích 8 (cả hai lùi 16 thẳng chữ trong dòng); tiêu đề mục trên màn lùi 4 như màn Tài khoản đã duyệt; nội dung sheet form cách nhau 24; sheet ngắn: tiêu đề → nhóm 16.

### Thang chữ theo bản web — 2026-10-28 (thay bảng 17pt ở mục trên)

- **Người dùng thấy 17pt quá to so với thẩm mỹ** → `TextRole` dùng đúng cỡ của design system web (docs/design "Nền tảng"): nội dung / tên dòng / số tiền dòng / nhãn **14** (line 20), tiêu đề thẻ · nhóm · sheet **16** (24), chú thích / phụ đề / chip / badge / nhãn nhóm in hoa **12** (16), chữ rất nhỏ **11**, chữ trong ô nhập riêng **16**, tiêu đề phần **20**, tên màn **24**; số tiền lớn giữ 34 / 40 / 24. Độ đậm giữ như bảng trước (Manrope vẫn hiển thị nặng hơn một bậc như web).
- **Nút:** 14 SemiBold ở cỡ 36 và 44, 16 ở cỡ 56 (web `text-sm`, nút L).
- **Hàng:** giữ `RowMetrics` — hàng một dòng đúng 52 (để vừa công tắc native 31pt), hàng có phụ đề ~58–59; icon dòng 20 trong cột 24 (trước 22). Đo trên Simulator: 52 / 59.
- Mọi thành phần đã đi qua `TextRole`, nên lần đổi này chỉ sửa một chỗ (`DesignTokens.swift`).

### Thử chữ 16 cho form, ô nhập, danh sách, thẻ — 2026-10-28 (đang thử, chờ người dùng chốt)

- Theo yêu cầu thử: `body` / `label` / `amount` / `input` **16** (line 22), tiêu đề thẻ · nhóm · sheet **17** (24) để vẫn hơn nội dung một bậc, phụ đề / chú thích / chip / badge **13** (18), nhãn nhóm in hoa **12**, chữ rất nhỏ 11. Nút 16 (cỡ 44 và 56), 14 ở cỡ 36.
- Hàng giữ 52 (một dòng) / ~62 (có phụ đề); không đổi `RowMetrics`.
- Phương án trước (bản web: nội dung 14, tiêu đề 16, phụ đề 12) chỉ cần đổi lại bốn dòng `size` trong `DesignTokens.swift`.
- Đã xem trên iPhone 17 Pro / iOS 26.3: Thư viện UI (dòng form với công tắc, nút, trạng thái trống) và màn Tài khoản (danh sách, thẻ hũ).

## Thang chữ đã chốt — nội dung 16 (2026-10-28, thay các thử nghiệm 17 / 14 ở trên)

Người dùng chốt **16 làm cỡ nội dung chính**. Manrope rộng nên 16 gần với Body 17 của SF Pro; mốc phổ biến của app tài chính (15–16). Các bậc cách nhau 1–4pt để thứ bậc rõ: 34 · 24 · 20 · 17 · 16 · 13 · 12 · 11.

| Vai trò | Cỡ / dòng | Độ đậm (hiển thị) | Dùng cho |
|---|---|---|---|
| hero | 40 | Bold (ExtraBold) | Số tiền đang nhập |
| display | 34 | ExtraBold | Số dẫn đầu màn |
| amountLarge | 24 | ExtraBold | Số lớn trong thẻ |
| pageTitle | 24 / 32 | SemiBold (Bold) | Tên màn |
| heading | 20 / 26 | SemiBold (Bold) | Tiêu đề phần |
| title | 17 / 24 | SemiBold (Bold) | Tiêu đề thẻ, nhóm, sheet, trạng thái trống |
| **body** | **16 / 22** | Regular (Medium) | Tên dòng, giá trị, nội dung, chữ gõ trong ô, nút |
| amount | 16 / 22 | Medium (SemiBold) | Số tiền cuối dòng |
| label | 16 / 22 | Medium (SemiBold) | Nhãn ô kiểu nhãn-trên |
| caption | 13 / 18 | Regular (Medium) | Phụ đề dòng, chú thích, lỗi |
| captionStrong | 13 / 18 | Medium (SemiBold) | Chip, badge |
| overline | 12 / 16 | Medium, in hoa | Nhãn nhóm dòng |
| footnote | 11 / 14 | Regular | Trục biểu đồ, chữ rất nhỏ |

- Nút: 16 ở cỡ 44 và 56, 14 ở cỡ 36. Ô số tiền lớn co 40 → 30 → 22 khi số dài.
- Mọi vai trò co giãn theo Kích thước chữ của iPhone (Dynamic Type); cỡ trong bảng là mức mặc định. Hàng giữ tối thiểu 52 (một dòng) / ~62 (có phụ đề) và cao thêm khi chữ to.
- Chưa áp: các màn cũ (Tổng quan, Giao dịch, Trợ lý, form cũ) vẫn dùng cỡ tự đặt; sẽ chuyển sang `TextRole` khi áp design system vào từng màn.

### Góp ý vòng 5 — 2026-10-28

- **Xanh chanh chỉ là điểm nhấn:** chỉ dùng cho Pro / AI (nút "Nổi bật", badge Pro, avatar Timi) và ngày hôm nay. Bỏ khỏi: màu mặc định của `ProgressBar` (giờ đen `Palette.primary`), nút nổi + (đen, icon trắng), badge "Đã thu" (xanh lá 12% thay nền chanh nhạt), mẫu thang khoảng cách, icon quà trong mẫu avatar. Các màn cũ còn chanh (Tổng quan: thẻ Pro, Làm quen, ô Tiền vào, lịch; Giao dịch: nút +, ô thu nhập, cột hôm nay; Vay nợ: thanh cho vay) — rà khi áp design system vào từng màn.
- **Nút không bấm được:** mọi vai trò khi tắt thành viên xám `fill2` (không glass nổi) với chữ xám nhạt (`secondary` 70%) — trước đó nút đen tắt chỉ mờ đi nên vẫn trông như bấm được.
- **Bỏ ô nhập "nhãn trên ô"** (`TimiTextField`, `FieldContainer`, `fieldSurface`): ô nhập chỉ còn kiểu iOS (`FormTextRow`, `FormNoteRow`, `TimiAmountField`).
- **Thanh hạn mức đổi màu theo mức** (`ProgressBar.budgetColor`): xanh lá dưới 80%, cam `Palette.warning` #F59E0B từ 80%, đỏ khi chạm/vượt 100%. Áp cho thanh hạn mức ở Tổng quan và Giao dịch. Thanh tiến độ khác (hũ, khoản vay) mặc định đen.
- Sửa kèm: badge không bị cắt chữ ("Sắp đến hạn").
- Đã xem trên iPhone 17 Pro / iOS 26.3: nút tắt, nút nổi đen, badge, ba mức hạn mức.

### Góp ý vòng 6 — 2026-10-28

- **Chọn trong form mở sheet:** `FormPickerRow` hiện giá trị + ›, chạm mở `ChoiceSheet` (danh sách có dấu ✓ ở mục đang chọn, chọn xong tự đóng). `FormDateRow` chạm pill mở sheet có lịch tháng trong thẻ trắng. Hai sheet này cao vừa nội dung (`timiFittedSheet`).
- **Danh sách & thẻ có ›:** `ListRow` mặc định hiện › (`showsChevron`), các dòng trong `OptionSheet` cũng có ›.
- **Sheet chuẩn iOS:** bỏ sheet tự vẽ tràn đáy (`timiBottomSheet`, `BottomSheetPanel`). Mọi sheet dùng `.sheet` của hệ thống: bo góc, lề nổi (iOS 26), thanh kéo, vuốt đóng đều của Apple. Timi chỉ đổi màu nền (`Palette.background`) và nội dung. Đầu sheet (`SheetHeader` / `SheetScaffold`): ✕ tròn bên trái, tiêu đề giữa; sheet form có chân Xoá + Lưu.
- Đã xem trên iPhone 17 Pro / iOS 26.3: sheet ngắn, sheet form, sheet chọn Loại (chọn xong giá trị đổi), sheet ngày, › trong danh sách.

### Góp ý vòng 7 — 2026-10-28

- **Sheet form theo chuẩn iOS (như Lịch, Danh bạ):** ✕ trên trái để huỷ, ✓ trên phải để lưu, cả hai là nút của thanh hệ thống (`Button(role: .close)` / `Button(role: .confirm)`). ✓ màu đen, xám khi chưa đủ thông tin (`SheetScaffold(canConfirm:onConfirm:)`). Bỏ chân sheet và `SheetSaveFooter` (thay chân Xoá + Lưu của vòng 6). Khi sửa mục đã có, `FormDestructiveRow` đỏ nằm trong một nhóm riêng ở cuối form; khi thêm mới thì không có dòng Xoá.
- **Dòng ngày bỏ viên:** `FormDateRow` giống dòng chọn: giá trị xám + ›, ví dụ "Hôm nay, 13:28" hoặc "30/10/2026, 15:28".
- **Chọn giờ:** `components: [.date, .hourAndMinute]` mở sheet có lịch tháng và bánh xe giờ trong cùng một thẻ trắng. Sheet sửa trên bản nháp: ✓ (đen, góc phải) mới lưu, ✕ bỏ thay đổi. `SheetHeader` có thêm `onConfirm` cho nút ✓.
- Thư viện UI có thêm mẫu "Sheet form · Sửa tài khoản" để xem dòng Xoá.
- Đã xem trên iPhone 17 Pro / iOS 26.3: sheet Thêm (✓ xám khi chưa có tên), sheet Sửa (dòng Xoá đỏ), sheet ngày giờ (chọn 30/10 và 15:28 rồi ✓ thì dòng cập nhật đúng).

### Vòng 8 — dùng đồ có sẵn của Apple — 2026-10-28

- **Biểu đồ chi theo ngày dùng Swift Charts** (`DailySpendingChart` trong `TimiCharts.swift`, dùng chung cho màn Giao dịch và Thư viện UI). Giữ dáng cũ: cột bo tròn, hôm nay màu chanh, ngày chưa tới nhạt. Nhấn giữ rồi kéo trên cột để xem "Ngày 7/10 · 6.000.000đ" dưới biểu đồ; cột được chọn đen, các cột khác mờ đi. Lựa chọn còn sau khi nhấc tay, nhấn lại đúng cột đó thì bỏ. Trong trang cuộn, Charts cần nhấn giữ chứ không nhận chạm nhanh (giống app Sức khoẻ). VoiceOver đọc được từng ngày.
- **Nút "Xong" trên bàn phím** (`keyboardDoneButton()`): bàn phím số không có phím Return nên luôn có nút Xong. Đã gắn sẵn trong `dismissesKeyboardOnTap()` (sheet form, Thư viện UI) và ở các form cũ (Thêm giao dịch, Thêm tài khoản, Hũ, Hạn mức). Chỉ gắn một lần cho cả màn, không gắn cho từng ô, nếu không iOS sẽ hiện nhiều nút.
- **Xoá luôn hỏi lại:** `FormDestructiveRow(title:question:message:)` mở bảng xác nhận của iOS (iOS 26 hiện dạng bảng nổi trỏ vào dòng Xoá), nút đỏ lặp lại tên hành động.
- **Rung nhẹ:** `.sensoryFeedback(.selection)` khi đổi chip lọc, chọn chip gợi ý số tiền, đổi giá trị dòng chọn, kéo qua từng cột biểu đồ. `Haptics.success()` khi bấm ✓ lưu (sheet form, sheet ngày). `Haptics.warning()` khi xoá. `Haptics.selection()` khi chọn trong sheet "Thêm mới". Công tắc đã có rung sẵn của iOS.
- Đã xem trên iPhone 17 Pro / iOS 26.3: biểu đồ (nhấn giữ cột ngày 7), nút Xong đóng bàn phím, bảng xác nhận xoá. Rung chưa thử được vì Simulator không phát rung, cần thử trên máy thật.

### Góp ý vòng 9 — 2026-10-28

- **Tách Ngày và Giờ thành hai dòng riêng:** `FormDateRow` ("Hôm nay", "Hôm qua", 30/10/2026) mở sheet lịch tháng. `FormTimeRow` ("15:47") mở sheet bánh xe giờ. Cả hai gắn chung một `Date`: đổi ngày giữ nguyên giờ, đổi giờ giữ nguyên ngày. Bỏ tham số `components` và sheet gộp lịch + giờ của vòng 7.
- Mỗi sheet có ✕ (bỏ) và ✓ đen (lưu), cao vừa nội dung. Dòng Giờ dùng icon `solar-clock-circle-linear`.
- Dòng chọn, Ngày, Giờ dùng chung một kiểu hiển thị (`FormValueLabel`: nhãn, giá trị xám, ›).
- Đã xem trên iPhone 17 Pro / iOS 26.3: đổi giờ 13:47 → 15:47 rồi ✓ thì dòng Giờ cập nhật, dòng Ngày giữ "Hôm nay".

### Dọn cấu trúc code — 2026-10-28

- Thư mục mới: `App`, `Models`, `Store`, `Utilities`, `DesignSystem/{Foundations, Components/*, Interaction, Legacy}`, `Features/<tab>/…`. Mỗi file một thành phần chính (Overview tách thành 6 thẻ + 2 sheet; Thư viện UI mỗi phần một file).
- Bỏ code không dùng: `Theme`, `CardSection`, `DailyTotal` / `dailyExpenses`.
- `Legacy/LegacyComponents.swift` gom `IconBadge`, `TransactionRow`, `AmountField` của bản prototype; xoá file này khi các màn cũ đã đổi sang `ListRow`, `IconCircle`, `TimiAmountField`.
- Giao diện không đổi; đã chạy lại 4 tab, lịch, sheet ngày và sheet hạn mức.
