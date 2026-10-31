> **Lưu trữ:** đây là nhật ký thiết kế cũ, giữ nguyên từng mục để tra lịch sử. Quy tắc đang áp dụng nằm ở [`DESIGN_NOTES.md`](../DESIGN_NOTES.md).

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

- Manrope; sáng/tối theo máy hoặc chọn trong Cài đặt (xem "Chế độ tối"); Solar Icons; tiền tệ liền số và cùng cỡ/font/weight/baseline (`10.000.000đ`, `10,3tr`).
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
- **Theme:** ~~App luôn dùng light theme~~ — thay bởi "Chế độ tối — 2026-10-29".
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

## Hộp xoá giữa màn hình, sửa màn hũ hoàn thành trống — 2026-10-29

- `FormDestructiveRow` dùng alert giữa màn hình của iOS (nút "Huỷ" và nút xoá đỏ) thay cho hộp nổi lên từ nút xoá. Áp dụng cho mọi nút xoá trong form (tài khoản, hũ, giao dịch, khoản vay).
- Màn "Hũ đã hoàn thành" khi danh sách trống (vd rút tiền làm hũ cuối cùng không còn đủ, rồi quay lại) bị vỡ chữ thành một cột dọc vì `ContentUnavailableView` nằm trong overlay của một ScrollView rỗng. Giờ khi trống thì hiện thẳng trạng thái trống full màn hình.

## Vòng đời hũ tiết kiệm, gợi ý số tiền khi nạp — 2026-10-29

- Ba trạng thái của hũ (`SavingsGoal.isReached`, `isClosed`):
  - Đang để dành: Rút tiền / Nạp tiền như cũ.
  - Đã đủ mục tiêu: dòng dưới thanh tiến độ ghi "Đã đủ mục tiêu"; nút chính "Dùng tiền", hai nút phụ "Rút hết" và "Mục tiêu mới" (mở form hũ để tăng mục tiêu). Lần nạp làm hũ vừa đủ hiện alert "Đã đủ mục tiêu" kèm rung thành công. Hũ đủ tiền vẫn nằm trong dãy thẻ (ghi "Đã đủ · mục tiêu 40tr") và vẫn tính vào tổng.
  - Đã đóng: thẻ đầu ghi "Mục tiêu 40.000.000đ" và "Đã dùng: … · ngày", không còn nút; hũ rời dãy thẻ và tổng số dư, nằm ở "Hũ đã hoàn thành" (mới đóng lên trước, dòng phụ "Đã dùng: … · 29/10").
- ~~"Dùng tiền" (`GoalSpendSheet`)~~ — nay là "Mua ngay" mở `AddTransactionView(buying:)`: số tiền mặc định là toàn bộ hũ, hạng mục chi (không có ô tên, từ 2026-10-29), ngày, giờ. Ghi thành khoản chi từ hũ (tính vào báo cáo); chi ít hơn thì hiện "Phần còn lại về [tài khoản]" và số còn lại được rút về. Lưu xong thì hũ đóng.
- "Rút hết" dùng sheet rút với số tiền điền sẵn bằng cả hũ; rút hết thì hũ đóng với ghi chú "Đã rút về …".
- Lịch sử màn hũ gồm cả khoản chi từ hũ.
- Gợi ý khi nạp (`TimiAmountField(presets:)`): trước khi gõ, hiện chip "Mỗi tháng 167k" (hũ có thời hạn) và "Còn thiếu 1tr"; bấm là điền ngay. Gõ số thì thay bằng gợi ý thường.

## ~~VIỆC ĐỂ SAU — "Dùng tiền" mở sheet tạo giao dịch~~ — đã làm (xem "Hũ: Mua ngay mở sheet thêm giao dịch")

- Ý người dùng (2026-10-29): bấm "Dùng tiền" trên hũ đã đủ mục tiêu thì mở **sheet tạo giao dịch** (`AddTransactionView`), điền sẵn từ hũ: loại chi tiêu, số tiền = cả hũ, tài khoản = hũ, tên = tên hũ. Lưu xong thì xử lý phần còn lại (nếu có) và đóng hũ như `FinanceStore.spend(from:…)`.
- Chưa làm vì sheet tạo giao dịch còn đang làm dở. Tạm thời dùng `GoalSpendSheet` (có ghi TODO trong file). Khi xong sheet giao dịch: thêm chế độ "từ hũ" cho nó, bỏ `GoalSpendSheet`.
- 2026-10-29: sheet giao dịch đã xong; `GoalSpendSheet` đã dùng ô chọn hạng mục con mới, nhưng vẫn là sheet riêng. Bước gộp vào `AddTransactionView` còn chờ.

## Tiêu đề nhóm viết hoa trong form — 2026-10-29

- Form bớt trống: mỗi nhóm có tiêu đề nhóm nhỏ viết hoa (`FormGroup(title:)`, kiểu `.group`).
  - Thêm/sửa tài khoản: THÔNG TIN · THỜI GIAN · TUỲ CHỌN · GHI CHÚ.
  - Hũ: THÔNG TIN · BIỂU TƯỢNG · KẾ HOẠCH.
  - Giao dịch: CHI TIẾT · GHI CHÚ. Nạp/rút hũ: CHI TIẾT · GHI CHÚ. Dùng tiền: CHI TIẾT · PHẦN CÒN LẠI. Khoản vay: THÔNG TIN.
  - Nhóm nút xoá không có tiêu đề. Ô ghi chú đổi chữ gợi ý thành "Thêm ghi chú" để không lặp với tiêu đề.

## Sửa 2 lỗi nghiệp vụ từ đợt rà soát — 2026-10-29

- Tài khoản khoá: giao dịch của nó không còn tính vào báo cáo (Đã chi/Đã thu, tổng ngày, lịch tiền, chi theo hạng mục, trợ lý); mở khoá là tính lại. Trong danh sách vẫn hiện, dòng phụ "[hạng mục] · Không tính". `reportable(excluding:)` + `FinanceStore.lockedAccountIDs` / `isReportable(_:)`.
- Xoá hũ còn tiền (người dùng chọn hỏi tài khoản nhận): hộp xoá ghi "Hũ còn X. Chọn tài khoản nhận lại tiền…" và có một nút "Chuyển về [tài khoản]" cho mỗi tài khoản không khoá; tiền rút về đó rồi hũ mới bị xoá, tổng tài sản không đổi. Không có tài khoản nào thì chỉ báo và có nút OK, không xoá. Hũ trống thì xác nhận như cũ. Các dòng nạp/rút cũ được giữ, hiện "Hũ đã xoá". `FormDestructiveRow` có thêm `choices` và `canConfirm`.

## Sửa 3 lỗi nghiệp vụ mức trung bình — 2026-10-29

- Chạm vào dòng lịch sử ở màn tài khoản và màn hũ để sửa (`ActivityRow` + `ActivityEditor`):
  - giao dịch chi/thu mở form sửa giao dịch (`AddTransactionView(editing:)`);
  - lần nạp/rút mở `GoalTransferSheet(editing:)` ("Sửa lần nạp/rút"), đổi số tiền, tài khoản, ngày, giờ, ghi chú, có "Xoá lần nạp/rút"; cả hai số dư được tính lại. Không cho sửa thành rút quá số trong hũ, hay nạp ít/xoá lần nạp khi tiền của nó đã bị rút ra (hũ sẽ âm).
  - Dòng nạp/rút của hũ đã xoá hoặc đã đóng thì không chạm được.
- Xoá tài khoản (người dùng chọn): xoá luôn các lần nạp/rút của nó và trừ lại khỏi hũ đang mở (không xuống dưới 0đ); hộp xoá báo trước "Hũ “Mua xe” giảm 2.000.000đ…". Hũ đã đóng giữ nguyên.
- Hũ đã đóng: lịch sử chỉ xem; form hũ có "Mở lại hũ" (`FinanceStore.reopen`) đưa hũ về dãy thẻ để sửa được lại.
- Sửa giao dịch "Điều chỉnh số dư" giữ nguyên hạng mục điều chỉnh (thêm vào đầu ô chọn), không còn bị đổi sang hạng mục khác.

## Đưa trang Tài khoản về design system — 2026-10-29

- Thành phần mới dùng chung:
  - `SummaryCard` (Surfaces): thẻ đầu căn trái, nhãn nhỏ, số lớn bằng `MoneyText(.display)`, icon/logo bên phải, nội dung thêm bên dưới. Dùng cho "Tổng số dư", màn tài khoản (đổi từ căn giữa sang căn trái, người dùng chọn) và màn hũ.
  - `NavigationRowLabel` (Forms): đưa từ Settings ra design system, thêm `value`. Dòng "Hũ đã hoàn thành" dùng nó.
  - `StatusBadge(icon:)`: nhãn bo tròn có icon thay chấm. Nhãn "Không tính … đang khoá" dùng nó.
  - `FormValueLabel(valueIcon:, isInvalid:)`: dòng "Ngân hàng/Ví" có logo trước tên, thay cho bản tự làm.
  - `SheetCloseButton`, `SelectionCheck` (Sheets): nút ✕ trên thanh của sheet và dấu tích chọn (Hugeicons `tick-02`, thêm asset). Dùng ở sheet chọn ngân hàng, sheet biểu tượng, `SheetScaffold`, `ChoiceSheet`.
- Khoảng cách viết số trên trang Tài khoản đổi sang `Spacing`.
- Icon lỗi trong `FormGroup` đổi sang Hugeicons `alert-circle`.
- Chưa đổi: thẻ tháng ở màn Giao dịch và thẻ Tổng quan vẫn tự làm, có thể chuyển sang `SummaryCard` sau.

## Rà soát trang Tài khoản lần 2 — 2026-10-29

- Tab bar mọc mục thứ 5: dòng `AssistantView()` bị nhân đôi trong `ContentView.swift`; đã xoá.
- Hũ đã đóng: giao dịch và nạp/rút của nó không sửa/xoá được ở bất kỳ đâu (`FinanceStore.isEditable`, store cũng tự từ chối). Màn Giao dịch nhấn giữ hiện "Mở lại hũ để sửa giao dịch này"; form sửa (từ Trợ lý) chỉ xem, có ghi chú.
- Phần trăm hũ làm tròn xuống (`SavingsGoal.progressText`): chỉ hiện 100% khi đủ mục tiêu.
- Nhãn khoá đổi thành "Đang khoá X".
- Khi mọi hũ đã hoàn thành: thẻ trống ghi "Chưa có hũ đang để dành". Hũ có tiền mà chưa có lần nạp: lời trống nói rõ đó là số có sẵn khi tạo hũ.
- `PickerRowLabel` (Sheets): dòng chọn dùng chung, có icon/logo, dòng phụ, dấu tích. Dùng ở `ChoiceSheet` và sheet chọn ngân hàng; `OptionSheet` ("Thêm mới") dùng `NavigationRowLabel`.
- Token mới: `RowMetrics.iconChoice` (52, ô trong sheet biểu tượng), `toolbarGlyph` (22) và `toolbarGlyphFrame` (28) cho nút + và bút chì (nút + to lên 2pt cho bằng bút chì).
- `SummaryCard` dùng thêm cho "Tổng tài sản" (Tổng quan) và "Tổng cho vay trừ nợ" (Vay nợ); hai thẻ này giờ bo 26 như thẻ đầu trang. Thẻ tháng ở Thu chi (hai số Đã chi/Đã thu cạnh nhau) là mẫu khác nên giữ nguyên.

## Lưu trữ thay vì xoá, rà soát lần 3 — 2026-10-29

- **Xoá tài khoản thiết kế lại** (người dùng chọn): tài khoản đã có giao dịch hoặc nạp/rút hũ chỉ "Lưu trữ tài khoản", một bước, giữ nguyên số dư (không bắt đưa về 0đ). Lưu trữ thì ẩn khỏi danh sách, ô chọn và tổng; lịch sử, báo cáo cũ và lịch sử hũ giữ nguyên. Danh sách ở "Tài khoản đã lưu trữ" (dòng ở cuối trang Tài khoản, chung thẻ với "Hũ đã hoàn thành"); trong form có "Khôi phục tài khoản". Tài khoản chưa có lịch sử vẫn "Xoá tài khoản" hẳn. Bỏ logic trừ lại khỏi hũ khi xoá tài khoản (hết lỗi cộng sai và cảnh báo thiếu). `Account.archivedAt`, `FinanceStore.archivedAccounts`, `archive`/`unarchive`/`hasHistory`; asset `hugeicons-archive-02`.
- Lỗi nghiệp vụ: khoản chi của hũ đã xoá không sửa được nữa (`isEditable`); sửa khoản chi trên hũ không được vượt số trong hũ; nạp/rút/dùng tiền khi mọi tài khoản đều khoá báo "Mọi tài khoản đang khoá. Mở khoá…" thay vì ✓ mờ im lặng; tài khoản/hũ mới lưu `sortOrder` = lớn nhất + 1 nên không đổi chỗ sau khi mở lại app; mỗi thao tác lưu một lần (`FinanceDatabase.batch`); nút xoá hũ phân biệt hai tài khoản trùng tên (thêm số dư) và dùng id; "Rút hết" khoá ô số tiền.
- Design system: `listCard()` cho mọi thẻ danh sách ở trang Tài khoản; thẻ hũ padding `Spacing.card`; "Đã đủ mục tiêu" và dòng "Đã dùng…" là `StatusBadge`; token cho `StatusBadge`, `LockBadge`, `SheetHeader`, `RowMetrics.circleDividerInset`; trạng thái trống dùng `EmptyStateCard` (bỏ `ContentUnavailableView`). `SheetHeader` giữ ✕/✓ của hệ thống như nút đóng native.
- Chữ: "Hũ đã hoàn thành" khi trống nói đúng là hũ đã đóng; xoá hũ khi mọi tài khoản khoá bảo "Mở khoá một tài khoản"; nhãn khoá thống nhất "Đã khoá" ("Đã khoá -300.000đ"), màn chi tiết "Đã khoá · không tính vào tổng và báo cáo"; "Mục tiêu mới" mở form với bàn phím ở ô mục tiêu; hũ đã đóng không sửa mục tiêu.

## Rà soát lần 4 (phạm vi Tài khoản) — 2026-10-29

- Phạm vi review chỉ còn quanh Tài khoản; Trợ lý AI và màn Giao dịch chưa thiết kế xong nên để sau.
- Tài khoản vừa khoá vừa lưu trữ vẫn không tính vào báo cáo (`lockedAccountIDs` gồm cả tài khoản đã lưu trữ).
- Lịch sử tài khoản đã lưu trữ chỉ xem như hũ đã đóng: `FinanceStore.readOnlyReason` trả lý do hiển thị ("Tài khoản đã lưu trữ. Khôi phục tài khoản để sửa.", "Hũ của giao dịch này đã bị xoá.", "…Mở lại hũ để sửa."), dùng ở form sửa giao dịch và menu nhấn giữ. Form tài khoản đã lưu trữ khoá số dư và "Số dư âm".
- "Rút hết" là một thao tác store (`withdrawAll`), lưu một lần.
- Store tự chặn mất tiền: xoá hũ còn tiền mà không có tài khoản nhận; dùng tiền vượt số trong hũ hoặc để lại tiền mà không có tài khoản nhận; nạp/rút với hũ đã đóng hay tài khoản khoá/lưu trữ; ghi giao dịch vào tài khoản lưu trữ hay hũ đã đóng/xoá.
- Thứ tự: danh sách lưu trữ mới nhất lên đầu cả sau khi mở lại app; tài khoản khôi phục về cuối danh sách (`FinanceDatabase.moveToEnd`).
- Bút chì không còn mở bàn phím ở ô mục tiêu; chỉ "Mục tiêu mới" mới mở.
- Ghi chú "Khôi phục" đúng khi tài khoản vẫn khoá.

## Rà soát lần 5 — 2026-10-29

- Sửa giao dịch "Điều chỉnh số dư" và khoản chi từ hũ: khoá chọn thu/chi (không biến điều chỉnh thành khoản chi có báo cáo, không biến khoản chi hũ thành khoản thu); khoản chi hũ chỉ được ở lại đúng hũ đó. Hộp xoá khoản chi hũ ghi "Số tiền được trả lại vào hũ."
- Tài khoản đã lưu trữ: khoá cả công tắc "Khoá tài khoản" (đổi nó sẽ đổi báo cáo cũ).
- Store kiểm cả giá trị mới khi sửa: giao dịch không chuyển sang tài khoản lưu trữ hay hũ khác/đã đóng, khoản chi hũ không vượt số trong hũ; nạp/rút không đổi hũ, không làm hũ âm (kể cả khi xoá); xoá hũ đã đóng mà còn tiền bị chặn; "Khôi phục" lưu một lần.
- `SheetScaffold` chặn bấm ✓ hai lần. "Dùng tiền" bỏ rung thừa.
- `FormActionRow` (mới): hành động hoàn tác được, chữ đen, không ›, có thể hỏi xác nhận. Dùng cho "Lưu trữ tài khoản" (trước là dòng đỏ như xoá), "Khôi phục tài khoản", "Mở lại hũ". Bỏ các footer giải thích dưới các nút này (đúng quy tắc ít chữ).
- Dòng lịch sử chỉ xem (tài khoản lưu trữ, hũ đã đóng/xoá) chạm vào hiện "Không sửa được" kèm lý do.
- Thẻ hũ dùng `MoneyText`; "Hũ đã hoàn thành" dựng lề bằng `contentMargins` như "Tài khoản đã lưu trữ"; `ListRow` có dòng phụ bên phải cũng tô xám số tiền khi khoá.
- Chữ: báo vượt số thống nhất "Hũ chỉ có X."; tiêu đề sheet khớp nút ("Nạp tiền", "Rút tiền", "Rút hết", "Dùng tiền"); "Đã lưu trữ 29/10"; màn tài khoản đổi "Giao dịch" thành "Lịch sử" như màn hũ; thẻ tổng bỏ "0 …" ("Chưa có tài khoản nào", "3 tài khoản", "1 hũ"); "Hoá đơn", "Sức khoẻ" theo kiểu dấu "Xoá/Khoá".

## Rà soát lần 6 — 2026-10-29

- Không có lỗi do các chặn mới. Sửa:
  - "Đóng hũ" (`FinanceStore.closeEmpty`): hũ đã mở lại mà còn 0đ đóng lại được, về "Hũ đã hoàn thành" với ghi chú cũ (mở lại không xoá ghi chú nữa).
  - Store chặn rút quá số trong hũ và số tiền ≤ 0 khi nạp/rút mới.
  - Khoản chi của hũ đã xoá ghi "Hũ đã xoá" thay vì "—".
  - Form giao dịch chỉ xem: khoá cả số tiền, các ô và ghi chú, không chỉ nút ✓.
  - Sửa trong form rồi bấm "Lưu trữ" / "Khôi phục" / "Mở lại hũ" / "Đóng hũ" thì chỉnh sửa được lưu trước, không mất. Form hũ lưu dựa trên hũ trong store (không ghi đè số tiền bằng bản cũ của form).
- `SheetAmountHeader` (Forms): phần đầu sheet có nhãn nhỏ + ô số tiền, dùng ở form tài khoản, form hũ, nạp/rút, dùng tiền. `HiddenToolbarTitle` thay `Color.clear` ở thanh trên.
- "Hũ đã hoàn thành" dựng như "Tài khoản đã lưu trữ" (một ScrollView, cùng lề, trống hay không). Ngày đóng hũ hiện "29/10" ở cả danh sách và màn hũ.
- Chữ: lý do chỉ xem gom thành 3 câu (`archivedReason`, `closedGoalReason`, `deletedGoalReason`); "Cần nạp ít nhất X, vì tiền đã được rút hoặc dùng."; "Tiền của lần nạp này đã được rút hoặc dùng…"; Dùng tiền: dòng "Về tài khoản", ghi chú "X sẽ về tài khoản này."; ghi chú đóng hũ có phần dư ("Đã dùng: Mua xe · 5tr về Vietcombank"); lần nạp vừa đủ mục tiêu chỉ rung một lần.

## Trang Hạng mục — 2026-10-29

- Cài đặt → "Hạng mục" (số = số hạng mục con đang dùng) mở `CategoriesView`: chọn Chi tiêu / Thu nhập; các nhóm là các dòng trong một thẻ (icon, tên, số hạng mục, ›), như Cài đặt iOS (người dùng chọn, thay cho bản đầu hiện cả cây). Nút + trên thanh thêm nhóm. Có dòng "Hạng mục đã ẩn" khi có. Bấm nhóm mở `CategoryGroupView`: các hạng mục con và "Thêm hạng mục"; bút chì sửa chính nhóm.
- `CategoryEditorView`: tên, biểu tượng (`IconQuickPicker`, gợi ý lấy từ icon của nhóm và các hạng mục trong nhóm), với hạng mục con có thêm "Nhóm" để chuyển nhóm; nhóm mới có "Hạng mục đầu tiên". Cuối form: "Hiện lại" (đã ẩn), "Ẩn …" (đã có giao dịch, hỏi trước), "Xoá …" (chưa có). Hạng mục con cuối cùng của nhóm không xoá/ẩn riêng được.
- Người dùng chọn: giao dịch bắt buộc ghi vào hạng mục con; hạng mục có giao dịch thì ẩn, giữ lịch sử; lượt này chỉ làm trang quản lý, chưa nối form giao dịch (ghi trong docs/DATABASE.md).
- Database V2 (`TimiSchemaV2`, thêm `CategoryRecord.parentID`), dữ liệu mặc định 14 nhóm (10 chi, 4 thu) và các hạng mục con tiếng Việt (`DefaultCategories`).
- Bảng biểu tượng mở rộng từ 133 lên 311 icon, 15 nhóm (thêm Làm đẹp, Thể thao, Công nghệ, Du lịch, Dịch vụ), toàn bộ Hugeicons free; đã kiểm mỗi tên có asset, không trùng.
- "Thêm hạng mục" dùng `FormActionRow` (chữ và dấu + màu đen như mọi dòng hành động); màu xám đọc như nút bị tắt.
- Rà soát phần Hạng mục: mặc định chỉ bổ sung một lần (mục đã xoá không quay lại); ẩn nhóm ẩn luôn hạng mục con thay vì xoá, hiện lại đúng những mục ẩn cùng lúc (nhóm không bao giờ trống); hạng mục cuối cùng không chuyển nhóm được; ẩn/xoá nhóm từ màn của nhóm thì màn tự quay về sau khi sheet đóng; "Đặt lại dữ liệu mẫu" lưu xong bước xoá rồi mới tạo lại hạng mục; thứ tự có tiêu chí phụ `createdAt`.
- "Hạng mục đã ẩn" dùng `NavigationRowLabel`, dòng phụ "Nhóm · Đã ẩn 29/10" / "Ăn uống · Đã ẩn 29/10"; hạng mục nằm trong nhóm đã ẩn không liệt kê riêng. Ô chọn nhóm có cả nhóm đang ẩn của chính hạng mục. Số ở Cài đặt chỉ đếm hạng mục đang dùng trong nhóm đang dùng; VoiceOver đọc "6 hạng mục". Dưới danh sách có một dòng ghi chú: hạng mục mới dùng được khi ghi giao dịch trong bản cập nhật tới.
- Rà soát Hạng mục lần 2:
  - Bấm "Ẩn …" / "Hiện lại …" lưu luôn tên và biểu tượng đang sửa trong form (trước đây mất).
  - 12 nhóm có sẵn (trùng `TransactionCategory`) chỉ ẩn, không xoá, vì form giao dịch cũ vẫn ghi vào chúng; nhóm đang ẩn vẫn chọn được ở form cũ cho tới khi nối form mới.
  - Hiện lại một hạng mục nằm trong nhóm đang ẩn thì hiện lại cả nhóm (cùng các mục ẩn cùng nhóm).
  - Ô "Nhóm" bị khoá ở hạng mục cuối cùng có chú thích "Hạng mục cuối cùng của nhóm nên không chuyển nhóm được."
  - Chữ: "Hiện lại nhóm/hạng mục"; "…, hoặc ẩn/xoá cả nhóm."; "Đặt lại dữ liệu mẫu" nhắc cả hạng mục.
  - "Hạng mục đã ẩn" xếp mục ẩn gần nhất lên đầu.
  - VoiceOver: dòng nhóm đọc "Ăn uống, 6 hạng mục" một lần (`NavigationRowLabel(spokenValue:)`), dòng Hạng mục ở Cài đặt cũng vậy.
- Rà soát Hạng mục lần 3:
  - Ghi chú dưới danh sách: "Thay đổi ở đây sẽ áp dụng khi ghi giao dịch từ bản cập nhật tới." (đổi tên, biểu tượng hay ẩn nhóm có sẵn chưa có tác dụng ở form giao dịch). Dùng `FormFooter`, cùng chú thích với `FormGroup`.
  - Mỗi loại (chi/thu) giữ ít nhất một nhóm: nhóm cuối vẫn có dòng "Ẩn/Xoá nhóm" nhưng hộp thoại chỉ giải thích, nút "OK" (`FormActionRow(canConfirm:)`, như `FormDestructiveRow`).
  - Biểu tượng "•••" và "+" (không có trong bảng, trông như nút "Xem tất cả"/"Thêm") đổi thành ô lưới (`dashboard-square-01`, "Khác" trong bảng) cho "Chi khác"/"Khác" và `money-add-02` cho "Thu khác"; dữ liệu cũ đổi khi mở app (`FinanceDatabase.replaceRetiredIcons`, cả tên Solar từ V1). Ngôi sao trong bảng giờ tên "Ngôi sao".
  - Tên tối đa 30 ký tự (`FormTextRow(maxLength:)`, `Category.maxNameLength`).
  - Không trùng tên: nhóm cùng loại, hạng mục cùng nhóm (không phân biệt hoa thường, có phân biệt dấu; tính cả mục đang ẩn). Lỗi đỏ dưới thẻ "Nhóm này đã có “Internet”." / "Đã có nhóm “Lương” (đang ẩn).", nút ✓ tắt. Gợi ý tên nhóm mới đổi thành "Du lịch" / "Vé máy bay".
  - Chuyển hạng mục sang nhóm khác: xếp sau mọi mục của nhóm đó, cả mục đang ẩn.
- Rà soát Hạng mục lần 4:
  - VoiceOver đọc dòng lỗi đỏ ngay khi nó hiện (`FormGroup` gửi `AccessibilityNotification.Announcement`), cho mọi form.
  - Nhóm cuối mỗi loại: khi có nhóm đang ẩn, câu giải thích thêm "…hoặc hiện lại một nhóm đã ẩn trước."
  - Trùng với mục đang ẩn: "Đã có nhóm “Lương”, đang ẩn trong Hạng mục đã ẩn."
  - Tên được gộp khoảng trắng thừa ("Ăn  sáng" thành "Ăn sáng", chỉ gặp khi dán) trước khi so trùng và lưu.
  - Bấm "Ẩn"/"Hiện lại" khi tên trống hoặc trùng: vẫn lưu biểu tượng mới, giữ tên và nhóm cũ.
- Rà soát Hạng mục lần 5: không cho đặt tên trùng tên hạng mục hệ thống ("Điều chỉnh số dư", `Category.reservedNames`), báo "“Điều chỉnh số dư” là tên dành cho hệ thống."

## Thêm giao dịch và chuyển khoản — 2026-10-29

- Nút thêm giao dịch: bỏ nút nổi đen ở trang Giao dịch (nhỏ, che số tiền). Thay bằng **nút + tròn tách riêng cạnh thanh tab** (`Tab(role: .search)` trên iOS 26, như nút Tìm kiếm của App Store), có ở mọi tab (người dùng chọn kiểu B trong 4 kiểu). Chọn nó không chuyển tab, chỉ mở sheet (`ContentView.tabSelection`). iOS 17 hiện thành tab thứ 5 "Thêm".
- Thêm khoản vay: nút + cạnh kính lúp, chỉ hiện khi đang ở "Vay nợ".
- Sheet `AddTransactionView`: Chi tiêu / Thu nhập / Chuyển khoản.
  - Chi/thu: Tên (gợi ý = tên hạng mục), **Hạng mục** (`CategoryPickerRow` → `CategoryPickerSheet`: tìm kiếm, "Gần đây" 4 mục, rồi từng nhóm với hạng mục con; người dùng chọn), Tài khoản, Ngày, Giờ, Ghi chú. Mặc định hạng mục dùng gần nhất và tài khoản dùng gần nhất (`transactions.lastAccountID`).
  - Giao dịch cũ ghi vào nhóm: "Hạng mục" đỏ, chú thích "Chọn hạng mục con cho giao dịch này.", ✓ tắt đến khi chọn.
  - Chuyển khoản: Từ, Đến, Phí, Ngày, Giờ, Ghi chú; chú thích "Không tính là thu hay chi." hoặc "Phí 5.000đ được ghi là khoản chi từ tài khoản nguồn.". Chỉ giữa tài khoản (không gồm hũ), cần hai tài khoản khác nhau chưa khoá. Sửa chuyển khoản không hiện thanh chọn loại.
- Danh sách Giao dịch: có cả chuyển khoản ("Chuyển khoản", "Ví tiền mặt → Vietcombank", số không dấu) và dòng phí ("Phí chuyển khoản", dòng phụ "Chuyển sang …"). Ô lọc "Chuyển khoản" giờ có dữ liệu. Chạm một dòng để sửa/xoá (như lịch sử tài khoản), bỏ menu nhấn giữ; dòng phí mở chuyển khoản của nó.
- Lịch sử tài khoản: "Chuyển đến MoMo" (−) / "Nhận từ Vietcombank" (+).

- Góp ý 2026-10-29 (sau bản đầu):
  - Giao dịch **không có tên**: bỏ ô "Tên", chỉ chọn hạng mục. Dòng hiện tên hạng mục ("Ăn trưa"); dòng phụ là ghi chú (dòng đầu), không có thì tên nhóm ("Ăn uống") (`FinanceStore.title(of:)`). Giao dịch cũ có tên vẫn giữ tên (mẫu, trợ lý AI).
  - Công tắc **"Không tính vào báo cáo"** cho chi/thu (`FinanceTransaction.isExcluded`, lưu ở `TransactionRecord.excluded`): vẫn đổi số dư, không tính vào tổng, biểu đồ, hạn mức, trợ lý; dòng phụ thêm "· Không tính"; bật lên thì chú thích "Vẫn tính vào số dư tài khoản.". Không có ở chuyển khoản và điều chỉnh số dư.
  - Sheet chọn hạng mục có **bút chì** góc trên: mở trang "Hạng mục" (đúng loại chi/thu) ngay trong sheet, thêm/sửa xong quay lại chọn luôn. Bỏ ghi chú "Thay đổi ở đây sẽ áp dụng… bản cập nhật tới" trong trang Hạng mục (đã nối).
  - Bỏ chú thích "Không tính là thu hay chi." của chuyển khoản; chỉ còn chú thích khi có phí.
  - Hạng mục **không tự chọn** (người dùng chọn 2026-10-29): dòng "Hạng mục" ghi "Chưa chọn"; đổi Chi tiêu ↔ Thu nhập thì bỏ chọn. Áp dụng cả "Dùng tiền".
  - Nút ✓ luôn bấm được (trừ khi chỉ xem): thiếu thì rung lỗi, giữ sheet và báo đỏ — "Nhập số tiền." dưới số tiền, "Hạng mục" đỏ và "Chọn hạng mục." dưới thẻ Chi tiết (như form tài khoản, `SheetScaffold(validate:)`). Dòng lỗi dùng `FormErrorText` (tách từ `FormGroup`, VoiceOver đọc khi hiện).
  - Sửa nháy khi mở sheet bằng nút +: nút + là một tab thật, nên iOS chuyển sang tab trống (màn trắng) rồi mới quay lại. Giờ `InstantTabSwitch` trả lời "không chọn" cho tab đó (`shouldSelectTab` iOS 18+, `shouldSelect` iOS 17) và mở sheet luôn; trang đang xem đứng yên phía sau. Việc sheet giãn ra full màn hình khi bàn phím số tiền mở là của iOS 26, giống mọi sheet có ô số tiền.
- Rà soát sheet thêm giao dịch lần 1:
  - Chuyển khoản dính tài khoản đã khoá: chỉ xem, "Tài khoản đã khoá. Mở khoá để sửa." (`FinanceStore.lockedReason`), thay vì lưu không được mà không báo.
  - Không có tài khoản dùng được: báo đỏ ngay "Chưa có tài khoản để ghi. Thêm tài khoản ở tab Tài khoản."
  - Câu báo hạng mục theo đúng lý do: "Chọn hạng mục." (chưa chọn, hiện sau ✓), "Chọn hạng mục thu nhập/chi tiêu." (đổi loại khi sửa), "Chọn hạng mục con cho giao dịch này." (giao dịch cũ ghi vào nhóm), "“X” không còn dùng được. Chọn hạng mục khác." (đã ẩn/xoá). Ba lý do sau hiện ngay vì dòng đã đỏ.
  - Ô Phí dùng `FormAmountRow` (có "đ"), như các ô số tiền phụ khác.
  - Hai hạng mục cùng tên trong cùng loại: dòng "Hạng mục" ghi kèm nhóm ("Mua sắm · Khác").
  - Giao dịch cũ có tên riêng: đổi hạng mục thì bỏ tên cũ, từ đó hiện tên hạng mục như giao dịch mới.
- Rà soát sheet thêm giao dịch lần 2:
  - Sửa giao dịch cũ có hạng mục đã ẩn: hạng mục đó vẫn hợp lệ (`CategoryPickerRow(kept:)`), không bắt chọn lại; nó chỉ không có trong danh sách chọn.
  - Chuyển khoản: chọn ở "Từ" tài khoản đang ở "Đến" (hoặc ngược lại) thì hai bên tự đổi chỗ.
  - Đổi Chi tiêu ↔ Thu nhập khi thêm mới: nhớ hạng mục đã chọn cho từng loại, quay lại thì còn.
  - Dòng phí ghi "Chuyển sang [tên tài khoản hiện tại]" (đổi tên tài khoản thì đổi theo).
  - "Gần đây" xếp theo lúc ghi (`FinanceTransaction.createdAt`, từ `TransactionRecord.createdAt`), không theo ngày của giao dịch.
  - "Dùng tiền" bỏ ô "Dùng vào" (người dùng chọn): giao dịch không tên như mọi giao dịch, ghi chú đóng hũ theo hạng mục ("Đã dùng: Mua xe máy").
- Rà soát sheet thêm giao dịch lần 3:
  - Bấm + khi đang xem một tài khoản: form chọn sẵn tài khoản đó (`AddTransactionContext`, `AccountDetailView` đặt khi hiện, bỏ khi ẩn hoặc chuyển tab); ở chỗ khác vẫn là tài khoản dùng lần trước.
  - "Không tính vào báo cáo" trên khoản chi từ hũ: chú thích "Vẫn tính vào số tiền trong hũ."
  - Một hàm bỏ dấu dùng chung `String.searchKey` (tìm hạng mục, tìm ngân hàng, trợ lý), thay cho hai bản riêng.

## VIỆC ĐỂ SAU — sheet giao dịch trong ngày (Tổng quan)

- Ý người dùng (2026-10-29): để sau. `DayTransactionsSheet` (chạm một ngày ở "Lịch thu chi") chưa giống trang Giao dịch: các dòng không chạm để sửa/xoá được và không có chuyển khoản. Khi làm: dùng `ActivityRow` + `AccountDetailView.activity(transactions:accountTransfers:)` như `TransactionsView`, mở `ActivityEditor`.

## Sheet xem giao dịch — 2026-10-29

- Chạm một giao dịch (chi/thu) ở trang Giao dịch, lịch sử tài khoản hay hũ: mở `TransactionDetailSheet` để **xem** thay vì vào thẳng form; bút chì trên thanh mở form sửa (form vẫn có "Xoá giao dịch"), như trang tài khoản và hũ. Xoá xong thì sheet tự đóng. Nạp/rút hũ vẫn mở thẳng form; chuyển khoản có sheet xem riêng (`TransferDetailSheet`, từ 2026-10-29).
- Bố cục: biểu tượng hạng mục, tên (tên hạng mục, hoặc tên riêng của giao dịch cũ, khi đó hạng mục ghi nhỏ ngay dưới: "Bún chả" / "Ăn trưa"), số tiền lớn có dấu; "Không tính vào báo cáo" / "Tài khoản đã khoá · Không tính" thành badge khi có. Thẻ "Chi tiết": **Nhóm hạng mục** ("Ăn uống", kèm biểu tượng nhóm; người dùng chọn, vì hạng mục đã là tiêu đề phía trên; không có ở điều chỉnh số dư và phí), Tài khoản (kèm logo), Thời gian ("Hôm qua, 28/10 · 12:15"); chú thích lý do khi chỉ xem được. "Ghi chú" khi có (chọn để sao chép được).
- **"Cùng hạng mục"** (người dùng yêu cầu): tối đa 5 giao dịch khác cùng hạng mục, mới nhất trước. Mỗi dòng: logo tài khoản, ngày, dòng phụ "[tên riêng hoặc ghi chú] · [tài khoản]", số tiền, giờ. Chạm một dòng đẩy sang xem giao dịch đó trong cùng sheet (‹ quay lại; chỉ màn đầu có ✕). Không có giao dịch nào khác thì không hiện mục này.
- `FormValueLabel(showsChevron: false)` cho các dòng chỉ xem.
- Đồng nhất dòng chọn (2026-10-29): `FormPickerRow` có `optionIcon` thì dòng hiện luôn biểu tượng/logo của lựa chọn đang chọn trước tên, như "Hạng mục". Áp dụng: Tài khoản, Từ, Đến (thêm/sửa giao dịch), "Về tài khoản" / "Từ tài khoản" (nạp, rút, dùng tiền hũ), "Nhóm" (sửa hạng mục).

## Chuyển khoản: bỏ dòng phí, thêm sheet xem — 2026-10-29

- Không còn dòng "Phí chuyển khoản" riêng (người dùng chọn): phí nằm trên chuyển khoản, nguồn trả số tiền + phí. Phí vẫn tính vào chi tiêu (tổng tháng, ~~tổng ngày~~ — bỏ ở lần rà soát 3, biểu đồ, lịch thu chi, hạn mức, chi theo hạng mục, trợ lý); số "Đã chi · N" chỉ đếm dòng có trong danh sách. Dòng phí cũ được gộp khi mở app.
- Dòng chuyển khoản: trang Giao dịch "Ví tiền mặt → Vietcombank" (số tiền không dấu; phí chỉ có trong sheet xem, người dùng chọn); lịch sử tài khoản nguồn "Chuyển đến …" trừ cả phí, dòng phụ "Gồm phí 9.000đ"; tài khoản đích "Nhận từ …" cộng số tiền.
- Form: chú thích phí "Phí 9.000đ trừ thêm vào Ví tiền mặt và tính là chi tiêu."; xoá chuyển khoản chỉ còn "Số dư hai tài khoản sẽ được tính lại."
- **Sheet xem chuyển khoản** (`TransferDetailSheet`), cùng kiểu với chi/thu: biểu tượng, "Chuyển khoản", số tiền; Chi tiết: Từ, Đến (kèm logo), Phí (khi có), Thời gian, chú thích "Phí tính là chi tiêu của …"; Ghi chú khi có. Bút chì mở form sửa; xoá xong thì đóng; chuyển khoản dính tài khoản khoá/lưu trữ thì chỉ xem, chú thích lý do.
- Chạm giao dịch hoặc chuyển khoản **chỉ xem được** giờ cũng mở sheet xem (không bút chì, có lý do), thay cho hộp thoại "Không sửa được". Nạp/rút hũ vẫn như cũ.
- Sửa giao dịch (2026-10-29): đổi Chi tiêu → Thu nhập thì hạng mục trống ("Chưa chọn"), đổi về thì hạng mục cũ trở lại, như khi thêm mới.
- Rà soát sheet xem/sửa giao dịch lần 2:
  - Hai sheet xem mở đầu bằng `SummaryCard` căn trái như trang tài khoản và hũ (người dùng chọn): thanh trên ghi tên giao dịch ("Bún chả") hoặc "Chuyển khoản"; thẻ ghi "Chi tiêu"/"Thu nhập"/"Số tiền chuyển", số tiền, biểu tượng bên phải; dưới số tiền là hạng mục khi giao dịch có tên riêng, và badge "Không tính" khi có. Khung chung `DetailScaffold`; dòng chỉ xem `FormInfoRow`, ghi chú chỉ xem `FormNoteText` (design system).
  - Chuyển khoản có tài khoản đã khoá sửa được như giao dịch thường: tài khoản khoá giữ được ở đúng phía của nó, không chọn được cho chuyển khoản mới.
  - Trợ lý AI mở sheet xem thay vì form sửa.
  - Ngày của năm khác ghi năm ("Thứ Ba, 27/10/2025"), ở mọi chỗ dùng tiêu đề ngày.
  - Khoản chi từ hũ ghi nhãn "Hũ". "Cùng hạng mục" của điều chỉnh số dư gồm cả hai chiều.
  - Chuyển khoản chỉ xem được: chú thích hiện cả lý do lẫn câu về phí.
- Giao dịch **không có tên riêng** nữa, ở mọi chỗ (người dùng chọn 2026-10-29): tên là hạng mục ("Ăn trưa", thanh trên của sheet xem, dòng trong danh sách). Tên cũ của dữ liệu mẫu và trợ lý ("Bún chả") được chuyển vào **ghi chú** khi mở app (`FinanceStore.moveTitlesToNotes`, đứng trước ghi chú đã có), nên vẫn hiện ở dòng phụ và trong "Ghi chú". Dữ liệu mẫu và trợ lý từ nay ghi mô tả vào ghi chú; tìm kiếm theo hạng mục và ghi chú.
- Rà soát sheet xem/sửa giao dịch lần 3: thẻ đầu của điều chỉnh số dư ghi "Điều chỉnh số dư" (người dùng chọn), không ghi "Thu nhập"/"Chi tiêu"; thẻ giao dịch trong trợ lý AI có dòng phụ là ghi chú (hoặc nhóm) · ngày, không lặp hạng mục; khoản chi từ hũ đã xoá ghi nhãn "Hũ"; `FinanceTransaction(title:)` mặc định rỗng.

## Trang Giao dịch: tìm kiếm, card tổng quan, chọn tháng — 2026-10-29

- **Tìm kiếm** (người dùng chọn): bấm kính lúp thì ô tìm của iOS hiện, thanh Thu chi/Vay nợ, card tổng quan và chip lọc ẩn đi. Chưa gõ: "Hạng mục gần đây" (chạm để tìm theo hạng mục). Đang gõ: kết quả ở **mọi tháng**, gộp theo ngày, khớp hạng mục, nhóm, ghi chú, tài khoản (chuyển khoản: hai tài khoản, ghi chú, "chuyển khoản"), không phân biệt dấu. Vay nợ khi tìm: hiện mọi mục khớp, không card, không chip.
- **Card tổng quan** thấp hơn (người dùng chọn): nút tháng lên đầu thẻ bên trái (bỏ hàng trống), Đã chi/Đã thu ngay dưới, biểu đồ cao 44 (trước 64), hạn mức một dòng chữ nhỏ "Đã dùng 47% hạn mức" + thanh; đệm thẻ 16.
- **Biểu đồ theo ngày**: chạm một cột là chọn ngay (`SpatialTapGesture` trên `chartOverlay`), kéo ngang để dò; kéo dọc vẫn cuộn trang. Thay `chartXSelection` (trong ScrollView nó chờ nhấn giữ và làm sáng cột trước khi nhận). Đổi tháng thì bỏ chọn.
- **Chọn tháng**: nút mở `MonthPickerSheet` (người dùng chọn) thay vì menu: năm với ‹ ›, lưới 12 tháng "T1…T12", tháng đang chọn đen, tháng chưa tới mờ và không chọn được, "Tháng này" khi đang ở tháng khác; chạm là chọn và đóng. Bỏ menu cũng hết việc bóng của nút phải chờ mới hiện lại.
- **Đổi chip lọc hoặc tháng**: danh sách mờ dần sang nội dung mới và trượt nhẹ lên (12pt).
- Góp ý sau bản đầu (2026-10-29):
  - Mở/đóng tìm kiếm: nội dung trang mờ dần hiện ra sau ô tìm (trễ 0,12 giây, 0,28 giây, trượt 10pt), không hiện ngay ("Hạng mục gần đây" xuất hiện sau ô tìm).
  - Đổi chip sang danh sách ngắn hơn: danh sách luôn cao ít nhất bằng màn hình nên trang không bị kéo giật về; nếu đang cuộn xuống dưới chip thì trang trượt mượt về hàng chip.
  - ~~Nút tháng màu accent (lime, kính nổi), chữ đen.~~ — 2026-10-29: đổi sang kính mặc định của iOS như nút tìm (người dùng chọn): `GlassCapsule`, `.glassEffect(.regular.interactive())`; iOS 17–18 là viên xám nhạt `Palette.fill3`.
- Góp ý lần 2 (2026-10-29):
  - Tìm kiếm dùng nút gốc của iOS 26: `.searchable(placement: .toolbar)` + `.searchToolbarBehavior(.minimize)`; nút kính lúp của hệ thống nở thành ô tìm ngay trên thanh và thu về khi đóng (như app của Apple). iOS 17–18 vẫn dùng nút riêng của trang. Khi tìm, tiêu đề "Giao dịch" và nút tháng ẩn khỏi thanh.
  - Nút tháng lên thanh trên, bên trái nút tìm (người dùng chọn), chỉ ở "Thu chi"; card tổng quan bắt đầu ngay bằng Đã chi/Đã thu.
  - Bộ lọc trong tìm kiếm: hàng chip Tất cả / Thu / Chi / Chuyển khoản riêng cho tìm kiếm (đóng tìm thì về Tất cả). Chưa gõ: "Hạng mục gần đây" theo loại đã chọn; "Chuyển khoản" khi chưa gõ thì liệt kê mọi chuyển khoản.
- Góp ý lần 3 (2026-10-29):
  - Nút tháng tự vẽ viên kính lime cao 44pt (`LimeCapsule`, `.glassEffect(.regular.tint(lime).interactive())`) vì kiểu nút kính trong toolbar bị ép thấp hơn nút kính lúp; chữ một dòng.
  - **Bộ lọc tìm kiếm** (`TransactionSearchFilter`, `TransactionFilterSheet`): nút "Bộ lọc" dưới ô tìm (đen kèm số khi đang bật, bên cạnh là tóm tắt "Chi · MoMo" và × để bỏ). Sheet: Loại (4 chip, thay hàng chip cũ trong tìm kiếm), Khoảng thời gian (Mọi lúc / Tháng này / Tháng trước / 30 ngày qua / Tuỳ chọn với Từ ngày–Đến ngày), Số tiền Từ–Đến (báo lỗi khi Từ > Đến), Tài khoản (chọn nhiều, gồm cả tài khoản lưu trữ), Nhóm hạng mục (chọn nhiều, theo loại), "Đặt lại bộ lọc". Áp dụng khi bấm ✓. Có bộ lọc mà chưa gõ chữ thì hiện mọi giao dịch khớp bộ lọc.
  - **Lịch sử tìm kiếm** thay "Hạng mục gần đây": "Tìm kiếm gần đây" tối đa 8 (mới nhất trên), lưu khi bấm Tìm trên bàn phím hoặc khi mở một kết quả; chạm để tìm lại, × để xoá một mục, "Xoá" để xoá hết. Chưa có lịch sử: dòng gợi ý cách tìm.
  - Ô tìm tắt tự sửa chính tả. (Thanh trên vẫn dùng `HiddenToolbarTitle` giữ chỗ tiêu đề: `toolbar(removing:)` cần iOS 18.)
  - **Chưa sửa được**: lần đầu mở ô tìm (thu gọn, iOS 26) có một mảng trắng mờ sau chữ gợi ý; gõ chữ rồi xoá thì mất. Đã thử bỏ tiêu đề, đổi chữ gợi ý, tắt tự sửa, đổi vị trí ô tìm, bỏ vai trò tìm kiếm của nút + — vẫn còn, nên có vẻ do chính ô tìm của iOS 26.
- **Màn tìm kiếm riêng** (người dùng chọn 2026-10-29, như các app ngân hàng), thay cho ô tìm của iOS trên thanh (bỏ `OnDemandSearch` và mảng trắng của nó): kính lúp trên thanh mở `TransactionSearchView` phủ toàn màn hình (`fullScreenCover`), trang Giao dịch phía sau đứng yên.
  - Trên cùng: ô tìm tự làm (viên trắng viền mảnh, kính lúp, nút xoá chữ, tắt tự sửa, phím "Tìm") và nút ✕ kính để đóng; bàn phím mở luôn.
  - Hàng chip: "Bộ lọc" (đen kèm số khi bật) rồi mỗi điều kiện đang bật một chip có × để bỏ riêng ("Chi ×", "Tháng này ×", "MoMo ×"); chạm chip mở sheet Bộ lọc. Chip thường (không kính) để không có quầng sáng; chỉ cuộn ngang khi tràn.
  - Chưa gõ, chưa lọc: "Tìm kiếm gần đây". Có chữ hoặc bộ lọc: kết quả mọi tháng gộp theo ngày (`ActivityDayList`, dùng chung với trang Giao dịch); chạm để xem.
  - Từ "Vay nợ": màn tìm tìm khoản vay.
  - Chip lọc nhanh cạnh "Bộ lọc" (2026-10-29, để nút không đứng một mình): "Chi", "Thu", "Chuyển khoản" khi chưa chọn loại, "Tháng này" khi chưa chọn thời gian; viền mảnh chữ xám, chạm một lần là bật (thành chip có ×), các chip cùng loại tự ẩn.
  - Màn tìm trượt lên bằng `fullScreenCover` của iOS; bàn phím mở sau 0,45 giây (khi màn đã trượt xong) vì mở bàn phím ngay lúc trượt làm cú trượt khựng gần cuối.
- Rà soát trang Thu chi lần 1 (agent, 2026-10-29), đã sửa:
  - Chip nhanh Thu/Chi/Chuyển khoản dùng `TransactionSearchFilter.setKind` như sheet: bỏ nhóm hạng mục không hợp loại.
  - ~~Phí chuyển khoản vẫn vào tổng ngày khi lọc "Chi"~~ — bỏ ở lần 3 (người dùng chọn: mỗi loại một chuyện).
  - Không cho chọn ngày sau hôm nay khi ghi giao dịch, chuyển khoản, nạp/rút hũ, dùng tiền hũ (`FormDateRow(latest:)`, người dùng chọn). "Tháng này" trong bộ lọc tính cả tháng; biểu đồ vẽ cột thật cho ngày sau hôm nay nếu có tiền (dữ liệu cũ).
  - Màn tìm có `NavigationStack` riêng: thẻ nợ thẻ tín dụng trong tìm "Vay nợ" mở được tài khoản.
  - Nút tháng: cả viên nhận chạm; iOS 17–18 là viên lime thường (trước nền đen chữ đen). Nút "Năm trước" dừng ở năm có giao dịch cũ nhất.
  - "Đã chi · N"/"Đã thu · N" đếm đúng số dòng mà chip Chi/Thu liệt kê (cả dòng không tính, trừ điều chỉnh số dư; người dùng chọn).
  - Danh sách trống nói theo chip và tháng ("Tháng 9 chưa có khoản thu"); lời mời "Thêm giao dịch đầu tiên" chỉ khi chưa có gì.
  - Kỳ "Tuỳ chọn": báo lỗi đỏ khi Từ ngày sau Đến ngày; chip ghi năm khi khác năm nay.
  - Lịch sử tìm kiếm bỏ trùng không phân biệt dấu ("an sang" = "Ăn sáng").
  - Vùng chạm: × trên chip 32×36, × lịch sử 44×44, cả viên chip mở Bộ lọc.
  - Màn tìm dựng kết quả lười (`LazyVStack`) và tra hạng mục/tài khoản qua bảng dựng một lần mỗi lần tìm.
  - Thành phần mới của design system: `SearchField` (ô tìm tự vẽ), `TagChip` (chip thường / gợi ý / có × / nổi đen). Số gõ tay đổi sang token (`Spacing`, `ControlHeight`, `RowMetrics`); danh sách theo ngày dùng `listCard()`. Bỏ `summary(in:)` không dùng.
- Rà soát trang Thu chi lần 2 (agent, 2026-10-29), đã sửa:
  - Chip Thu/Chi không còn liệt kê "Điều chỉnh số dư" (tổng cũng không tính nó); chỉ "Tất cả" có. Số "Đã chi · N"/"Đã thu · N" đếm đúng các dòng chip liệt kê.
  - Gõ "phí" trong màn tìm ra chuyển khoản có phí.
  - Tìm nhiều từ, không cần đúng thứ tự ("phong trua" ra "Cơm trưa văn phòng"); tìm "Vay nợ" cũng bỏ dấu và dấu cách thừa như "Thu chi".
  - Không có kết quả khi đang bật bộ lọc: "…khớp với “grab” và bộ lọc."
  - Bộ lọc tính một lần mỗi lượt tìm (`TransactionSearchFilter.Matcher`: khoảng ngày, nhóm của hạng mục), không tính lại cho từng giao dịch.
  - Để app qua đêm: sang ngày mới thì cột hôm nay đổi theo, đang xem tháng vừa hết thì chuyển sang tháng mới (`NSCalendarDayChanged`, khi app trở lại).
  - Biểu đồ: vuốt dọc từ biểu đồ vẫn cuộn trang. iOS 18 trở lên dùng một pan UIKit chỉ nhận khi bắt đầu sang ngang; iOS 17 giữ `DragGesture`.
  - `TagChip`, `SearchField`, nút tháng cao lên theo cỡ chữ (chiều cao tối thiểu thay vì cố định).
  - VoiceOver đọc "Đã chi 14.128.000 đ, 23 giao dịch".
- Rà soát trang Thu chi lần 3 (agent, 2026-10-29), đã sửa:
  - Mỗi chip một chuyện (người dùng chọn): Chi/Thu chỉ có giao dịch chi/thu, Chuyển khoản chỉ có chuyển khoản, Tất cả có cả hai. Phí chuyển khoản ở với chuyển khoản (sheet xem), không lên chip Chi và không cộng vào tổng ngày, ở trang lẫn màn tìm. Thẻ "Đã chi" vẫn là số báo cáo nên vẫn gồm phí (như Tổng quan).
  - Tìm "Vay nợ": chỉ hiện mục có kết quả; không có gì thì một thẻ "Không tìm thấy" (trước là các thẻ trống lần đầu, có thẻ chỉ tới nút + màn tìm không có).
  - Đếm "Đã chi · N"/"Đã thu · N" thẳng trên giao dịch của tháng, không dựng danh sách; `DayTotals` lọc dòng tính một lần.
  - Đổi tháng khi chip vừa khuất dưới thanh: đo trong không gian của ScrollView nên trang cuộn về chip.
  - Thông báo sang ngày mới nhận trên luồng chính (`receive(on: RunLoop.main)`).
- Rà soát trang Thu chi lần 4 (agent, 2026-10-29), đã sửa:
  - Giữ: thẻ tổng quan (số "Đã chi" và biểu đồ) là số báo cáo nên gồm phí chuyển khoản; tổng ngày của danh sách thì không. Ấn cột một ngày chỉ có phí sẽ thấy số phí, còn danh sách Chi ngày đó trống — có chủ ý.
  - VoiceOver đọc tổng ngày thành chữ ("Thu 1.200.000 đ, chi 55.000 đ"); nút "Xoá" lịch sử đọc "Xoá lịch sử tìm kiếm".
  - Tìm "Vay nợ" khi chưa gõ: một dòng gợi ý như "Thu chi", không liệt kê hết; chỉ gõ dấu cách cũng tính là chưa gõ.
  - `ActivityDayList` chuyển sang `FlowRows.swift` cạnh `DayTotals`; bỏ `loanFilter` không dùng trong màn tìm; sửa các chú thích cũ (nút tháng màu chanh, tìm Vay nợ, dòng mở sheet xem).
- Rà soát lần cuối (agent, 2026-10-29): sẵn sàng commit. Sửa thêm: lịch chọn ngày chặn tới hết hôm nay (không phải giây hiện tại), nên giờ đã đặt muộn hơn bây giờ không bị kéo về; chip lọc đang bật có gợi ý VoiceOver "Mở bộ lọc" (`TagChip(hint:)`).

## Vay nợ: bỏ thẻ tín dụng, thẻ gọn, tìm và lọc như Thu chi — 2026-10-29

- Vay nợ chỉ còn khoản vay với người (người dùng chọn): dư nợ thẻ tín dụng không còn ở mục Đi vay, ô "Đang nợ" hay "Cần chú ý" (nhắc trả thẻ ở với Tài khoản). Tổng quan và Trợ lý vẫn tính nợ thẻ (`totalDebt`). Bỏ `CreditCardDebtCard`.
- Thẻ tổng quan (`LoansSummaryCard`, người dùng chọn "số ròng + 2 ô"): nhãn "Chênh lệch" (người dùng đổi từ "Cho vay trừ nợ") và số ròng; dưới đó thanh phân bổ (`SplitBar`: xanh lá phần cho vay, đỏ phần đang nợ, mỗi bên có tiền giữ tối thiểu 8pt, chưa có gì thì một thanh xám); rồi hai ô "Cho vay · 80tr · 2 người", "Đang nợ · 12tr · 3 khoản", mỗi ô có chấm màu như thanh để làm chú giải. Bỏ câu giải thích dài. Số "Đang nợ" chỉ đỏ khi còn nợ. VoiceOver đọc thanh "Cho vay 80%, đang nợ 20%" và mỗi ô thành một câu.
- Chip Tất cả / Cho vay / Đi vay (bỏ "Đã tất toán", người dùng chọn) có hiệu ứng như Thu chi: danh sách mờ dần sang chip mới, giữ tối thiểu một màn hình cao, đã cuộn xuống thì trượt về hàng chip.
- Tìm Vay nợ giống tìm Thu chi: hàng chip "Bộ lọc" + gợi ý Cho vay / Đi vay; chip đang bật có ×. Bộ lọc (`LoanFilterSheet`, sheet vừa nội dung) chỉ có Loại (người dùng chọn). Lịch sử tìm kiếm riêng (`loans.searchHistory`), lưu khi bấm Tìm hoặc mở một khoản vay. Không có kết quả: "…khớp với bộ lọc" / "…khớp với “Minh” và bộ lọc".
- Màn tìm bỏ `NavigationStack` riêng (chỉ để mở thẻ tín dụng).

## Vay nợ: form thêm khoản vay mới — 2026-10-29

- Trang Vay nợ bỏ mục "Cần chú ý" (người dùng chọn); nhắc hạn vẫn ở Tổng quan.
- Form (`LoanEditorView`):
  - Người vay / Người cho vay chọn từ Danh bạ (`ContactPickerSheet`, người dùng chọn): mọi người A→Z kèm icon và tên mối quan hệ, rồi "Thêm người mới" là dòng cuối của danh sách như sheet chọn mối quan hệ (người dùng chọn; mở form Danh bạ rồi chọn luôn người vừa lưu). Ô tìm là `.searchable` của hệ thống như sheet chọn ngân hàng/hạng mục: iOS 26 đặt ở dưới cùng (người dùng chọn), iOS cũ dưới tiêu đề. Dòng trên form hiện icon mối quan hệ cạnh tên, "Chọn" khi chưa có.
  - Bỏ dòng "Còn phải thu/trả". Bật "Khoản có sẵn" (có từ trước khi dùng Timi, không đổi số dư) thì hiện nhóm "Đã trả" với "Còn lại" (trống = chưa trả đồng nào). Tắt thì là khoản mới: nhóm "Tiền đi" (cho vay, "Chi từ") hoặc "Tiền về" (đi vay, "Nhận vào") chọn tài khoản, và ngày cho vay / ngày vay (không sau hôm nay).
  - Lãi suất: "% mỗi tháng" (người dùng chọn), tính trên số gốc, tháng nào cũng như nhau; chân nhóm tính sẵn "Mỗi tháng 375.000đ, tính trên số gốc.".
  - "Có hạn trả" bật/tắt thì dòng "Hạn trả" trượt vào/ra; đổi "Khoản có sẵn" cũng có hiệu ứng.
  - Bấm ✓ khi thiếu: báo đỏ "Nhập số tiền gốc." và "Chọn người vay." (như form thêm giao dịch).
- Khoản mới đổi số dư: cho vay trừ, đi vay cộng; sửa thì hoàn lần cũ rồi áp lần mới, xoá thì hoàn lại. Hiện ở "Thu chi" chip Tất cả và lịch sử tài khoản (`LoanMoveRow`: "Cho vay · Mẹ · Ví tiền mặt −25.000.000đ", chữ đen) nhưng không tính vào Đã chi/Đã thu, biểu đồ, tổng ngày (người dùng chọn). Chạm vào mở `LoanMoveSheet` chỉ để xem; sửa/xoá ở tab Vay nợ. Tìm kiếm Thu chi tìm được theo người, "cho vay"/"đi vay", tài khoản.
- Database V6 (`TimiSchemaV6`): thêm `isExisting` (dòng cũ = có sẵn), `accountID`, `loanDate`, `monthlyInterestRate` vào `LoanRecord`.

## Vay nợ: khoản đã tất toán có lối vào riêng — 2026-10-29

- Bỏ chip "Đã tất toán" ở trang và ở Bộ lọc tìm kiếm (người dùng chọn); `LoanFilter` chỉ còn Tất cả / Cho vay / Đi vay.
- Cuối trang Vay nợ, ở mọi chip, khi có khoản tất toán: dòng "Khoản vay đã tất toán · N ›" (icon huy hiệu tích như "Hũ đã hoàn thành"), mở `SettledLoansView` (thẻ khoản vay, mới nhất trước; chạm để mở form). Tìm kiếm vẫn hiện mục "Đã tất toán" khi khớp.

## Rà soát sheet thêm khoản vay lần 1 (agent, 2026-10-29), đã sửa:

- Khoản mới đã thu/trả một phần: số tiền gốc nhỏ hơn số đã thu/trả thì báo đỏ ngay dưới số tiền ("Số tiền gốc không nhỏ hơn số đã thu (30.000.000đ).") thay vì lặng lẽ thành "đã tất toán".
- Lãi suất: gõ tới đâu sửa tới đó (chỉ số, một dấu phẩy, dấu chấm thành phẩy, tối đa 3 chữ số trước và 2 số lẻ), nên không còn số âm, chữ hay số lẻ bị làm tròn khi mở lại; trên 100 vẫn báo đỏ.
- Hạn trả của khoản mới không trước ngày cho vay/ngày vay: lịch chặn từ ngày đó, đổi ngày cho vay sau hạn trả thì nhóm "Hạn trả" báo đỏ.
- Bật/tắt "Khoản có sẵn" giữ số còn lại: "Còn lại" vừa gõ thành số đã thu/trả của khoản mới, và ngược lại.
- VoiceOver gọi ô số tiền lớn theo nhãn của nó (`TimiAmountField(label:)`, mặc định "Số tiền"; form khoản vay là "Số tiền gốc").
- Nhóm "Đã trả" đổi thành "Còn phải thu" / "Còn phải trả" cho khớp dòng "Còn lại".
- Rà soát sheet thêm khoản vay lần 2 (agent, 2026-10-29), đã sửa:
  - Bật/tắt "Khoản có sẵn": "Còn lại" trống là chưa trả đồng nào (khoản mới thành chưa thu/trả); khoản đã trả đủ bật lên thì "Còn lại" là 0.
  - Câu lỗi theo dạng quy tắc: "Số tiền gốc không được nhỏ hơn số đã thu (…)", "Hạn trả phải sau ngày cho vay."
  - Hạn trả của khoản mới từ hôm sau ngày cho vay trở đi (người dùng chọn "sửa hết", theo ghi chú "hạn bắt đầu từ ngày mai" của `FormDateRow`).
  - Số tiền gốc dùng `SheetAmountHeader` như các sheet tiền khác; VoiceOver đọc "Số tiền gốc" một lần (`SheetAmountHeader(fieldSaysCaption:)`).
  - "Còn lại" đỏ khi sai (`FormAmountRow(isInvalid:)`).
  - Tìm "Tuan" không thấy rồi "Thêm người mới": form Danh bạ điền sẵn tên đã tìm (`ContactEditorView.Target.new(name:)`).
- Rà soát sheet thêm khoản vay lần 3 (agent, 2026-10-29): sẵn sàng commit. Sửa thêm: tên điền sẵn cắt còn 40 ký tự như khi gõ; lịch chọn ngày mở với ngày ngoài khoảng cho phép (hạn trả trước ngày cho vay) thì bắt đầu ở ngày gần nhất được chọn, nên ✓ là sửa luôn. Giữ tên đúng như đã gõ khi tìm (không tự viết hoa).

## Vay nợ: thẻ khoản vay mới, badge theo hạn, khoản gấp lên trước — 2026-10-29

- Thẻ (`LoanCard`): chữ cái đầu, tên, dòng phụ "Hạn 6/11 · Lãi 375k" (không hạn thì tên mối quan hệ); badge ở góc phải theo hạn; dòng "Còn 45tr / 75tr" (đỏ khi đi vay) và "Đã trả 40%"; thanh tiến độ. Khoản quá hạn thêm viền đỏ nhạt. Bỏ `DebtCardLayout`.
- Mức hạn (`LoanUrgency`, mình chọn, đổi được): quá hạn → đỏ "Quá hạn 3 ngày"; hôm nay đến 7 ngày → cam "Đến hạn hôm nay" / "Còn 3 ngày"; 8–30 ngày → xám; trên 30 ngày → xanh lá; không có hạn → xám "Không có hạn"; tất toán → xanh lá "Đã tất toán". Thanh tiến độ cũng đỏ/cam khi quá hạn/sắp đến hạn.
- `BadgeTone.caution` mới: nền cam nhạt (`Palette.warning` 16%), chữ cam đậm cho dễ đọc. `warning` đổi tên hiển thị thành "Quá hạn".
- Mục Cho vay và Đi vay xếp khoản gấp lên trước: quá hạn lâu nhất, rồi hạn gần nhất, không có hạn cuối cùng; cùng hạn thì khoản còn nhiều hơn trước.

## Vay nợ: sheet xem khoản vay và ghi nhận thu/trả nợ — 2026-10-29

- Chạm một khoản vay (trang, màn tìm, "Khoản vay đã tất toán") mở `LoanDetailSheet` để xem trước (người dùng chọn); bút chì mở form sửa. Thứ tự: thẻ "Còn phải thu/trả" (badge hạn, thanh tiến độ, "Gốc …"); "Ghi nhận thu nợ / trả nợ" (ẩn khi đã tất toán); nhóm "Lãi" (Mỗi tháng · Tháng này đã/chưa thu/trả · Đã thu/trả tổng cộng); "Chi tiết" (người, tài khoản và ngày nếu là khoản mới, hoặc "Khoản có sẵn", hạn trả); "Lịch sử thu/trả nợ" (chạm để sửa/xoá).
- `LoanPaymentSheet` (người dùng chọn tách gốc và lãi, chọn tài khoản): Tiền gốc (chip "Hết 45tr"), Tiền lãi (điền sẵn lãi tháng nếu tháng này chưa thu/trả), Nhận vào / Chi từ, Ngày (không sau hôm nay, không trước ngày cho vay). Gốc không lớn hơn số còn lại. Chân nhóm: "Còn lại sau lần này: …" / "Lần này trả hết khoản vay." + "Tiền lãi tính là thu nhập/chi tiêu."
- Tiền: thu nợ cộng gốc + lãi vào tài khoản, trả nợ trừ ra; gốc trừ vào "Còn lại" (về 0 là tất toán). Gốc không tính là thu/chi; lãi là "Lãi cho vay" (thu nhập) / "Lãi đi vay" (chi tiêu), hệ thống, vào báo cáo như phí chuyển khoản (`interestTransactions`), không có dòng riêng.
- Dòng thu/trả nợ (`LoanPaymentRow`) ở chip Tất cả của Thu chi, màn tìm và lịch sử tài khoản: "Thu nợ · Mẹ · Ví tiền mặt +25.375.000đ"; chạm mở sheet khoản vay. Tổng ngày không cộng lãi (thẻ tổng quan là số báo cáo, như phí).
- Bỏ "Đánh dấu đã tất toán" khỏi form sửa (tất toán bằng một lần thu/trả hết). Khoản có lần thu/trả thì không đổi được Cho vay ↔ Đi vay. Xoá khoản vay xoá cả các lần thu/trả và hoàn số dư. Tài khoản có khoản vay hoặc lần thu/trả thì chỉ lưu trữ được, không xoá.
- Database V7: bảng `LoanPaymentRecord`.
- Rà soát trang Vay nợ (agent, 2026-10-29), đã sửa:
  - Khoản có sẵn đã có lần thu/trả: "Còn lại" để trống là gốc trừ phần đã thu/trả qua Timi; gõ cao hơn thì báo "Đã thu 5.000đ qua Timi: còn lại tối đa …". Số còn lại luôn nằm trong 0…gốc khi thêm/sửa/xoá lần thu/trả.
  - Sửa lần thu/trả (hoặc khoản vay) có tài khoản đã lưu trữ giữ nguyên tài khoản đó, không tự chuyển sang tài khoản khác.
  - Ngày cho vay không sau lần thu/trả đầu tiên.
  - Lần thu/trả mà khoản vay không còn không hiện ở Thu chi (`listedLoanPayments`).
  - Lãi "Tháng này" và lãi điền sẵn chỉ khi khoản bắt đầu trước tháng này (hoặc là khoản có sẵn) (`owesInterest`).
  - Tìm "lãi" / "lãi cho vay" ra lần thu/trả có lãi.
  - Thẻ khoản đã tất toán bỏ "Hạn …"; thanh tiến độ ở thẻ và sheet cùng một màu (`LoanCard.progressColor`).
- Rà soát trang Vay nợ lần 2 (agent, 2026-10-29), đã sửa:
  - Khoản đã có lần thu/trả: khoá công tắc "Khoản có sẵn" (người dùng chọn), như đã khoá Cho vay ↔ Đi vay; dòng phụ "Đã có lần thu nợ, không đổi được". Nhờ vậy số còn lại, ngày cho vay và các lần thu/trả luôn khớp nhau.
  - Số gốc không nhỏ hơn phần đã thu/trả (khoản có sẵn: phần qua Timi); số còn lại không âm.
  - Sửa một lần thu/trả: tiền gốc tối đa là gốc trừ các lần khác.
- Rà soát trang Vay nợ lần 3 (agent, 2026-10-29): sẵn sàng commit. Sửa thêm: khoản có sẵn chỉ được thu/trả qua Timi mở form với "Còn lại" trống (số đó do app tính, không phải người dùng gõ); "Lần này thu hết khoản vay." khi cho vay; hộp xoá khoản mới chưa có lần thu/trả chỉ nói "Số dư tài khoản sẽ được tính lại."

## Hũ: "Mua ngay" mở sheet thêm giao dịch — 2026-10-29

- Hũ đủ mục tiêu: nút "Dùng tiền" đổi thành "Mua ngay" (người dùng chọn), mở sheet thêm giao dịch thường (`AddTransactionView(buying:)`) thay cho `GoalSpendSheet` (đã bỏ; xong TODO cũ).
- Trong sheet: chỉ có chi tiêu (không có segment), tài khoản là chính hũ (dòng chỉ hiển thị, không ›), số tiền điền sẵn bằng tiền trong hũ; hạng mục, ngày, giờ, ghi chú, "Không tính vào báo cáo" như mọi giao dịch. Mua ít hơn số trong hũ: nhóm "Phần còn lại" chọn tài khoản nhận lại, chân nhóm "36.000.000đ sẽ về tài khoản này, rồi hũ được đóng." (người dùng chọn). Lưu thì ghi chi tiêu từ hũ, rút phần còn lại, đóng hũ ("Đã dùng: Đi chợ · 36tr về Ví tiền mặt").
- `FinanceStore.spend` nhận thêm ghi chú và "không tính vào báo cáo".

## Rà soát xuyên 3 trang Tài khoản · Thu chi · Vay nợ (3 agent, 2026-10-29), đã sửa:

- Vay nợ:
  - Khoản mới chỉ tính đã trả từ các lần thu/trả thật: bật "Khoản có sẵn", gõ "Còn lại", tắt lại không còn sinh một lần trả ảo.
  - Tài khoản đã lưu trữ: không đổi được tiền của khoản vay hay lần thu/trả gắn với nó; store cũng chặn (`readOnlyReason(_ loan:)`, `readOnlyReason(_ payment:)`). Bút chì vẫn mở form để đổi người, hạn trả, lãi suất; form khoá loại, số gốc, "Khoản có sẵn", tài khoản, ngày, "Còn lại" và nút xoá, ghi lý do dưới số tiền. Sheet khoản vay khoá dòng lịch sử và luôn ghi lý do ở chân nhóm.
  - "Cho vay · N người" đếm người, không đếm khoản.
  - Phần trăm đã trả không bao giờ "100%" khi còn nợ hay "0%" khi đã trả một ít (`Loan.paidText`).
  - Khoản đã tất toán xếp theo ngày tất toán (lần thu/trả cuối), ở màn riêng lẫn màn tìm.
  - Badge hạn và thứ tự theo `today` của trang, nên qua nửa đêm tự đổi.
  - VoiceOver đọc thẻ thành câu ("Minh Trần, còn 8 ngày, còn 45.000.000 đ trên 75.000.000 đ, đã trả 40%").
  - Tìm "Lan" khi đã có Lan: "Thêm người mới" mở form trống, không báo trùng ngay.
  - Khoản đã tất toán không hiện "Mỗi tháng" ở nhóm Lãi. Thanh chia hai màu không lỗi khi rất hẹp.
- Mua ngay: tiêu đề "Mua ngay", dòng "Hũ" thay "Tài khoản", chân "Vẫn trừ vào hũ." khi không tính báo cáo; sheet giữ số tiền trong hũ lúc mở nên không nháy "Hũ chỉ có 0 đ." khi đóng; lần rút phần còn lại ghi sau 1 giây nên lịch sử hũ xếp đúng.
- Tài khoản:
  - "Mục tiêu mới" phải lớn hơn số đã để dành (báo đỏ). Hạ mục tiêu xuống dưới số đã có thì hiện alert "Đã đủ mục tiêu".
  - Dòng trạng thái hũ đã đóng xuống dòng thay vì cắt. Hai nút "Rút hết" / "Mục tiêu mới" xếp dọc ở cỡ chữ rất lớn.
  - Thẻ tổng khi mọi tài khoản đều khoá: "1 tài khoản đang khoá".
  - "Lưu trữ tài khoản" khi tên trống báo lỗi thay vì lặng lẽ bỏ phần sửa.
  - VoiceOver đọc "2 hũ", "1 tài khoản" ở hai dòng lối vào.
- Thu chi:
  - Chọn tháng lùi được tới năm chỉ có khoản vay. Người chỉ có khoản vay không bị mời "Thêm giao dịch đầu tiên".
  - Dòng tiền khoản vay mở sheet khoản vay như dòng thu/trả (bỏ `LoanMoveSheet`).
  - Bộ lọc tài khoản trong màn tìm có cả hũ đã có giao dịch "Mua ngay".
- Rà soát lại (agent): sẵn sàng commit. Sửa thêm: khoản mới lưu từ bản trước với số đã trả nhưng không có lần thu/trả giữ số đó khi bật/tắt "Khoản có sẵn"; VoiceOver đọc cả dòng phụ của thẻ khoản vay (cho vay/đi vay, hạn, lãi); lần rút phần còn lại của "Mua ngay" không lùi sang ngày hôm sau.

## Rà soát lại 3 trang (3 agent, 2026-10-29), đã sửa:

- Nháy chữ đỏ khi sheet đang đóng: sheet thu/trả nợ và sheet nạp/rút hũ giữ giới hạn tính lúc mở (`openedLeft`, `savedWithout`), như "Mua ngay". Form sửa khoản vay mở bằng `sheet(item:)` nên xoá khoản vay không làm form trống khi trượt xuống.
- Tài khoản:
  - Hũ quá hạn mà chưa đủ (`SavingsGoal.isOverdue`): badge đỏ "Quá hạn · 70%" thay "45tr/tháng"; thẻ hũ ghi "Quá hạn · mục tiêu 40tr" màu đỏ; form ghi "Hạn đã qua. Chọn hạn mới…"; nạp tiền không còn chip "Mỗi tháng".
  - Tài khoản chỉ có "Điều chỉnh số dư" (sửa số dư gõ nhầm) vẫn xoá được, xoá luôn các điều chỉnh đó (người dùng chọn).
  - "Khôi phục tài khoản", "Mở lại hũ", "Đóng hũ" khi tên trống báo lỗi thay vì bỏ phần sửa.
  - Badge "Đã khoá" chỉ cộng số dư dương.
  - VoiceOver đọc thẻ hũ thành câu; cỡ chữ rất lớn: thẻ hũ rộng cả trang, dòng tiến độ xếp dọc.
- Vay nợ:
  - Khoản đã tất toán có lãi: "Ghi nhận thu/trả lãi" mở sheet "Thu lãi"/"Trả lãi" (tiền gốc khoá ở 0).
  - Nhóm "Lãi" ẩn khi đã tất toán mà chưa có lãi nào.
  - Gợi ý dưới "Còn lại" khi đã thu qua Timi: "Để trống nếu trước khi dùng Timi chưa thu đồng nào."
  - Hai ô trên thẻ tổng quan cùng đếm người ("Đang nợ · 1 người").
  - Ngày trong lịch sử thu/trả có năm khi khác năm nay. Badge trong sheet theo ngày của trang.
- Thu chi:
  - Sửa giao dịch "Mua ngay": dòng "Hũ" chỉ hiển thị, không ›.
  - VoiceOver đọc dòng hạn mức bằng số đầy đủ.
  - Tổng chi của ngày luôn màu xám, dù ngày có cả thu.
  - Sheet chuyển khoản: tài khoản nguồn đang khoá thì ghi "Phí không tính vào báo cáo vì … đang khoá."
  - Đổi tháng khi đang chọn cột biểu đồ chỉ rung một lần.
  - Bộ lọc tài khoản có "Hũ đã xoá" khi còn giao dịch của hũ đã xoá.
- Rà soát lại (agent): sẵn sàng commit. Sửa thêm: sheet sửa nạp/rút hũ giữ giới hạn trong `@State` (một `let` vẫn bị tính lại khi trang cha vẽ lại); sheet "Thu lãi" báo "Nhập tiền lãi." và tự mở bàn phím ở ô tiền lãi (`FormAmountRow(focusesOnAppear:)`), sửa một lần như vậy thì tiêu đề "Sửa lần thu lãi"; "Mở lại hũ"/"Đóng hũ" khi tên trống báo đỏ "Nhập tên."; chạm lại cột biểu đồ để bỏ chọn vẫn rung; lãi trả muộn không đẩy khoản vay lên đầu "Đã tất toán" (xếp theo lần trả gốc cuối).

## Danh bạ — 2026-10-29

- Cài đặt → Chung → "Danh bạ" (số = số người, VoiceOver đọc "2 người") đẩy sang `ContactsView` (người dùng chọn đẩy màn như Hạng mục, không chồng sheet). Một thẻ `listCard()`, xếp A→Z theo tiếng Việt: vòng chữ cái đầu (từ rà soát lần 2), tên, dòng phụ "Bạn bè · 1 khoản vay". Nút + trên thanh thêm người; chạm một người để sửa. Không có chú thích dưới thẻ (người dùng bỏ 2026-10-29). Trống: `EmptyStateCard` "Danh bạ trống".
- `ContactEditorView` (`SheetScaffold`): Tên (`FormTextRow`, tối đa 40 ký tự) và Mối quan hệ (`FormPickerRow`). Cuối form "Xoá khỏi danh bạ" (`FormDestructiveRow`). Có `onSave` để form khoản vay sau này thêm người rồi chọn luôn.
- Người dùng chọn:
  - Mối quan hệ là danh sách cố định: Gia đình, Bạn bè, Đồng nghiệp, Người quen, Khác (`ContactRelationship`, mỗi loại một icon Hugeicons).
  - Khoản vay nối với người bằng id (`Loan.contactID`, database V3). Đổi tên người thì tên trên khoản vay đổi theo.
  - Người còn khoản vay (kể cả đã tất toán) không xoá được: hộp thoại chỉ giải thích và có nút "OK".
- Tên không trùng (không phân biệt hoa thường, có phân biệt dấu, gộp khoảng trắng thừa), báo đỏ "Danh bạ đã có “Minh Trần”.", nút ✓ tắt.
- Chưa nối form khoản vay: `LoanEditorView` vẫn gõ tên. Khi lưu, store tìm người trùng tên, không có thì tạo người mới loại "Khác" (`FinanceStore.link`), nên khoản vay nào cũng có người. Sửa tên trên khoản vay thành tên khác thì khoản đó chuyển sang người khác (người cũ vẫn còn trong danh bạ).
- Mở từ trang Vay nợ sau này: `ContactsSheet` (cùng màn, trong `NavigationStack` riêng, có ✕).
- Database V3: bảng `ContactRecord`, cột `LoanRecord.contactID`; chuyển V2 → V3 tự động (lightweight), lần mở app đầu sau đó mỗi tên trong khoản vay cũ thành một người "Khác". Dữ liệu mẫu có 3 người (Minh Trần, Hùng Lê, Mẹ). "Đặt lại dữ liệu mẫu" xoá cả danh bạ.
- Góp ý lần 1 (2026-10-29):
  - Chưa nhập tên mà bấm ✓: báo đỏ "Nhập tên." và tô đỏ chữ "Tên" (như form tài khoản). Nút ✓ luôn bật, chỉ báo lỗi khi bấm.
  - **Loại mối quan hệ tự thêm** (người dùng chọn: có icon riêng, thêm/sửa/xoá được): sheet chọn mối quan hệ (`RelationshipPickerSheet`) có thêm dòng "Thêm loại mới" (dấu +, màu đen) ở cuối; loại tự thêm nằm trước "Khác", có bút chì bên phải để sửa. Form `RelationshipEditorView`: Tên loại (tối đa 20 ký tự, không trùng loại nào kể cả loại có sẵn, báo "Nhập tên." khi trống) và Biểu tượng (`IconQuickPicker`, gợi ý icon người, nhà, công việc…). "Xoá loại": ai thuộc loại đó chuyển về "Khác". Thêm xong loại mới thì loại đó được chọn luôn và sheet chọn đóng lại.
  - Database V4: bảng `RelationshipRecord` (V3 chưa phát hành nhưng máy thử đã ở V3 nên thêm V4 thay vì sửa V3).
- Rà soát Danh bạ lần 1 (2026-10-29), đã sửa:
  - Bỏ chú thích dưới danh sách (người dùng chọn).
  - Người do app tự tạo từ tên gõ ở khoản vay (`Contact.isAutoCreated`, database V5) tự xoá khi không còn khoản vay nào: sửa tên trên khoản vay ("Minh Tran" thành "Minh Trần") hay xoá khoản vay gõ nhầm không còn để lại người thừa. Người bạn thêm hoặc đã lưu lại trong Danh bạ thì giữ nguyên.
  - Sheet chọn mối quan hệ cao theo nội dung nhưng cuộn được khi nhiều loại (trước bị cắt mất các dòng cuối và "Thêm loại mới").
  - Tên người tự tạo cắt còn 40 ký tự, như giới hạn ở Danh bạ.
  - Thêm người, thêm loại: ô Tên tự focus khi sheet trượt xong (`FormTextRow(focusesOnAppear:)`, như iOS Danh bạ).
  - Để sau: tìm kiếm trong Danh bạ (làm khi nối Danh bạ vào form khoản vay).
- Rà soát Danh bạ lần 2 (2026-10-29), đã sửa:
  - Xếp tên theo tiếng Việt dù iPhone để tiếng Anh ("Dũng" trước "Đức", "Anh" trước "Ăn"): so sánh với `Locale.vietnam` thay vì ngôn ngữ của máy.
  - Mỗi dòng Danh bạ hiện vòng chữ cái đầu như thẻ khoản vay ở Vay nợ (người dùng chọn, thay cho icon mối quan hệ); mối quan hệ vẫn ở dòng phụ. Đường kẻ bắt đầu sau vòng tròn.
  - Để sau: thẻ "Cần chú ý" mẫu lưu tên dạng chữ nên không đổi khi đổi tên người (làm lời nhắc thật thì lưu id khoản vay); gợi ý "Có phải Minh Trần?" khi gõ tên gần giống người đã có (khi nối form khoản vay với Danh bạ).

## Chế độ tối — 2026-10-29

- Theo máy, hoặc chọn trong Cài đặt → Giao diện: Theo hệ thống / Sáng / Tối (`AppAppearance`, lưu `settings.appearance`). Áp lên cửa sổ (`overrideUserInterfaceStyle`), không dùng `preferredColorScheme`: sheet đang mở như Cài đặt cũng đổi màu ngay, và "Theo hệ thống" trả về đúng màu máy.
- Mỗi token trong `Palette` có hai màu (`Color(light:dark:)`). Tối: nền đen, card 28,28,30, chữ gần trắng, xám theo iOS; đỏ/xanh/cam lấy bản sáng hơn của iOS.
- Nút và chip chính: đen chữ trắng ở chế độ sáng, **trắng chữ đen** ở chế độ tối (người dùng chọn). Chữ/icon trên nền này dùng `Palette.onPrimary`, không viết cứng `.white`.
- Lime giữ nguyên; chữ trên lime luôn tối (`Palette.onLime`).
- Switch bật và ngày chọn trong lịch: đen ở chế độ sáng, xanh iOS ở chế độ tối (`Palette.controlTint`) — trắng làm mất núm switch.
- Thẻ Pro: nền xám nổi (`Palette.proCard`) ở chế độ tối.

## Lịch thu chi ở Tổng quan — 2026-10-29

- Nút tháng dùng lại `MonthMenu` của trang Giao dịch: kính trơn "Tháng 10 ⌄", mở sheet "Chọn tháng" (không chọn được tháng chưa tới). Bỏ menu cũ (Tháng trước / Tháng sau / menu năm) và icon lịch.
- Số tiền trong ô ngày cùng một cỡ 10pt (trước 13pt tự co theo chỗ nên "-85k" to, "-430k" nhỏ). Chỉ co thêm khi số rất dài.
- Ngày chưa tới mờ 40% và không bấm được.
- Màu ô ngày (người dùng chọn, thay 3 mức xám): thu nhiều hơn chi → xanh nhạt, chi nhiều hơn → đỏ nhạt; chênh từ 1tr và từ 3tr thì đậm hơn (8% / 15% / 24%). Không có gì: nền `fill1`. Hôm nay vẫn lime.

## Tổng quan: nền xanh, Timi Pro, Làm quen — 2026-10-29

- **Nền đầu trang:** ~~lớp lime~~ — đã bỏ theo người dùng (2026-10-29). Trước đây: lớp lime (`Palette.heroGlow`, 28% sáng / 13% tối) sau status bar và lời chào, nhạt dần xuống nội dung. Cuộn theo trang (người dùng chọn); phần trên đầu che lúc kéo xuống quá.
- **Timi Pro** (người dùng chọn): card tối, một quầng lime nhạt trên phải (bỏ quầng dưới trái và tick lime theo người dùng: "hơi nhiều xanh"; badge PRO nền trắng mờ, vương miện lime), viền lime chạy chậm quanh card (6 giây một vòng, đứng yên khi bật Giảm chuyển động). Badge "PRO" lime, tiêu đề "Timi Pro", một dòng mô tả, 3 quyền lợi tick trắng mờ, nút lime "Nâng cấp ngay" cỡ thường, chữ `captionStrong` (bản to bị chê quá lớn). Vẫn mở thông báo "Sắp ra mắt".
- **Làm quen với Timi:** mỗi việc chưa xong là một dòng bấm được, có chevron: Thêm ví → form thêm tài khoản, Ghi thu chi → sheet thêm giao dịch, Ghi cho vay → form khoản vay, Hỏi AI → tab Trợ lý AI. "Hỏi AI" được tick thật khi gửi câu hỏi đầu tiên (`onboarding.askedAI`). Việc đã xong: tick đen, chữ gạch ngang. Xong cả 4 thì thẻ ẩn đi. "+5 lượt AI" vẫn chỉ là chữ, chưa cộng lượt thật.

## Cài đặt mới và lượt AI — 2026-10-29

- **Lượt AI** (`AIQuota`, người dùng chọn): gói Miễn phí 20 lượt/tháng, ngày 1 đầy lại; Pro 300 (chưa bán). Mỗi việc "Làm quen với Timi" xong được +5 lượt thưởng một lần, giữ tới khi dùng. Mỗi câu hỏi gửi Trợ lý AI (kể cả bấm gợi ý) trừ lượt tháng trước, rồi lượt thưởng. Hết lượt: ô nhập thay bằng thẻ "Đã dùng hết lượt AI · Lượt mới vào 1/11", không gửi được. Lưu trong UserDefaults.
- **Cài đặt** từ trên xuống:
  - Thẻ hồ sơ: avatar lime, tên, "Dữ liệu mẫu · lưu trên máy", badge "Miễn phí".
  - Thẻ "Lượt AI tháng này": số lượt còn lại (to), thanh lượt miễn phí còn lại (cam khi còn ≤3), "Đã dùng x/20 lượt miễn phí", "+n lượt thưởng" (xanh), "Làm mới 1/11".
  - Thẻ mời "Nâng cấp Timi Pro": tối + lime như card ở Tổng quan, bấm mở ghi chú "Sắp ra mắt".
  - **Giao diện** chọn ngay tại chỗ: 3 ô màn hình nhỏ (Theo máy nửa sáng nửa tối, Sáng, Tối) + vòng tick, như iOS Màn hình & Độ sáng. Bỏ dòng mở list.
  - Rồi Chung, Thông báo, Hỗ trợ, Nhà phát triển như cũ.

## Tổng quan "Mực đêm" — 2026-10-31

- Người dùng muốn "phong cách mới, màu mới thật là peak". Đưa 3 hướng mockup: A Mực đêm (thẻ than gần đen + lime điện trên nền kem), B Hoàng hôn (thẻ gradient cam → hồng → tím, nền trắng), C Tối giản (không thẻ, số rất to, một màu cam cháy). Chọn **A**.
- Token mới trong `Palette`: `night` #14201A, `onNight`, `onNightMuted` (trắng 64%), `redOnNight` (= `chartCoral`), `nightTile` (trắng 10%). `lime` đổi từ vàng #E0A840 sang xanh chanh điện #C9F26B; `onLime` vẫn mực, `limeTile` theo. Mọi chỗ dùng `lime` (badge PRO, "+5 AI", nút `.accent`, vương miện ở Cài đặt, cột 3 trong biểu đồ Báo cáo) đổi theo.
- Trang: bỏ dải rêu và `ClearBarOverBand` / `TopEdgeEffectOnlyPastBand` (thanh trạng thái không còn đổi theo cuộn, iOS 17 không còn thanh rêu đặc). Lời chào thành chữ mực trên nền kem. `HeroCard` nền đêm, không bóng, số trắng, tăng trưởng và đường biểu đồ lime (`MoneyText.Tone.onNight`, `NetWorthGrowth(onNight:)`, `NetWorthChart(tint:)`). `QuickActions` từ kính sang vòng đêm phẳng với icon lime (ngoại lệ kính duy nhất trong nội dung không còn). Thêm `MonthSummaryTiles` (hai ô trắng Chi/Thu tháng này, bấm mở Báo cáo qua `ReportRoute`). `OnboardingCard` vòng đêm (`ProgressRing` thêm `track:`). Lịch: hôm nay ô đêm số lime khi chưa chi, viền đêm khi đã chi. `ProUpgradeCard` từ banner vàng nhạt sang đêm + lime.
- Để sau nếu người dùng muốn: chữ "Tháng 10 ⌄" trên tiêu đề Lịch vẫn rêu (quy tắc chung của nút trên hàng tiêu đề); nếu thấy lệch tông thì đổi sang mực riêng cho Tổng quan.

## Tổng quan "soft UI" theo mẫu Iconly — 2026-10-31

- Ngay sau bản "Mực đêm", người dùng gửi 3 ảnh chụp Instagram của iconlypro (màn Profile có huy hiệu lục giác, màn Dropbox có thanh Storage nhiều màu và dock, màn task có tag "High" và nút + đỏ) và yêu cầu làm lại theo phong cách đó.
- Đặc điểm rút ra: nền xám lạnh nhạt; thẻ trắng bo rất tròn với bóng rộng mềm; ô trắng lồng trong thẻ có viền mảnh; nút tròn trắng; một nút tròn đen/màu nổi; icon nét; màu tươi chỉ ở điểm nhỏ; chữ đậm đen, phụ xám.
- Đã làm: token `softPage/softBorder/softSecondary/softTrack/softBlack` và bộ `vividSeries` trong `Palette`; `CardCorners.soft` 36; file `SoftSurface.swift` (`softCard`, `softTile`, `SoftCircleButtonStyle`, `SoftCapsuleButtonStyle`, `SoftTag`, `RoundedHexagon`, `HexagonBadge`). `OverviewView` ẩn thanh điều hướng, header `OverviewHeader` trong nội dung. `HeroCard` thành thẻ tổng hợp (tài sản ròng + `SpendingBarTile` + `MonthSummaryTiles` + `ActionDock`). Thêm `TopCategoriesCard`. `OnboardingCard` và `MoneyCalendarCard` đổi sang bề mặt mềm; `MonthMenu`/`HeaderCapsuleLabel` thêm `tint`/`color`. Xoá `QuickActions`, `ProUpgradeCard`.
- Sửa sau khi xem: emoji 👋 hiện ô vuông (Manrope không có emoji) → bỏ; nút Pro bị ép mất chữ → `fixedSize()`; avatar dùng `InitialsAvatar` nền kem lệch tông → chữ Q thẳng trên vòng trắng; nút ✦ dùng `ink` xanh xám → `softBlack`.
- Để sau: số tiền ra trong ô "Đã chi" vẫn đỏ gạch `red` theo quy tắc toàn app, icon cạnh đó san hô tươi; nếu muốn đồng bộ thì cho `MoneyText` một tone san hô riêng cho Tổng quan. Các tab khác vẫn nền kem; nếu chốt soft UI cho cả app thì đổi `background` trong `AccentTrial` sang `softPage`.

## Tổng quan: thẻ kính + bố cục HIG — 2026-10-31

- Người dùng xem bản soft UI: "nhìn cũng tạm", chê card bọc trong card, muốn card Liquid Glass và bố cục chuẩn Apple HIG.
- Lưu ý đã nêu: HIG khuyên glass cho lớp điều hướng, không làm nền nội dung; làm theo ý người dùng nhưng thêm `GlassBackdrop` (3 vòng màu blur cố định) để kính có gì để khúc xạ, và kiểm tra trôi khi cuộn trên Simulator.
- Bỏ: header tự vẽ (`OverviewHeader`), dock + nút đen (`ActionDock`), ô lồng (`SpendingBarTile`, `MonthSummaryTiles`), lục giác, `SoftSurface` và token `soft*`/`vivid*`; cả token `night*` của bản "Mực đêm". Thêm `glassCard()` + `GlassBackdrop` trong `CardSurface.swift`.
- Quay về tiêu đề native `TabHeading` + Q/chuông trên thanh; `QuickActions` kính như bản 2026-10-30; `HeroCard` như bản trắng nhưng kính; gộp thanh chi tiêu + hai tổng vào `MonthCard` một thẻ dưới section "Tháng này" (nút "Báo cáo ›"); `TopCategoriesCard` thành icon tròn tô nhạt theo `ChartShades`; Làm quen và Lịch lên kính; màu thanh/huy hiệu dùng `ChartShades` để khớp Báo cáo thay bộ màu tươi riêng.

## Tổng quan chuẩn HIG + bảng Đơn sắc — 2026-10-31

- Người dùng hỏi có nên dùng card Liquid Glass theo HIG không; trả lời: không, kính là của lớp điều khiển (thanh, tab bar, nút nổi), nội dung đặt trên bề mặt đặc; Wallet/Health/Fitness iOS 26 cũng vậy. Người dùng chốt: làm đúng HIG, và thử phối màu đơn sắc không rêu.
- Bỏ `glassCard` và `GlassBackdrop`; thẻ Tổng quan về `sleekCard()`; nút nhanh từ kính sang vòng phẳng `primaryTint` (nút trong nội dung cuộn không phải kính). Kính còn ở thanh trên, tab bar, nút +.
- Bảng "Đơn sắc" thêm vào `AccentTrial` làm mặc định: `Choice` có thêm `neutrals` và `hues`; `Palette` chuyển các token chữ/màu phụ sang computed đọc từ combo; `ChartShades.steps/rest` thành computed. Lần đầu xem thanh "Chi theo nhóm" xám không giảm dần (sky xám vừa, lime xám đậm) → đổi sky đậm, lime vừa với chữ mực.
- Để sau: nếu chốt đơn sắc, đổi `AccentColor` Assets và cân nhắc đỏ tiền ra có cần lạnh hơn (#B5543F hiện hơi ấm trên nền xám).

## Đơn sắc không xám — 2026-10-31

- Người dùng xem bản đơn sắc xám: "không thích màu xám", muốn mono như 3 ảnh Iconly nhưng không xám. Đề xuất 3 mix khác (Mực & Kem, Navy đơn tông, Espresso) bị gạt: ý là giữ đen trắng.
- Sửa combo "Đơn sắc": nền sáng hơn (#F5F5F7), lime = đen chữ trắng (badge đen như nút FAB của mẫu), green = mực, sky = xanh dương, đồ thị 4 màu tươi (`Hues.chartSteps`, `ChartShades.steps` đọc từ đó), nút nhanh vòng trắng viền mảnh thay tô xám.

## Dọn theme cũ, design system theo HIG — 2026-10-31

- Người dùng duyệt 6 đề xuất của `docs/design-system-plan.md`: Đơn sắc là theme duy nhất; thẻ viền mảnh không bóng; `positive` xanh lá nhỏ #1E9E5A chỉ cho chấm/mũi tên/chữ 13; iOS 26 tối thiểu; dark mode để sau; xoá `examples/`, commit `docs/design-trials/`.
- Bước 1: `Palette` thành hằng số của bộ Đơn sắc; xoá `AccentTrial` (6 combo: Đơn sắc, Rêu & Kem, Xanh biển & Ngà lạnh, Lục bảo & Bạc hà, Chàm & Oải hương, Hổ phách & Giấy), row "Màu (thử)" và "Kiểu trang Tài khoản (thử)", `AccountsLayout` (cố định thẻ tổng + hũ cuộn ngang). `AccentColor` #111111. Deployment target 26.0, xoá 19 nhánh `#available`, `HiddenToolbarTitle` và tiêu đề vẽ tay ở 4 trang. Bỏ `income`, `incomeTile`, `limeTile`, `controlTint`, `flatSection`, `TextRole.hero/input`, `ControlHeight.row/floating`, `CardCorners.sheet`, `nativeGlassButton`.
- Bảng rêu cũ để tra: primary #3E5B3F, green #1E5A48, sky #5FB89A, lime #C9F26B (trước đó vàng #E0A840), chartCoral #E8917A, chartRest #A9B9A0, nền #FAF7F2, ink #1F2A22, chữ phụ #6F675B, chevron #968E82, muted #F1EEE6, border #ECE7DC.
- Bước 2: token đặt theo vai trò (`label`, `surface`, `separator`, `negative`, `positive`, `info`, `accent`, `chart`…) thay tên theo màu (`ink`, `card`, `border`, `red`, `green`, `sky`, `lime`); `sleekCard` → `card`, `HeaderCapsuleLabel` → `HeaderLink`, `headerCapsuleGlass` → `headerLinkButton`, `AccountRowDivider` → `RowDivider(column: .logo)`. Thư viện UI liệt kê token theo nhóm vai trò.
- Bước 3: `SplitTotals` thay 4 bản hai cột tự dựng; `SegmentedBar` + `LegendRow` thay 3 thanh chia phần (thanh Tổng quan từ 12 về 8); `cardSurface(outlined:)` viền mảnh thay `softCardShadow`; `CardButtonStyle` bỏ scale; nhãn dưới nút nhanh và lưới hạng mục vào trong `Button`; badge "Đã thu" trắng viền chấm xanh; `TextRole.amountEntry` 52/38/28, `display`/`amountLarge` có line box 42/32; Reduce Motion ở ô tiền, dòng giá trị, dòng hạn mức, danh sách Thu chi, kiểu nhấn; `ProgressRing`, `FlowLayout`, `SplitLine`, `ChartShades` về DesignSystem.
- Bước 4: xem Tổng quan, Tài khoản, Thu chi, Vay nợ, Báo cáo, sheet Thêm giao dịch trên Simulator ở cỡ mặc định và AX-large (hai cột xếp dọc đúng).

## Duyệt khó tính Thư viện UI — 2026-10-31

- Người dùng xem Thư viện UI: quá nhiều màu, nút Chính và Nổi bật giống nhau, badge Pro chấm đen trên nền đen, cuộn trang bị giật về, số tiền trong danh sách không cần đậm hơn tên.
- Màu: xoá `fill1`, `fill3`, `info`, `accent`, `onAccent`, `inputBackground`, `primaryTrack` (không ai gọi hoặc trùng giá trị); `fill2` → `fill`. Còn 23 token, mỗi token có nơi gọi. Đo tương phản: `positive` #1E9E5A chỉ 3,45:1 → #15803D (5,0:1); cam đồ thị #F5A623 2,0:1 → #D97706 (3,2:1); "Khác" #D1D1D6 1,5:1 → #8E8E93 (3,3:1). Đỏ #B5543F 4,9:1, chữ phụ 4,9:1 đạt.
- Nút: bỏ vai trò "Nổi bật". Badge Pro: tone `.pro`, nền `primary`, chấm trắng.
- Chữ: `amount` 16 SemiBold như `body` (trước Bold).
- Chip: nút 44 để chạm, viên 36 vẽ lùi 4 trên dưới.
- Thư viện UI: bỏ `scrollPosition(id:)` (gắn vị trí cuộn vào `LazyVStack` làm trang giật về khi phần mới được dựng), chỉ theo dõi bằng `onScrollTargetVisibilityChange`.
- Đối chiếu HIG còn lại ghi ở cuối `docs/design-system-plan.md`.

## Sheet ngắn dùng thanh thật — 2026-10-31

- Người dùng chọn chuyển 8 sheet ngắn (Thêm mới `OptionSheet`, `ChoiceSheet`, `NoteSheet`, lịch ngày/giờ, Mối quan hệ, Nợ, giao dịch trong ngày, mẫu Thư viện UI) từ thanh tự vẽ `SheetHeader` sang `NavigationStack` + toolbar của iOS qua `SheetScaffold`.
- `SheetScaffold` thêm `fitsContent`: đo chiều cao nội dung (`onGeometryChange`) cộng thanh (safe area trên của scroll view) thành một detent `.height`; cuộn chỉ khi vượt màn (`scrollBounceBehavior(.basedOnSize)`). Xoá `SheetHeader.swift` và `timiFittedSheet()`.
- Nợ: tổng đỏ nằm đầu nội dung thay vì dưới tiêu đề tự vẽ. Ghi chú: chữ lùi 16 như dòng.

## Đợt 1 sau rà soát: trợ năng và tương phản — 2026-10-31

- `RowIcon`, `InitialsAvatar`, `FormRowIcon` tự co theo Dynamic Type; bỏ 9 `@ScaledMetric` lẻ ở caller; `FormDivider` = `RowDivider` (lùi theo icon đã co); xoá `RowMetrics.dividerInset`, `AccountRow.dividerInset`.
- `AdaptiveStack` mới: `FormTextRow`, `FormAmountRow`, `FormValueLabel` xếp dọc ở cỡ trợ năng; ô nhập mang `accessibilityLabel(title)`.
- `Palette.warning` #E8890C → #D97706 (3,2:1). Badge "Quá hạn" trắng viền mảnh chữ đỏ (4,9:1) thay chữ đỏ trên đỏ 10% (4,3:1); badge bỏ `fixedSize`, 2 dòng ở AX.
- `TimiButton` một cỡ 44, chữ `textRole(.body)`; xoá `TimiButtonSize`. `SearchField` nút xoá rộng 44, `secondaryLabel`, icon `iconGlyph`.
- `MoneyText` có nhãn VoiceOver "trừ 10.300.000 đồng". Reduce Motion ở `FlatButtonStyle`, `FormGroup`, `FormErrorText`, `IconQuickPicker`. Bỏ `GlassEffectContainer` quanh chip ô tiền. `IconQuickPicker` rung bằng `sensoryFeedback`.
- Còn lại của mục 1 (12, 14, 15, 16) cần thử VoiceOver trên máy, để đợt sau.

## Đợt 2 sau rà soát: một dòng danh sách — 2026-10-31

- `ListRow` thành generic với slot `leading` / `trailing`, xếp dọc ở cỡ trợ năng bằng `AdaptiveStack`; `ListRowTrailing` / `ListRowAmount` cho phần phải (số + dòng nhỏ có màu). Bản ngắn `ListRow(icon:…amount:)` giữ nguyên chữ ký cho 10 nơi gọi; bỏ `isLocked`.
- `AccountRow`, `LoanRow`, `GoalRow`, `CompletedGoalRow` dựng trên `ListRow`: mất ~120 dòng bố cục tự viết; `GoalRing` tự co như `RowIcon`.
- 7 bản `AnyLayout(VStackLayout…)` thay bằng `AdaptiveStack` (`SectionHeader`, `LoanDetailSheet`, `GoalDetailView` ×2, ba dòng trên).
- `fixedSize()` trên số tiền trong dòng → `layoutPriority(1)`, để `MoneyText` còn co được khi số rất dài.
