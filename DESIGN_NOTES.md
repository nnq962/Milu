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

### Áp design system vào các màn cũ — 2026-10-28

- **Form chuyển sang `SheetScaffold`** (✕ trái, ✓ đen phải, không chân): Thêm/Sửa giao dịch, Thêm tài khoản, Thêm/Sửa hũ, Thêm/Sửa khoản vay, Hạn mức chi tiêu. Không còn `Form` mặc định của iOS trong app.
  - Số tiền chính dùng `TimiAmountField` (mở bàn phím ngay khi thêm mới qua `focusesOnAppear`). Số phụ ("Đã để dành", "Còn phải thu") dùng dòng mới `FormAmountRow`.
  - Danh mục, Tài khoản, Loại, Biểu tượng là `FormPickerRow`; sheet chọn có icon cạnh từng mục (`optionIcon`).
  - Giao dịch có hai dòng Ngày và Giờ; khoản vay có công tắc "Có hạn trả" + dòng Hạn trả.
  - Xoá (giao dịch, hũ, khoản vay) là `FormDestructiveRow` có hỏi lại. Sửa giao dịch giờ cũng xoá được ngay trong form.
- **Danh sách giao dịch** ở Chi tiết tài khoản và sheet "giao dịch trong ngày" (Lịch thu chi) dùng `TransactionListRow` (bọc `ListRow`, icon trơn, số tiền +/− đỏ), thẻ trắng, `RowDivider`, `EmptyStateCard`. Chi tiết tài khoản: thẻ số dư với `MoneyText(.display)`.
- **Xoá thư mục `DesignSystem/Legacy`** (`IconBadge`, `TransactionRow`, `AmountField`).
- Đã xem trên iPhone 17 Pro / iOS 26.3: thêm giao dịch (nhập số, sheet Danh mục có icon, ✓ lưu, số liệu tháng cập nhật), Chi tiết Vietcombank, Sửa hũ.
- Còn lại cho vòng sau: chữ tự đặt cỡ (Typography.font(...) size 11/12/14) ở thẻ Tổng quan, Vay nợ, Giao dịch, Trợ lý chưa đổi sang `TextRole`; xanh chanh ở các thẻ đó vẫn giữ.

### Các màn theo thang chữ và màu chung — 2026-10-28

- **Chữ:** mọi cỡ đặt tay trong `Features/` (75 chỗ: 9–34pt) đổi sang `TextRole`, bỏ `designLineHeight` lẻ.

| Cũ | Vai trò |
|---|---|
| 34 heavy | display |
| 24 heavy | amountLarge |
| 24 semibold | pageTitle |
| 20–22 semibold | heading |
| 16 semibold (tiêu đề thẻ) | title |
| 16 bold (số trong ô) | bodyStrong |
| 14 (tên dòng) | body |
| 14 bold (số tiền dòng) | amount |
| 12 / 11 regular | caption |
| 12 / 11 medium–semibold | captionStrong |
| 9–10 | footnote |

  Số trong ô Số dư / Cho vay / Nợ dùng `amount`. Ngày trong Lịch thu chi dùng `captionStrong`.
- **Xanh chanh chỉ còn ở:** thẻ Timi Pro, avatar trợ lý AI, ô hôm nay (lịch, biểu đồ).
  - Đã bỏ khỏi: nút + ở Giao dịch (giờ đen, icon trắng), icon thu nhập trong danh sách, thanh "Làm quen" (đen) và badge 3/4, +5, thanh tiến độ cho vay (đen).
  - `Palette.incomeTile` đổi từ chanh nhạt sang xanh lá 10% (ô Tiền vào, Đang cho vay).
- **Component chung thay đồ tự vẽ:**
  - Danh sách giao dịch ở tab Giao dịch dùng `TransactionListRow`; bỏ `FlowRow`.
  - "Cần chú ý" ở Tổng quan dùng `ListRow` + `RowDivider`.
  - Số "sắp đến hạn" là `StatusBadge` cảnh báo (đỏ nhạt).
  - Thanh hạn mức và thanh "Làm quen" dùng `ProgressBar`.
- Đã xem trên iPhone 17 Pro / iOS 26.3: Tổng quan (toàn trang), Giao dịch (Thu chi, Vay nợ), Trợ lý.

### Logo ngân hàng & ví — 2026-10-28

- **Nguồn:** bộ logo và danh sách của dự án web (`finance-tracker-v2/web/public/institutions`, `web/lib/institutions.ts`): 63 ngân hàng + 19 ví.
  - Đặt trong `Assets.xcassets/Institutions/` (ảnh tên `Institutions/<logo>`).
  - SVG giữ dạng vector. 3 file WebP (Bắc Á, Bảo Việt, PG Bank) đổi sang PNG 144×144.
- **Dữ liệu:** `Models/Institution.swift`, sinh từ file TS.
  - Gồm tên đầy đủ, tên ngắn, từ khoá.
  - `search` xếp hạng như bản web: viết tắt khớp đúng → tên ngắn bắt đầu bằng → từng từ → tên đầy đủ → chứa trong chữ. Không phân biệt dấu và hoa thường ("quan doi" → MB Bank).
  - `Account.institutionID` (+ `institution`, `iconName`). Dữ liệu mẫu: Vietcombank, Techcombank, MoMo, thẻ VPBank.
- **Hiển thị:**
  - `InstitutionLogo`: màu gốc, ô bo góc nền trắng, viền mảnh. Logo lùi vào 14% so với viền để không chạm cạnh (nhiều logo vẽ sát mép như Vietcombank).
  - `RowIcon` tự chọn logo hoặc icon Solar. Logo 28pt nhưng vẫn giữ cột icon 24pt, nên chữ và đường kẻ thẳng hàng với các dòng khác.
  - Dùng ở: danh sách Tài khoản, Chi tiết tài khoản (logo 56), thẻ tín dụng ở Vay nợ (44), sheet chọn tài khoản khi thêm giao dịch.
- **Chọn ngân hàng:** form Thêm tài khoản có dòng "Ngân hàng" / "Ví" (ẩn với Tiền mặt).
  - Dòng này mở `InstitutionPickerSheet`: ô tìm kiếm của iOS, danh sách logo + tên ngắn + tên đầy đủ, ✓ ở mục đang chọn.
  - Chọn xong thì tên tài khoản tự điền, trừ khi người dùng đã tự gõ tên. Đổi loại thì bỏ lựa chọn không hợp.
- Thư viện UI → Danh sách & Thẻ: thêm dòng Vietcombank mẫu và lưới toàn bộ logo.
- Lưu ý: logo là thương hiệu của từng ngân hàng/ví. Trước khi phát hành cần xem lại nguồn bộ logo và quy định thương hiệu.
- Đã xem trên iPhone 17 Pro / iOS 26.3: danh sách Tài khoản có logo, sheet chọn ngân hàng, tìm "quan doi", chọn MB Bank → tên tự điền → lưu → hiện trong danh sách.

### Sửa lỗi khi chạy máy thật — 2026-10-28

- **Hiệu ứng khi bấm:** `ButtonStyle` mới trong `PressStyles.swift`.
  - `.row`: hàng xám nhạt `fill3` khi đè ngón, nhả ra thì mờ dần, như ô trong danh sách iOS. Dùng cho dòng tài khoản, dòng chọn, Ngày/Giờ, Hạng mục, Xoá, sheet chọn, chọn ngân hàng.
  - `.card`: cả thẻ mờ 60% và thu nhỏ 2%. Dùng cho thẻ khoản vay, hũ, ô lịch.
  - `cardSurface` giờ cắt nội dung theo góc bo, để nền xám của hàng không tràn khỏi thẻ.
- **Ô số tiền không còn cuộn đi xa:**
  - `SheetScaffold` có thêm phần `header` (segmented + số tiền lớn), ghim dưới thanh tiêu đề và nằm ngoài vùng cuộn.
  - Trước đó, khi focus ô số tiền, iOS cuộn vùng chứa ô về phía bàn phím nên số bị đẩy lên rất xa.
  - Dùng ở: Thêm/Sửa giao dịch, tài khoản, hũ, khoản vay, hạn mức.
- **Nút xoá số tiền:** nút kính tròn của iOS (`nativeCircleButton`, 32pt, ✕), thay cho icon ✕ xám cũ.
- **Mở Thư viện UI mượt hơn:** các phần dùng `LazyVStack`, chỉ dựng khi cuộn tới. Trước đây dựng cả 9 phần cùng lúc (82 logo, biểu đồ) ngay lúc trượt vào.
- **Log khi gõ form:**
  - Các dòng `TUIKeyplane… width == -1.5`, `RTIInputSystemClient…`, `containerToPush is nil` là log nội bộ của bàn phím iOS. Thường gặp trên máy thật/iOS 26, không làm hỏng app, và không sửa được từ code app.
  - Dòng "Invalid frame dimension" có thể từ app, nên đã chặn hai nguồn:
    - `ProgressBar` bỏ qua giá trị NaN hoặc vô cực;
    - sheet vừa nội dung bỏ qua chiều cao 0 trước khi bố cục xong.
- Sửa kèm: mã màu `incomeTile` trong Thư viện UI (#E8F6ED).
- Đã xem trên Simulator: số tiền đứng yên khi gõ, nút xoá kính, mở Thư viện UI. Hiệu ứng bấm và độ mượt khi trượt cần xem lại trên máy thật.

### Màn Cài đặt — 2026-10-28

- **Avatar mở Cài đặt** (`Features/Settings/SettingsView.swift`) dạng sheet cao toàn màn, như trang tài khoản trong app của Apple. ✕ ở trên trái. Thư viện UI giờ là một dòng trong Cài đặt, mở bằng cách đẩy trang (push) trong sheet và có nút quay lại.
- **Bố cục theo trang cài đặt bản web:**
  - Hồ sơ: avatar 80, tên, "Dữ liệu mẫu · lưu trên máy", badge gói.
  - **Chung:** Giao diện (Sáng), Hạng mục (12), Hạn mức chi tiêu. Hạn mức mở `BudgetEditorSheet`, dùng chung giá trị với Tổng quan.
  - **Thông báo:** Nhắc ghi chi tiêu, Cảnh báo hạn mức, Tin từ Timi. Lựa chọn lưu bằng `@AppStorage`; chưa gửi thông báo thật, có ghi chú dưới nhóm.
  - **Hỗ trợ:** Câu hỏi thường gặp, Góp ý, Email hỗ trợ (mở Mail tới support@timi.nnqlab.dev), Điều khoản, Quyền riêng tư.
  - **Nhà phát triển:** Thư viện UI, Lịch sử phiên bản.
  - Cuối trang: số phiên bản.
- Mục chưa làm (Giao diện, Hạng mục, FAQ, Điều khoản…) mở một sheet ngắn giải thích "Sắp có", không để chạm vào mà không có gì.
- Icon Solar mới lấy từ Iconify: pallete-2, tag, bell-bing, star, question-circle, chat-round-line, letter, document-text, shield-check, widget-4, history, info-circle, logout-2.
- Đã xem trên iPhone 17 Pro / iOS 26.3: mở Cài đặt từ avatar, cuộn hết trang, mở Thư viện UI.

### Trang Tài khoản — vòng 1 — 2026-10-28

- **Chuyển tab không còn mờ:**
  - Nguyên nhân: iOS 26 cross-fade giữa hai tab khoảng 0,3 giây, nên trang cũ và trang mới chồng lên nhau (quay video Simulator thấy rõ "Chào buổi chiều" đè lên "Tài khoản"). Nhìn như cả trang, nhất là phần trên cùng, mờ rồi mới rõ.
  - Cách sửa: `App/InstantTabSwitch.swift` cho bộ điều khiển tab một animator kết thúc ngay, nên chuyển tab tức thì như iOS 18 trở về trước và các app ngân hàng. Các lời gọi khác vẫn chuyển cho delegate của SwiftUI, nên tab được chọn và trạng thái vẫn đúng.
- **Mục tiêu tiết kiệm dùng đúng thẻ của design system:**
  - Trước đây mỗi hũ là một thẻ riêng vừa có viền vừa có bóng, lề 21pt, icon lệch với danh sách tài khoản phía trên.
  - Giờ cả ba hũ nằm chung một thẻ trắng (`cardSurface`, có bóng, không viền), cách nhau bằng `RowDivider`, giống "Tài khoản thanh toán".
  - Mỗi hũ là `GoalRow`: cùng cột icon, cỡ chữ và số tiền với `ListRow`. Thanh tiến độ và dòng "Đã đạt / Còn" bắt đầu thẳng dưới tên hũ.
  - Bấm vào hàng thì hàng xám nhạt (`.row`), thay cho kiểu thu nhỏ cả thẻ.
- Đã xem trên iPhone 17 Pro / iOS 26.3: quay video chuyển Tổng quan → Tài khoản (không còn khung chồng), danh sách hũ.

### Trang Tài khoản — vòng 2 — 2026-10-28

- **Hũ tiết kiệm dạng lưới 2 cột** (`GoalTile`), chọn sau khi so với kiểu "thẻ gọn có vòng tiến độ" (đã bỏ).
  - Mỗi ô: icon trên nền tròn `fill1`, tên hũ, số đã để dành cỡ `amountLarge` dạng gọn (28tr), thanh tiến độ, dòng "70% · còn 12tr".
  - Ô cuối "+ Thêm hũ" viền đứt nét (`AddGoalTile`).
  - Bấm vào ô thì cả thẻ mờ đi (`.card`).
- **Nút + mở sheet "Thêm mới"** (`OptionSheet`) với 4 loại: Tiền mặt, Tài khoản ngân hàng, Ví điện tử, Hũ tiết kiệm, mỗi loại có một dòng gợi ý.
  - Chọn xong, sheet đóng rồi form đúng loại mới mở, để hai sheet không chồng nhau.
  - `AddAccountView(type:)` đặt sẵn loại, tiêu đề theo loại ("Thêm ví điện tử"…), gợi ý tên theo loại.
- Bỏ `GoalRow` (danh sách hũ chung một thẻ) và nút đổi kiểu hiển thị.
- Đã xem trên iPhone 17 Pro / iOS 26.3: lưới hũ, sheet Thêm mới, form Thêm ví điện tử.
- Bỏ ô "+ Thêm hũ" trong lưới: thêm hũ đi qua nút + → Thêm mới → Hũ tiết kiệm.
- Dòng tài khoản thanh toán chỉ còn một dòng (logo/icon, tên, số dư, ›), không còn "Cập nhật hôm nay…". `ListRow.subtitle` giờ là tuỳ chọn; bỏ hàm `FinanceStore.lastActivity` không còn dùng.

### Bo góc gần app Apple — 2026-10-28

Bản trước quy đổi từ Sleek web nên bo quá tròn trên iPhone. Đổi `CardCorners`:

| Token | Cũ | Mới | Dùng cho |
|---|---|---|---|
| large | 32 | 22 | thẻ, danh sách, ô hũ, thẻ Tổng quan (≈ widget iOS) |
| extraLarge | 40 | 26 | thẻ dẫn đầu trang: Tổng số dư (Tài khoản), Thu chi (Giao dịch), trạng thái trống |
| inset | 28 | 22 | nhóm form, thẻ trong sheet ngắn |
| flow | 18 | 16 | ô nhỏ trong thẻ: Số dư / Cho vay / Nợ (trước dùng inset 28), Tiền vào / ra, thẻ trong chat |
| field | 14 | 12 | ô nhập |
| icon | 12 | 10 | icon vuông (vương miện Pro) |
| calendarDay | 8 | 8 | giữ nguyên |

Sheet hệ thống vẫn dùng bo góc của Apple. Đã xem trên iPhone 17 Pro / iOS 26.3: Tổng quan, Tài khoản.

### Màu khi bấm hàng — 2026-10-28

- Hàng danh sách khi đè ngón dùng `Palette.rowPressed` = chanh 18% trên trắng (#F3FCD6), thay cho xám `fill3`. Nhả ra thì mờ dần như cũ.
- Áp cho mọi hàng dùng `.buttonStyle(.row)`: danh sách tài khoản, dòng chọn trong form, Ngày/Giờ, sheet chọn, chọn ngân hàng, Cài đặt.
- Chanh chỉ hiện thoáng qua lúc bấm nên vẫn là điểm nhấn. Thẻ (hũ, khoản vay, ô lịch) vẫn mờ và thu nhỏ khi bấm, không tô màu.
- Đã xem trên iPhone 17 Pro / iOS 26.3: đè giữ dòng Vietcombank.

### Trang Tài khoản — vòng 3 — 2026-10-28

- Tiêu đề phần "Mục tiêu tiết kiệm" → **"Hũ tiết kiệm"**.
- **Trạng thái trống có nút hành động:** `EmptyStateCard` có thêm `actionTitle` + `action`, hiện nút đen nhỏ (`TimiButton` primary, cỡ 36) dưới câu mô tả.
  - Hũ trống: icon heo, "Chưa có hũ nào", "Để dành cho chuyến đi, chiếc xe hay quỹ dự phòng, mỗi mục tiêu một hũ.", nút "Tạo hũ đầu tiên".
  - Tài khoản trống: "Chưa có tài khoản", nút "Thêm tài khoản" mở sheet Thêm mới.
  - Thay cho dòng chữ xám trong thẻ trắng trước đây; bỏ `emptyCard`.
- **Xoá tài khoản** ở hai chỗ:
  - nhấn giữ một dòng trong danh sách → menu "Xoá tài khoản";
  - màn Chi tiết tài khoản → nút "…" trên phải → "Xoá tài khoản".

  Cả hai đều hỏi lại bằng bảng xác nhận của iOS, ghi rõ số giao dịch sẽ bị xoá theo ("4 giao dịch của tài khoản này cũng bị xoá. Không thể hoàn tác."), rung cảnh báo khi xoá.
- `FinanceStore.delete(_ account:)` xoá tài khoản và mọi giao dịch của nó, rồi ghi xuống SwiftData (`deleteAccount(id:transactionIDs:)`).
- Đã xem trên iPhone 17 Pro / iOS 26.3: xoá Techcombank từ màn chi tiết (tổng số dư 118,52tr → 100,27tr, còn 3 tài khoản), trạng thái trống hũ trong Thư viện UI.
- Sửa lại theo góp ý: thẻ trống **không có nút** (thêm mới đi qua nút + của trang), icon **trơn không nền** 32pt màu `secondary`, cùng quy tắc với icon trong danh sách. Bỏ tham số `actionTitle`/`action` của `EmptyStateCard`. Áp cho mọi thẻ trống trong app.

### Form Thêm tài khoản — 2026-10-28

- **Ô số tiền lớn (`TimiAmountField`):** khi trống, ô nhập chỉ rộng 2pt và đứng ngay trước chữ "0" xám, nên chạm vào là thấy con trỏ nhấp nháy. Trước đây "0" là placeholder của TextField nên con trỏ bị che cho tới khi gõ. Thêm `isNegative`: hiện "−" và chữ đỏ.
- **Thêm tiền mặt / ngân hàng / ví** (`AddAccountView`):
  - Bỏ dòng "Loại", vì loại đã chọn ở sheet Thêm mới.
  - Không trường nào bắt buộc, ✓ luôn bấm được: để trống số dư thì lưu 0đ, để trống tên thì lấy tên gợi ý ("Tiền mặt", tên ngân hàng/ví đã chọn, "Ngân hàng", "Ví điện tử").
  - Công tắc **Số dư âm** ("Đang nợ tiền mặt" / "Tài khoản đang thấu chi"): lưu số dư âm, số hiện đỏ có dấu "−".
  - Dòng **Ngày** + **Giờ**, mặc định là lúc mở form. Lưu vào `Account.openedAt` (cột `createdAt` của V1, chưa cần đổi schema).
  - Công tắc **Không tính vào báo cáo** kèm chú thích. Lưu vào `Account.excluded` (cột `excluded` có sẵn).
  - **Mô tả → Ghi chú:** ô ghi chú nhiều dòng ở cuối form.
  - Ô số tiền mở bàn phím ngay khi vào form.
- **Không tính vào báo cáo:**
  - `FinanceStore.countedAccounts` bỏ các tài khoản này khỏi Tổng số dư, Tổng tài sản và Nợ; dòng "Gồm N tài khoản" cũng không đếm chúng.
  - Trong danh sách, tài khoản loại này có dòng phụ "Không tính vào báo cáo".
- **Sửa lỗi:** chạm ra ngoài để đóng bàn phím dùng `simultaneousGesture`, để công tắc trong form vẫn nhận được lần chạm.
- Đã xem trên iPhone 17 Pro / iOS 26.3: con trỏ hiện ngay, thêm "Tiền mặt" −300.000đ không tính báo cáo → hiện đỏ trong danh sách, tổng số dư không đổi.

### Form Thêm tài khoản — vòng 2: đồng bộ và báo lỗi — 2026-10-28

- **Đồng bộ:** mọi nhóm trong form chỉ gồm các dòng có nhãn bên trái, không còn tiêu đề nhóm ("GHI CHÚ") hay chú thích dưới nhóm.
  - Nhóm 1: Ngân hàng/Ví, Tên tài khoản, Số dư âm.
  - Nhóm 2: Ngày, Giờ, Không tính vào báo cáo.
  - Nhóm 3: ô Ghi chú (placeholder "Ghi chú").
  - Bỏ dòng phụ dưới "Số dư âm".
- **Bắt buộc:** tên tài khoản; với ngân hàng/ví thì phải chọn ngân hàng/ví. Gợi ý tên: "Tiền mặt", tên ngân hàng/ví đã chọn, nếu chưa chọn thì "Vietcombank" / "MoMo".
- **Báo lỗi:**
  - Nút ✓ luôn bấm được. Bấm khi còn thiếu thì sheet không đóng, máy rung kiểu lỗi (`Haptics.error`), nhãn dòng thiếu chuyển đỏ, và dưới nhóm hiện câu đỏ có icon "Chọn ngân hàng và nhập tên tài khoản.".
  - Sửa đến đâu lỗi tắt đến đó.
- **Design system:**
  - `SheetScaffold(validate:)` kiểm tra trước khi lưu; trả `false` thì giữ sheet và rung lỗi.
  - `FormGroup(error:)` hiện câu lỗi đỏ thay cho chú thích.
  - `FormRowLabel(isInvalid:)` và `FormTextRow(isInvalid:)` tô đỏ nhãn.
- Đã xem trên iPhone 17 Pro / iOS 26.3: bấm ✓ khi trống → hai dòng đỏ + câu lỗi; chọn Techcombank → tên tự điền, lỗi biến mất.

### Bàn phím và ô nhập — 2026-10-28

- **Bỏ thanh "Xong" trên bàn phím** (xoá `keyboardDoneButton`). Như các app hiện đại, bàn phím đóng khi chạm ra ngoài ô nhập hoặc kéo nội dung.
- **Bỏ nút xoá nhanh** ở mọi ô: nút kính ✕ của ô số tiền lớn và ✕ xám của `FormTextRow` / `FormAmountRow`; xoá file `ClearFieldButton.swift`. Xoá số bằng phím ⌫ của bàn phím.
- **Phần đầu form cuộn cùng nội dung:** `SheetScaffold` đặt `header` (segmented + số tiền lớn) làm phần tử đầu trong ScrollView, không còn ghim dưới thanh tiêu đề. Đã thử với bàn phím ảo trên Simulator: chạm và gõ số tiền thì số đứng yên, không bị đẩy đi xa như trước.
- Form Thêm/Sửa giao dịch: bỏ tiêu đề nhóm "GHI CHÚ", ô ghi chú dùng placeholder "Ghi chú", giống form tài khoản.

### Chip gợi ý số tiền — 2026-10-28

- Trước đây chỉ gợi ý khi gõ dưới 1.000 và chỉ nhân 1.000 / 10.000 / 100.000, nên tối đa chừng chục triệu.
- Giờ lấy số đã gõ nhân 10³ … 10⁹, bỏ những mức vượt 999 tỷ (giới hạn 12 chữ số của ô), giữ tối đa 5 chip:
  - gõ 5 → 5k, 50k, 500k, 5tr, 50tr;
  - gõ 25 → 25k … 250tr;
  - gõ 2500 → 2,5tr … 25tỷ.
- Nhãn chip dạng gọn quen thuộc (`vndCompact`: 25k, 2,5tr, 1,2tỷ) để 5 chip vừa một hàng, căn giữa. VoiceOver vẫn đọc số đầy đủ.
- Hàng chip không cuộn ngang: hàng chip kính trong ScrollView bị iOS 26 vẽ một dải màu đậm phía sau. Nếu lỡ không vừa thì mới cuộn, có `NoScrollEdgeEffect` + `GlassEffectContainer`.
- Đã xem trên Simulator: gõ 25, chọn 250tr → −250.000.000đ, chip được chọn chuyển đen.
- **Hiệu ứng chip:** mỗi chip xuất hiện nối nhau từ trái sang phải. Chip phóng từ 70% lên, rõ dần, trồi lên 8pt, kiểu lò xo 0,4 giây (độ nảy 0,35), chip sau trễ 45ms so với chip trước. Gõ thêm số thì bộ chip mới chạy lại hiệu ứng; chip cũ mờ đi nhanh (0,12 giây).
  - Hàng chip luôn có mặt trong giao diện (rỗng khi chưa gõ), để từng chip chạy được hiệu ứng riêng. Nếu thêm cả hàng một lúc thì chỉ thấy hàng mờ dần hiện ra.
  - Đã xem trên Simulator bằng cách quay video rồi tách từng khung hình.

### Hiệu ứng form — 2026-10-28

1. **Số tiền lăn số:** số hiển thị là một `Text` có `.contentTransition(.numericText())`. TextField phủ lên trên không vẽ chữ (`.clear`), chỉ hiện con trỏ, nên chữ và con trỏ luôn khớp. Chọn chip, gõ hay xoá số thì từng chữ số lăn sang giá trị mới (snappy 0,3 giây).
2. **Lưu thiếu thông tin thì lắc:** `ShakeEffect` + `.shake(_:)` trong `Interaction/Shake.swift` lắc ba nhịp qua lại 8pt trong 0,4 giây, như khi nhập sai mật mã iPhone. `FormGroup(shakes:)` lắc cả thẻ mỗi lần số đếm tăng. Form Thêm tài khoản tăng số đếm mỗi lần bấm ✓ còn thiếu, cùng lúc nhãn đỏ, câu lỗi trượt xuống và rung lỗi.
3. **Đổi Chi tiêu/Thu nhập:** dấu "−"/"+" là cùng một `Text` nên lăn sang nhau. Màu số chuyển dần đỏ ↔ đen trong 0,25 giây. Dấu xuất hiện hoặc biến mất kèm thu phóng và mờ.
4. **Ngày/Giờ/lựa chọn đổi giá trị:** `FormValueLabel` dùng `.numericText()`, nên "Hôm nay" → "30/10/2026", "16:51" → "15:30", hay danh mục mới đều lăn vào. Áp cho mọi dòng chọn: Danh mục, Tài khoản, Ngày, Giờ…
- Đã xem bằng video Simulator: 45 → bấm chip 4,5tr thì lăn thành 4.500.000; đổi sang Thu nhập thì "−" đỏ thành "+" đen; bấm ✓ khi trống thì thẻ lắc và nhãn đỏ.
- **Sửa lại theo góp ý:**
  - Bỏ hiệu ứng lăn số của ô số tiền, vì quá rối khi chọn chip. Số đổi ngay, chip được chọn chuyển đen theo hiệu ứng mặc định của nút kính iOS. Dấu "−"/"+" và màu khi đổi Chi tiêu/Thu nhập vẫn chuyển mượt.
  - Hàng chip mở/đóng mượt: đổi `typedBase` trong `withAnimation(.smooth(duration: 0.35))`, nên cả sheet chạy chung một chuyển động. Các dòng bên dưới trượt xuống/lên cùng hàng chip, thay vì nhảy bật trong khi chỉ chip có hiệu ứng. Bỏ `.animation(value: suggestions)` cũ.
  - Đã xem bằng video Simulator: gõ 3 thì hàng "Tên" trượt xuống dần trong ~0,35 giây; bấm 30k thì số đổi ngay.

### Bàn phím đẩy nội dung — 2026-10-28

- Trước: chạm ô Ghi chú thì iOS chỉ cuộn đủ cho ô nhập vừa lộ ra, nên mép dưới thẻ ghi chú dính sát bàn phím.
- Giờ: `SheetScaffold` có `.safeAreaPadding(.bottom, Spacing.xxl)`. iOS cuộn ô đang nhập lên trên vùng an toàn, nên luôn chừa 24pt giữa thẻ và bàn phím. Áp cho mọi form.
- Đã thử cách tự cuộn bằng `ScrollViewReader.scrollTo` tới mép bàn phím: lệnh chạy và tính đúng vị trí, nhưng iOS tự cuộn ngay sau đó và ghi đè. Đã bỏ cách này.
- Sửa kèm:
  - Chạm ra ngoài để đóng bàn phím giờ dùng một lớp nằm sau nội dung (`keyboardDismissArea()`). Cử chỉ phủ cả form trước đây làm bàn phím vừa mở đã đóng ngay khi chạm vào một ô.
  - Cả ô ghi chú (không chỉ dòng đầu) nhận chạm.
- Đã xem trên Simulator với bàn phím ảo: từ ô số tiền chuyển sang Ghi chú thì thẻ ghi chú lộ đủ, còn khoảng hở phía trên bàn phím.
- **Bỏ lại theo góp ý:** gỡ `safeAreaPadding` vì không thấy hiệu quả rõ. Phần đẩy nội dung khi bàn phím hiện để iOS tự lo như mặc định. Vẫn giữ hai sửa kèm (lớp đóng bàn phím nằm sau nội dung, cả ô ghi chú nhận chạm).
- **Chip về hiệu ứng mặc định** (góp ý 2026-10-28): bỏ kiểu nảy lần lượt. Chip xuất hiện và biến mất bằng transition mặc định của SwiftUI (mờ dần), trong cùng chuyển động `.smooth` làm các dòng bên dưới trượt theo. Bấm chọn chip vẫn là hiệu ứng nút kính của iOS.
- **Báo lỗi bỏ lắc** (góp ý 2026-10-28): xoá `ShakeEffect` / `FormGroup(shakes:)`. Lưu thiếu thông tin thì chỉ rung lỗi, rồi câu đỏ hiện ra mượt dưới nhóm. `showsErrors` đổi trong `withAnimation(.smooth(duration: 0.3))`, nên các nhóm bên dưới trượt xuống nhường chỗ chứ không nhảy.
- **Viết hoa chữ đầu:** đã thử `textInputAutocapitalization` rồi bỏ theo góp ý (không thấy tác dụng trên máy thật). Để bàn phím iOS xử lý theo cài đặt của người dùng.

### Chú thích trong form — 2026-10-28

- Đã thử thêm hai câu chú thích dưới nhóm rồi bỏ: người dùng thích ít chữ.
- **Quy tắc:** nhãn dòng tự nói lên ý nghĩa, form không có chú thích hay tiêu đề nhóm.
- Form thêm tài khoản chỉ đổi nhãn "Ngày" → **"Số dư tính từ"**; nhóm gồm "Số dư tính từ", "Giờ", "Không tính vào báo cáo" như trước.

### Chữ gợi ý ngắn gọn — 2026-10-28

- **Quy tắc:** placeholder của ô tìm kiếm và ô nhập chỉ là 1–3 từ nói việc cần làm, không kèm danh sách ví dụ. Ví dụ: "Tìm ngân hàng", "Tìm ví", "Tìm giao dịch", "Ghi chú", tên gợi ý như "Tiền mặt". Câu trong thẻ trống cũng giữ một câu ngắn.
- Sheet chọn ngân hàng: "Tìm ngân hàng: vcb, mb, techcom…" → **"Tìm ngân hàng"**; "Tìm ví: MoMo, ZaloPay…" → **"Tìm ví"**. Thẻ không tìm thấy: "Thử tên viết tắt, như vcb."
- **Ô tìm kiếm ở chân màn hình:** sheet chọn ngân hàng/ví dùng `.searchable` với vị trí mặc định thay cho `.navigationBarDrawer`. Trên iOS 26 ô tìm kiếm nằm dưới cùng, kiểu kính, gần ngón cái như app của Apple. Khi tìm, thanh tiêu đề thu lại và có nút ✕ cạnh ô. iOS cũ hơn vẫn để ô dưới tiêu đề. Đã xem trên Simulator.

### Tài khoản — câu tóm tắt, icon, màn chi tiết — 2026-10-28

- **Câu dưới Tổng số dư** (`AccountsView.summary`) chỉ nói những gì đang có:
  - có cả hai: "Gồm 3 tài khoản và 2 hũ";
  - chỉ có tài khoản: "Gồm 3 tài khoản";
  - chỉ có hũ: "Gồm 2 hũ tiết kiệm";
  - chưa có gì: "Chưa có tài khoản nào".

  Không đếm tài khoản "không tính vào báo cáo".
- **Icon và logo một chuẩn:**
  - Không dùng icon có nền nữa: bỏ `IconCircle` ở màn chi tiết và thẻ tín dụng (Vay nợ), bỏ nền tròn của icon trong ô hũ.
  - `RowIcon(name:size:)` vẽ cả glyph Solar lẫn logo ngân hàng/ví trong cùng một ô vuông `size`: logo phủ cả ô, glyph chiếm 20/24 ô (glyph Solar đã có lề sẵn). Logo không còn to hơn icon: trước đây logo 28 so với glyph 20 trong dòng, logo 56 so với icon 44 ở màn chi tiết.
  - Cỡ dùng: dòng danh sách 24, ô hũ 28, đầu màn chi tiết và thẻ tín dụng 44. `InstitutionLogo` mặc định 24.
- **Màn chi tiết tài khoản:**
  - Dòng dưới số dư không còn lặp. Chỉ hiện tên đầy đủ của ngân hàng khi khác tên tài khoản, rồi ghi chú của người dùng; bỏ phần trùng tên hoặc trùng loại ("Tiền mặt · Tiền mặt"). Không có gì thì ẩn dòng.
  - Form thêm tài khoản giờ lưu đúng ghi chú người dùng nhập, không tự điền loại/tên ngân hàng vào ô ghi chú.
  - **Xoá tài khoản** chuyển từ menu "…" trên thanh tiêu đề xuống dòng đỏ ở cuối nội dung (`FormDestructiveRow`, có hỏi lại), như Danh bạ của iOS.
- Đã xem trên Simulator: danh sách (logo và icon cùng cỡ, ô hũ không nền), chi tiết Vietcombank và Tiền mặt.
- **Sửa lại dòng dưới số dư:** mọi loại tài khoản hiện cùng một thông tin, ngày bắt đầu theo dõi: "Từ ngày 28/10/2026" (`Account.openedAt`). Bỏ tên đầy đủ ngân hàng và ghi chú khỏi dòng này. Dữ liệu mẫu bỏ số tài khoản giả ("•••• 4821"…), vì app không thu số tài khoản (áp dụng sau khi Đặt lại dữ liệu mẫu).

### Dòng giao dịch và dòng Xoá — 2026-10-28

- **`FormDestructiveRow`** có icon thùng rác đỏ (`solar-trash-bin-minimalistic-linear`) trước chữ, mặc định cho mọi dòng xoá. `RowIcon(tint:)` để tô màu glyph.
- **`ListRow(trailingSubtitle:)`:** số tiền thẳng hàng với tên, dòng phụ bên phải nằm dưới số tiền. Số tiền giữ đủ cỡ, tên co trước.
  - Chi tiết tài khoản: trái là hạng mục, phải là ngày rút gọn "27/10".
  - Tab Giao dịch (đã nhóm theo ngày): trái là hạng mục, phải là giờ "08:15".
- **Nhãn nhóm in hoa 12pt (`overline`):** vẫn dùng ở tiêu đề nhóm trong Cài đặt (CHUNG, THÔNG BÁO, HỖ TRỢ, NHÀ PHÁT TRIỂN) và nhãn mẫu trong Thư viện UI. Form nhập không dùng, theo quy tắc "form không có tiêu đề nhóm".
- Đã xem trên Simulator: chi tiết Vietcombank (số tiền ngang tên, 27/10 dưới số tiền, dòng Xoá có icon).

### Một kiểu tiêu đề — 2026-10-28

- **Chỉ còn một kiểu tiêu đề** cho mọi chỗ: phần trong màn, nhóm dòng trong form hay Cài đặt, thẻ, sheet, hộp thoại. Đó là `TextRole.title` (17 SemiBold, viết thường như câu), vẽ bằng `SectionHeader`. `FormGroup(title:)` dùng chính `SectionHeader`, nên "Chung", "Thông báo" trong Cài đặt giống hệt "Hũ tiết kiệm", "Giao dịch".
- **Bỏ nhãn nhóm in hoa 12pt (`overline`)** khỏi `TextRole`. Nhãn mẫu trong Thư viện UI chuyển sang `captionStrong`.
- **Sheet và form được có tiêu đề nhóm** khi nhóm cần tên. Thay quy tắc cũ "form không có tiêu đề nhóm". Vẫn giữ ít chữ: nhóm mà nhãn dòng đã đủ rõ thì không cần tiêu đề.
- Đã xem trên Simulator: Cài đặt.
- **Tiêu đề thụt vào theo nội dung thẻ** (giống app Claude): `SectionHeader` lùi 16pt (`RowMetrics.horizontal`), đúng chỗ nội dung trong thẻ bắt đầu. Dòng có icon thì tiêu đề thẳng với icon. Dòng không có icon (form, ô hũ) thì thẳng với chữ đầu dòng. Chú thích dưới thẻ cũng thẳng hàng theo. Đã xem trên Simulator: Cài đặt, Tài khoản.
- **Tiêu đề nhẹ như app Claude:** `SectionHeader` dùng chữ cỡ nội dung (16, độ đậm thường) màu xám phụ, không còn 17 SemiBold màu mực. `TextRole.title` (17 SemiBold) giờ chỉ dành cho tiêu đề trong thẻ, sheet, hộp thoại.
- **Một khoảng cách từ tiêu đề tới thẻ:** token mới `Spacing.headerGap` = 8, dùng ở mọi màn và trong `FormGroup`. Trước đây mỗi màn tự đặt: đa số 12, màn chi tiết tài khoản 20 (vì tiêu đề nằm chung stack với các phần khác), Cài đặt 8 + 4. Ở Vay nợ, các thẻ trong một phần vẫn cách nhau 12, chỉ khoảng dưới tiêu đề là 8.
- Đã xem trên Simulator: Giao dịch, chi tiết Vietcombank, Cài đặt.
- **Quay lại hai kiểu tiêu đề** (tiêu đề xám làm màn chính kém nổi bật): `SectionHeader(style:)`.
  - `.section` (mặc định): tên phần trên màn chính (Tài khoản, Giao dịch, Vay nợ, chi tiết tài khoản), 17 SemiBold màu mực, để nổi giữa các thẻ trên nền trang.
  - `.group`: tên nhóm dòng trong sheet hoặc form (Cài đặt, form nhập), cỡ nội dung 16, màu xám, như app Claude. Trong sheet, tiêu đề sheet đã là chữ đậm nên nhóm chỉ cần nhẹ. `FormGroup(title:)` tự dùng kiểu này.
  - Cách chọn: tiêu đề đứng trên nền màn chính thì dùng `.section`; tiêu đề trong sheet thì dùng `.group`. Cả hai cùng lùi 16pt và cùng cách thẻ `Spacing.headerGap` (8).
- **Tiêu đề nhẹ dùng lại nhãn in hoa:** `SectionHeader` `.group` vẽ bằng `TextRole.overline` (12 Medium, in hoa, giãn chữ 0.6, màu xám), không dùng chữ thường 16 nữa. `overline` được khôi phục trong `TextRole`, cũng dùng lại cho nhãn mẫu trong Thư viện UI. Vậy app có đúng hai kiểu tiêu đề: `.section` (17 SemiBold, màn chính) và `.group` (in hoa 12, trong sheet/form). Đã xem trên Simulator: Cài đặt.

### Sheet hũ tiết kiệm — thời hạn — 2026-10-28

- Nhãn trên số tiền lớn: "Mục tiêu" (trước là "Số tiền mục tiêu").
- **Thời hạn:** nhóm mới gồm công tắc "Thời hạn". Bật lên thì hiện dòng "Đến ngày" (mặc định 6 tháng sau, lịch chỉ cho chọn từ ngày mai, `FormDateRow(earliest:)`), như cách Lời nhắc của iOS bật ngày.
- **Gợi ý mỗi tháng** ở chú thích dưới nhóm: "Cần để dành 5.834.000đ mỗi tháng trong 6 tháng." Tính bằng (mục tiêu − đã để dành) ÷ số tháng còn lại (tháng lẻ tính là một tháng, ít nhất 1), làm tròn lên 1.000đ (`SavingsGoal.monthlySaving`). Đủ tiền rồi thì ghi "Đã đủ mục tiêu." Số tự cập nhật khi đổi số tiền hoặc ngày.
- Lưu vào cột `goalDueDate` đã có sẵn trong schema V1, không cần phiên bản mới. Dữ liệu mẫu: "Mua xe" hạn 14 tháng, "Du lịch Đà Nẵng" 6 tháng (áp dụng sau khi Đặt lại dữ liệu mẫu).
- Đã xem trên Simulator: sửa hũ "Mua xe", bật thời hạn.

### Biểu tượng hũ — 2026-10-28

- **20 biểu tượng** cho các mục tiêu hay gặp (`GoalIcon`): Tiết kiệm, Quỹ dự phòng, Nhà, Xe hơi, Xe máy, Du lịch, Học tập, Cưới hỏi, Gia đình, Thú cưng, Điện thoại, Máy tính, Máy ảnh, Giải trí, Nội thất, Sức khoẻ, Thể thao, Mua sắm, Quà tặng, Khác.
  - Tất cả là icon nét (Solar linear, lấy từ Iconify như các icon khác). Riêng con heo dùng `mdi-piggy-bank-outline`, vì Solar không có heo đất.
  - "Du lịch" dùng vali: máy bay của Solar là máy bay giấy, dễ hiểu nhầm là "gửi".
  - Ba biểu tượng cũ giữ nguyên mã đã lưu trong database (`mdi-piggy-bank`, `mdi-car-outline`, `mdi-airplane`). Chỉ hình vẽ đổi sang bản nét (`GoalIcon.image`), nên hũ cũ không mất icon.
- **Chọn biểu tượng:** dòng "Biểu tượng" hiện hình icon kèm tên. Bấm vào mở sheet vừa nội dung (`GoalIconPickerSheet`) gồm lưới 5 × 4 icon tròn, không có chữ, giống Lời nhắc của iOS. Icon đang chọn tô đen, icon trắng. Bấm một icon là chọn và đóng sheet.
- Đã xem trên Simulator: mở lưới từ hũ "Mua xe", chọn vali, dòng đổi thành "Du lịch".

## Chuyển sang Hugeicons — 2026-10-28

Thay Solar. Solar thiên về icon giao diện, thiếu nhiều icon đời sống (cơm, heo đất, em bé, ngân hàng, tàu, xu…).

- **Đã so sánh 6 bộ** cùng 12 icon tài chính: Solar, Lucide, Phosphor, Tabler, Hugeicons, MingCute. Người dùng chọn **Hugeicons bản miễn phí (Stroke Rounded)**:
  - hơn 4.000 icon, rất nhiều icon tài chính;
  - nét 1.5 bo tròn, gần với Solar;
  - giấy phép MIT, dùng được trong app thương mại.
  - Đổi lại, bản miễn phí chỉ có một kiểu nét, không có bản tô đặc.
- **Icon trong code:**
  - Asset tên `hugeicons-<mã>`, tải từ Iconify, đổi `currentColor` thành đen để vẽ dạng template. `SolarIcon` đổi tên thành `TimiIcon`.
  - Đã bỏ toàn bộ asset `solar-*`, `mdi-*`, `material-symbols-*` và file giấy phép của chúng.
  - Đổi tương ứng một số icon: ăn uống dùng dao dĩa, giải trí dùng cuộn phim, đầu tư dùng biểu đồ đi lên, lương dùng túi tiền, cho vay dùng tay cầm xu, trợ lý AI dùng `ai-magic`, cảnh báo hạn mức dùng chấm than tròn.
- **Thanh tab:** không còn bản tô đặc khi chọn. Tab giữ icon nét, nền kính của iOS 26 đánh dấu tab đang chọn.
- **Kho icon chung `IconCatalog`:**
  - 133 icon, 10 nhóm: Tài chính, Ăn uống, Đi lại, Nhà cửa, Mua sắm, Sức khoẻ, Giải trí, Học tập, Gia đình, Khác.
  - Mỗi icon có tên tiếng Việt và từ khoá. Tìm kiếm không phân biệt dấu, ví dụ "xe" ra xe máy, xe buýt, ô tô (từ khoá "xe hơi").
  - Hũ dùng kho này. Hạng mục sau này dùng chung kho.
  - Thêm icon: bỏ SVG vào Assets và thêm một dòng trong `IconCatalog`.
- **`IconPickerSheet`** thay cho lưới 20 icon:
  - sheet cao, các nhóm có tiêu đề in hoa nhẹ, lưới 5 cột;
  - ô tìm kiếm ở chân màn hình, gợi ý "Tìm icon";
  - icon đang chọn tô đen, bấm là chọn và đóng.
- **Dữ liệu cũ:** `SavingsGoal.icon` giờ là chuỗi tên icon. `IconCatalog.migrated` đổi tên Solar/MDI cũ của hũ và icon lời nhắc sang Hugeicons khi đọc database.
- **Giấy phép:** Cài đặt → Hỗ trợ → **Giấy phép mã nguồn mở** hiện giấy phép MIT của Hugeicons và OFL của phông Manrope (`LicensesView`, đọc từ Resources). Dòng xuống hàng cứng của file được nối lại cho dễ đọc.
- Đã xem trên Simulator: Tổng quan, Tài khoản, sheet chọn icon (cuộn nhóm, tìm "xe"), Cài đặt, màn Giấy phép.

### Bỏ tìm kiếm icon, một cỡ icon đứng riêng — 2026-10-28

- **Sheet chọn icon không có ô tìm kiếm**: chỉ còn các nhóm, để người dùng tự xem và chọn. Đã bỏ `IconCatalog.search` và từ khoá phụ. Mỗi icon chỉ còn tên tiếng Việt, dùng cho VoiceOver và dòng "Biểu tượng".
- **Trạng thái trống** (`EmptyStateCard`): icon màu mực như mọi icon khác, không còn màu xám nhạt. Vẽ bằng `RowIcon` giống logo.
- **Một cỡ cho icon và logo đứng riêng**: `RowMetrics.featureIcon` = 44, dùng cho logo hoặc icon ở đầu màn chi tiết tài khoản, thẻ tín dụng (Vay nợ) và trạng thái trống. Trước đây icon trạng thái trống là 32 nên trông nhỏ hơn logo ngân hàng 44.
- Đã xem trên Simulator: trạng thái trống "Chưa có giao dịch chuyển khoản", sheet chọn icon.

## Màu nhấn xám iOS, thẻ hũ gọn hơn — 2026-10-28

- Dòng list khi nhấn: đổi từ lime 18% sang `systemGray4` (#D1D1D6, tối #3A3A3C), màu chuẩn của ô bảng iOS như trong Cài đặt.
- Dòng "Biểu tượng" trong sheet hũ chỉ hiện icon và mũi tên, không kèm tên (tên vẫn đọc cho VoiceOver).
- Thẻ hũ tiết kiệm: icon, tên chữ thường 16 (`body`, màu mực), thanh tiến độ, dòng cuối "đã để dành/mục tiêu" (`amount`, phần mục tiêu màu xám, tự co tối đa 60% khi số dài). Bỏ số lớn và dòng phần trăm.

## Chọn nhanh biểu tượng, số tiền hũ rút gọn — 2026-10-28

- Thẻ hũ: dòng cuối rút gọn "15tr/50tr" (`vndCompact`), cỡ 16 không co chữ.
- Sheet hũ: bỏ dòng "Biểu tượng >", thay bằng nhóm "BIỂU TƯỢNG" có một hàng `IconQuickPicker`: 5 icon gợi ý (`SavingsGoal.suggestedIcons`: heo đất, xe, nhà, vali, mũ tốt nghiệp) và nút "…" mở `IconPickerSheet` đầy đủ, kiểu Lời nhắc của iOS. Icon chọn trong sheet mà không nằm trong gợi ý sẽ thế vào chỗ đầu hàng, nên lựa chọn luôn hiện ra.
- Ô icon tròn (`IconChoiceLabel`) dùng chung cho hàng chọn nhanh (44pt) và sheet (52pt). Thêm asset `hugeicons-more-horizontal`.

## Sửa tài khoản và hũ — 2026-10-28

- Màu nhấn dòng list: quay lại lime 18% (#F3FCD6); đã thử xám iOS nhưng không hợp.
- Lối vào sửa, theo kiểu Danh bạ iOS:
  - Màn chi tiết tài khoản có nút "Sửa" ở góc trên phải, mở lại form tài khoản (tiêu đề "Sửa tài khoản", điền sẵn mọi trường, không tự bật bàn phím).
  - "Xoá tài khoản" chuyển từ màn chi tiết vào cuối form sửa, giống form hũ.
  - Nhấn giữ một dòng tài khoản hoặc một thẻ hũ: menu "Sửa" / "Xoá". Chạm vào thẻ hũ vẫn mở form sửa như trước.
- Sửa số dư không ghi đè: phần chênh lệch thành giao dịch "Điều chỉnh số dư" (icon bút chì, dòng phụ "Không tính vào báo cáo"), không tính vào tổng thu chi, lịch tiền, biểu đồ và trợ lý. Hai hạng mục này không hiện trong ô chọn hạng mục.

## Màn hũ tiết kiệm, nạp/rút, nút sửa dạng icon — 2026-10-28

- Nút sửa ở thanh trên (màn tài khoản, màn hũ) là icon bút chì (`EditToolbarButton`), iOS 26 đặt trong vòng kính như nút quay lại.
- Chạm thẻ hũ giờ mở **màn hũ** chứ không mở form sửa:
  - thẻ đầu có icon, số đã để dành, "trên mục tiêu", thanh tiến độ, phần trăm và số còn thiếu (kèm số cần để dành mỗi tháng nếu có hạn);
  - hai nút "Nạp tiền" (chính) và "Rút tiền" (phụ, tắt khi hũ trống);
  - mục "Lịch sử" liệt kê các lần nạp/rút.
- Nạp/rút như chuyển khoản: chọn tài khoản nguồn hoặc đích, tài khoản giảm đúng bằng số hũ tăng (và ngược lại), tổng tài sản không đổi, không tính vào thu chi. Rút quá số trong hũ thì báo "Hũ chỉ còn X." Màn tài khoản cũng hiện dòng "Nạp vào Mua xe" / "Rút từ Mua xe".
- Form sửa hũ bỏ dòng "Đã để dành" (chỉ còn khi tạo hũ mới), để mọi thay đổi số tiền đều đi qua nạp/rút.
- Menu nhấn giữ: phần nổi lên giữ góc bo 22pt của thẻ (`contentShape(.contextMenuPreview, …)`) thay vì góc nhỏ mặc định của hệ thống.

## Menu nhấn giữ mượt như iOS — 2026-10-28

- Dòng list (`RowButtonStyle`) có nền trắng riêng dưới lớp lime khi nhấn. Trước đó nền trong suốt nên khi nhấn giữ, hệ thống chỉ nhấc icon và chữ lên, kèm viền xám; giờ cả dòng nổi lên thành một khối trắng bo 22pt.
- Thẻ hũ dùng `MenuCardButtonStyle`: không có hiệu ứng nhấn riêng (trước là mờ 60% + thu nhỏ 0,98 với spring). Hiệu ứng riêng chạy chồng lên hiệu ứng thu-rồi-nổi của hệ thống nên thẻ bị nổi, thu, rồi nổi lại; giờ chỉ còn hiệu ứng của iOS. Các thẻ khác không có menu (khoản vay, ngày trên lịch) vẫn giữ `.card`.
- Còn một khung hình mờ lúc iOS đổi dòng đang nổi sang bản xem trước cạnh menu. App Danh bạ của Apple trên iOS 26 cũng vậy (đã quay video so sánh trên Simulator). Đã thử bỏ mờ dần khi thả và dùng bản xem trước tự vẽ (`preview:`), cả hai không đỡ hơn. Quyết định giữ menu của Apple, không tự làm hiệu ứng riêng như Claude app (người dùng chọn 2026-10-28).
- Bóng thẻ hũ hiện trễ khi menu đóng: iOS ẩn thẻ gốc (cả bóng) lúc menu mở và chỉ hiện lại khi bản nổi đã đáp xuống. Giờ bóng được vẽ riêng (`CardShadow`, chỉ phần bên ngoài thẻ) phía sau, nằm ngoài `.contextMenu`, nên luôn có sẵn; `GoalTile` không tự vẽ bóng nữa. Đã đo lại bằng video: bóng xuất hiện cùng lúc thẻ đáp.

## Màn hũ gọn chữ hơn — 2026-10-28

- Thẻ đầu màn hũ chỉ còn: icon, số đã để dành, "/ mục tiêu", thanh tiến độ, và nếu có thời hạn thì một dòng "Cần X/tháng". Bỏ dòng phần trăm và "còn …".
- Hai nút đổi chỗ và gọn chữ: "Rút" (phụ) bên trái, "Nạp" (chính) bên phải.
- Form hũ bỏ hẳn "Đã để dành", cả khi tạo mới: hũ bắt đầu từ 0đ, tiền vào qua "Nạp".
- Ghi chú "•••• 4821"… khi sửa tài khoản mẫu là dữ liệu mẫu cũ còn trong database của máy; dữ liệu mẫu hiện tại không còn ghi chú. Cài đặt → Nhà phát triển → Đặt lại dữ liệu mẫu sẽ xoá.

## Thẻ đầu màn hũ theo kiểu "Tổng số dư" — 2026-10-28

- Bỏ bố cục giữa và dòng "/ 50.000.000đ". Thẻ giờ canh trái như thẻ "Tổng số dư": nhãn "Đã để dành" và số lớn bên trái, icon hũ bên phải; dưới là thanh tiến độ, một dòng "34%" (trái) và "Mục tiêu 50.000.000đ" (phải); có thời hạn thì thêm "Cần X/tháng".
- Nút ghi đủ "Rút tiền" / "Nạp tiền" (Rút trái, Nạp phải).
- Lịch sử: tiêu đề là việc đã làm ("Nạp tiền" / "Rút tiền"), dòng phụ là nguồn ("Từ Ví tiền mặt" / "Về Vietcombank"). Ở màn tài khoản: "Nạp vào hũ" / "Rút từ hũ", dòng phụ là tên hũ.

## Bỏ menu nhấn giữ, thẻ hũ có vòng tiến độ — 2026-10-28

- Bỏ menu nhấn giữ Sửa/Xoá trên dòng tài khoản và thẻ hũ: sửa và xoá ở màn chi tiết (nút bút chì). Gỡ luôn `CardShadow`, `MenuCardButtonStyle` và nền trắng riêng của `RowButtonStyle` (chỉ cần cho menu). Thẻ hũ dùng lại `.card`. Dòng giao dịch ở màn Giao dịch vẫn còn nhấn giữ để xoá (có từ trước).
- Thẻ đầu màn hũ: dòng dưới thanh tiến độ luôn một dòng: "92% · 167k/tháng" (trái) và "Mục tiêu 6tr" (phải), số rút gọn để không xuống dòng trên máy hẹp.
- Nạp/rút có thêm dòng "Giờ".
- Thẻ hũ ở Tài khoản: icon nằm trong vòng tiến độ (`ProgressRing`, 44pt, nét 4pt, cùng màu với `ProgressBar`), dưới là tên và "17tr/50tr". Bỏ thanh ngang để thẻ thấp và gọn hơn.
- Thẻ hũ làm lại theo mẫu người dùng gửi (thay vòng tiến độ, bỏ `ProgressRing`): icon trên nền tròn (`IconCircle`) cạnh tên và "Mục tiêu 40tr", dưới là số đã để dành đầy đủ (16 SemiBold, tự đổi sang "28tr" nếu không vừa) với phần trăm bên phải, cuối cùng là thanh tiến độ.
- Bỏ lưới 2 cột: thẻ nửa màn hình cứ bị cắt tên và số. Hũ giờ là các dòng trong một thẻ như "Tài khoản thanh toán" (`GoalRow`): icon không nền ở cột icon, tên và số đã để dành đầy đủ, thanh tiến độ, rồi "Mục tiêu 40.000.000đ" và phần trăm. Không còn chữ nào bị cắt.
- Hàng chọn nhanh biểu tượng: 2 hàng x 6 (11 gợi ý + nút "…"), icon không nền, chỉ icon đang chọn có vòng tròn đen. Gợi ý thêm: quỹ dự phòng, xe máy, laptop, điện thoại, cưới, em bé. Sheet đầy đủ vẫn giữ nền tròn xám.
- Sheet biểu tượng cũng bỏ nền tròn xám: mọi ô chọn icon đứng riêng, chỉ icon đang chọn có vòng tròn đen (bỏ tham số `showsTile`).
- TẠM: màn Tài khoản đang xếp 4 kiểu hiển thị hũ (A dòng gọn, B vòng tiến độ, C cuộn ngang, D lưới tối giản) cùng kiểu hiện tại để người dùng so trên máy (`GoalLayoutTrials.swift`). Chọn xong thì xoá file này và chỉ giữ một kiểu.
- Chốt kiểu C (người dùng chọn 2026-10-28): hũ là các thẻ cuộn ngang (`GoalCard`), mỗi thẻ rộng 3/5 trang để thẻ sau hé ra; cuộn dừng đúng mép thẻ (`scrollTargetBehavior(.viewAligned)`), thẻ chạy ra quá lề trang khi cuộn. Trong thẻ: icon không nền, tên, số đã để dành đầy đủ (17 SemiBold), "Mục tiêu 40tr · 70%", thanh tiến độ. Đã xoá `GoalLayoutTrials.swift` và `GoalRow`.

## Khoá tài khoản, thẻ Tổng số dư mới — 2026-10-28

- "Không tính vào báo cáo" đổi thành "Khoá tài khoản" (người dùng chọn thay luôn, không giữ hai công tắc). Công tắc nằm trong một nhóm riêng của form tài khoản. Trong code: `Account.isLocked`, vẫn lưu ở cột `excluded`.
- Tài khoản khoá: dòng phụ "Đã khoá" trong danh sách; màn chi tiết ghi "Đã khoá · không tính vào tổng số dư"; không có trong ô chọn tài khoản khi ghi giao dịch (trừ giao dịch đang sửa nằm ở tài khoản đó) và khi nạp/rút hũ.
- Thẻ "Tổng số dư" ở Tài khoản: tổng lớn, dưới là hai phần "Tài khoản" và "Hũ tiết kiệm" cạnh nhau, ngăn bằng một vạch dọc; nếu có tài khoản khoá thêm dòng có icon ổ khoá "Không tính X đang khoá". Bỏ dòng "Gồm 3 tài khoản và 3 hũ". Thêm asset `hugeicons-square-lock-02`.

## Dòng tài khoản khoá, hũ đã hoàn thành — 2026-10-28

- Dòng tài khoản khoá (`ListRow(isLocked:)`): icon/logo xám và mờ 45%, tên và số tiền màu chữ phụ (`MoneyText.Tone.muted`), ổ khoá nhỏ trước số tiền, dòng phụ "Đã khoá".
- Mục "Đã hoàn thành" ở cuối trang Tài khoản: hũ có số đã để dành ≥ mục tiêu (`SavingsGoal.isCompleted`) rời khỏi dãy thẻ cuộn ngang và hiện ở đây thành dòng (icon, tên, "Mục tiêu X", số tiền), chạm mở màn hũ. Mục chỉ hiện khi có hũ hoàn thành. Rút bớt tiền thì hũ quay lại dãy thẻ.
- TẠM: đầu trang Tài khoản đang xếp 3 kiểu thẻ Tổng số dư (gọn với nhãn khoá, thanh tỉ lệ, tối giản) cùng kiểu hai cột hiện tại để người dùng so (`TotalCardTrials.swift`). Chọn xong thì xoá.
- Chốt thẻ Tổng số dư kiểu 1: tổng, dòng "3 tài khoản · 3 hũ", nhãn bo tròn xám có ổ khoá "Không tính X đang khoá" khi có tài khoản khoá. Đã xoá `TotalCardTrials.swift`.
- Hũ đã hoàn thành: thay mục liệt kê ở cuối trang bằng một dòng lối vào "Hũ đã hoàn thành" (icon huy hiệu, số hũ, mũi tên) mở màn riêng `CompletedGoalsView` gom tất cả hũ đã đủ mục tiêu. Dòng chỉ hiện khi có ít nhất một hũ hoàn thành. Thêm asset `hugeicons-checkmark-badge-01`.
- Dòng tài khoản khoá đổi lại: bỏ làm xám/mờ icon và tên, bỏ ổ khoá cạnh số tiền. Giờ có huy hiệu ổ khoá nhỏ (`LockBadge`: vòng đen 15pt, viền trắng) gắn ở góc dưới phải icon/logo như huy hiệu app iOS; số tiền màu xám, dòng phụ "Đã khoá".
- Màn "Hũ đã hoàn thành": dòng phụ bỏ "Mục tiêu X" (lặp với số tiền), thay bằng ngày hoàn thành "Hoàn thành 28/10" (ngày của lần nạp gần nhất); hũ chưa từng nạp ghi "Đã hoàn thành".
