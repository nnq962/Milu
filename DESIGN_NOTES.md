# Ghi chú thiết kế Timi — quy tắc đang áp dụng

> Bản rút gọn, chỉ giữ quyết định mới nhất. Nhật ký đầy đủ theo ngày (lý do, các bản thử, số đo): [`docs/design-history.md`](docs/design-history.md). Quyết định mới: sửa thẳng mục tương ứng ở đây, rồi ghi một mục có ngày vào cuối file lưu trữ.

App iPhone SwiftUI, tiếng Việt, tiền VND. 4 tab: Tổng quan, Tài khoản, Giao dịch (Thu chi · Vay nợ), Trợ lý AI; Cài đặt mở từ avatar. Dữ liệu lưu trên máy (SwiftData), có dữ liệu mẫu. Mẫu nguồn: HTML Sleek trong `examples/`, design system của bản web (`finance-tracker-v2/docs/design`).

## Nguyên tắc chung

- **Native iOS trước:** `NavigationStack` + toolbar, `TabView`, `.sheet`, `Toggle`, alert, Swift Charts, `.searchable` của hệ thống. Chỉ đổi màu, font, cỡ, hình khi cần; không tự dựng lại thứ Apple đã có.
- **Thanh trên:** để iOS tự lo nền mờ / scroll-edge. Không tự làm header mờ bằng `Material`, blur, gradient, mask hay opacity theo offset. Tiêu đề màn và nút nằm trong `ToolbarItem`; nút tròn 44pt dùng glass riêng thì ẩn shared background của item trên iOS 26.
- **Liquid Glass chỉ trên button** (2026-10-27). Card và ô dữ liệu nền đặc, không kính. Card trắng không viền, bóng ngắn sát mép dưới; ô nhỏ trong card không bóng.
- **Button giữ hiệu ứng của Apple:** không tự thêm scale/animation/shadow mô phỏng nhấn. iOS 26 dùng `glass` / `glassProminent`; `bordered*` chỉ để tương thích iOS cũ.
- **Không tự thêm CTA** hay đổi vị trí nút ngoài thiết kế.
- **Icon:** Hugeicons bản miễn phí, Stroke Rounded (MIT; người dùng chọn 2026-10-28, thay Solar). Asset `hugeicons-<mã>`, vẽ template qua `TimiIcon`; kho chung `IconCatalog` (311 icon, 15 nhóm). Thêm icon: bỏ SVG vào Assets + một dòng trong `IconCatalog`.
- **Icon không nền (không tile)** ở mọi dòng form, list, sheet, thẻ hũ, trạng thái trống. Trong một nhóm: hoặc mọi dòng có icon, hoặc không dòng nào. Ô nhập không kèm icon. `.formIconStyle(.tile)` chỉ dùng ở chỗ riêng.
- **Dòng hành động màu mực (`ink`):** việc hoàn tác được ("Lưu trữ tài khoản", "Khôi phục", "Mở lại hũ", "Thêm hạng mục", "Thêm loại mới") dùng `FormActionRow`, chữ và dấu + màu mực, không ›. Xám đọc như nút tắt nên không dùng. Xoá dùng `FormDestructiveRow` đỏ, có icon thùng rác.
- **Xoá luôn hỏi lại** bằng alert giữa màn hình (Huỷ + nút đỏ lặp tên hành động), rung cảnh báo.
- **Xem trước, sửa sau:** chạm một mục mở màn/sheet xem; bút chì (`EditToolbarButton`) trên thanh mở form sửa; xoá nằm cuối form sửa. Không dùng menu nhấn giữ (đã bỏ 2026-10-28/29).
- **Lưu trữ thay vì xoá** khi đã có lịch sử (tài khoản); hũ đóng thay vì mất. Mục chỉ xem thì mở sheet xem, ghi lý do.
- **Ít chữ:** placeholder 1–3 từ ("Tìm ngân hàng", "Thêm ghi chú"); nhãn dòng tự nói nghĩa; chú thích dưới nhóm chỉ khi có thông tin tính sẵn hoặc lỗi; không footer giải thích dưới nút hành động.
- **Bàn phím:** không có thanh "Xong", không nút xoá nhanh trong ô; chạm ra ngoài hoặc kéo nội dung để đóng (`keyboardDismissArea()`). Đẩy nội dung khi bàn phím hiện để iOS tự lo.
- **Rung:** `.sensoryFeedback(.selection)` khi đổi chip/lựa chọn/cột biểu đồ; `Haptics.success` khi ✓ lưu; `Haptics.warning` khi xoá; `Haptics.error` khi lưu thiếu thông tin.
- **Ngày ghi tiền** không sau hôm nay (giao dịch, chuyển khoản, nạp/rút, thu/trả nợ) — người dùng chọn.
- Chuyển tab tức thì, không cross-fade (`InstantTabSwitch`). Ẩn chỉ báo cuộn dọc toàn app.

## Giao diện: một theme sáng (2026-10-30)

- **Chỉ một giao diện sáng**: bỏ chế độ tối và mục "Giao diện" trong Cài đặt; app khoá sáng bằng `UIUserInterfaceStyle = Light`. Token trong `Palette` là màu thường, không còn cặp sáng/tối.
- **Bảng màu "TổngQuan"** (người dùng gửi và chốt 2026-10-30; thay bảng Sleek xanh ngọc): xanh rêu #3E5B3F (`primary`: nút chính, tab, chip chọn, switch, tiến độ, thẻ chính Tổng quan), xanh đậm #1E5A48 (`green`: tiền vào), đỏ san hô #B5543F (`red`: tiền ra; bản mẫu #D9725B chỉ 3.2:1 nên làm đậm cho đạt 4.5:1), vàng #E0A840 (`lime` — giữ tên token), xanh lá nhạt #5FB89A (`sky`), cam `warning` cho hạn mức sắp hết, nền ấm #FAF7F2, chữ #1F2A22, chữ phụ #6F675B (mẫu #7A7266, đậm hơn một bậc), viền #ECE7DC.
- **Đổi màu**: chỉ sửa nhóm "Base colours" đầu `Palette.swift`; `heroCard`, `incomeTile` (= `green` 12%), `controlTint`, `onLime`, `rowPressed`, `fill1/2/3` tự theo. Riêng `AccentColor` trong Assets (nút hộp thoại hệ thống) phải sửa tay cho bằng `primary`. Màu đồ thị (`ChartShades`) lấy từ `Palette` nên cũng đổi theo.
- **Vàng rất ít**: chỉ badge PRO, vương miện, "+5" ở bước Làm quen chưa làm, viền chạy thẻ Pro.
- **Tiền vào luôn `green`, tiền ra luôn `red`** ở mọi nơi (dòng giao dịch, tổng, Báo cáo, lịch, Trợ lý AI, ô nhập tiền, Cho vay ở Vay nợ).
- **Biểu tượng không có nền** ở mọi nơi (kể cả avatar Trợ lý AI: glyph xanh trơn); chỉ tô màu nét. Biểu tượng trên header (avatar, chuông, tìm, +, ‹ ›) màu chính.
- **Chữ**: tiêu đề, số tiền, chữ hoa nhỏ = Manrope ExtraBold (`.heavy`); chữ khác = Manrope Bold (`.semibold`) theo mẫu trong `examples/` (Regular trông mờ).
- **Bo góc**: mọi thẻ 28 (`CardCorners.large`), nhóm form và thẻ trong Cài đặt 24 (`inset`), ô trong thẻ 20 (`flow`). Đệm thẻ 20 (`Spacing.card`), thẻ đầu trang 24. Khoảng cách giữa các khối 28 (`Spacing.section`). Vùng chạm ≥ 44.
- **Bóng**: thẻ trắng không viền, bóng ngắn sát mép dưới (đen 6% r1,5 y1 + đen 5% r6 y3, theo ảnh mẫu người dùng) qua `cardSurface(elevated:)`, `sleekCard()`; thẻ màu (`HeroBackground`) = bóng đen 10%, r12, y8.
- **Chỉ thẻ chính Tổng quan nền xanh đặc**; thẻ đầu các tab khác giữ nền trắng (thử nền đậm cho mọi tab: người dùng thấy lố).
- **Đồ thị** (`ChartShades`, theo mẫu "TổngQuan"): 4 nhóm lớn nhất rêu `primary` / bạc hà `sky` / vàng `lime` / san hô `chartCoral`, "Khác" xanh xám `chartRest`; biểu đồ chi theo ngày: hôm nay và cột chọn màu chính.
- Bấm dòng: `.row` (màu chính 10%); bấm thẻ: `.card`.

## Màu

- Mọi màu lấy từ `Palette`; không viết cứng `.white` / `.black` (trừ chữ trắng trên thẻ xanh).
- `onPrimary` trắng; `controlTint` = `heroCard` = `primary`; `onLime` = `ink`; `incomeTile` = `green` 12%; `fill1/2/3` = mực 4/6/10%.
- `ProgressBar` mặc định màu `primary`. Thanh hạn mức (`budgetColor`): xanh < 80%, cam từ 80%, đỏ khi chạm/vượt 100%.

## Chữ & tiền tệ

- **Font Manrope** toàn app (cả tab bar, segmented, tiêu đề thanh). Manrope vẽ mảnh nên mọi độ đậm hiển thị nặng hơn một bậc như web (`Typography.instance(for:)`); code vẫn ghi độ đậm theo ý nghĩa.
- **Thang `TextRole`** (chốt 2026-10-28, nội dung 16), co giãn theo Dynamic Type; không đặt cỡ tay trong `Features/`:
  - hero 40 (số đang nhập) · display 34 (số dẫn đầu) · amountLarge 24 · pageTitle 24 · heading 20
  - title 17 SemiBold (tiêu đề phần trên màn chính, thẻ, sheet, hộp thoại)
  - body / amount / label 16 (tên dòng, giá trị, chữ gõ, số tiền cuối dòng)
  - caption / captionStrong 13 (phụ đề, chú thích, lỗi, chip, badge) · overline 12 in hoa (tiêu đề nhóm) · footnote 11
- Nút: 16 ở cỡ 44/56, 14 ở cỡ 36. Ô số tiền lớn co 40 → 30 → 22 khi số dài.
- **Tiền:** đầy đủ `10.000.000đ`, rút gọn `10,3tr` (`25k`, `2,5tr`, `1,2tỷ`). Đơn vị liền số, cùng font/cỡ/weight/baseline; dấu chấm phân nhóm, dấu phẩy thập phân; không dùng `₫`. Formatter chung `vnd` / `vndCompact`; số tiền vẽ bằng `MoneyText` (dấu, màu theo nghĩa).
- Ngày: "Hôm nay, 28/10", "Thứ Hai, 12/5"; năm khác thì ghi năm ("Thứ Ba, 27/10/2025").
- Chính tả theo kiểu dấu "Xoá / Khoá / Hoá đơn / Sức khoẻ".

## Bo góc & khoảng cách

- `RoundedRectangle(..., style: .continuous)`; không path squircle tự vẽ, không capsule cho card. Sheet hệ thống giữ bo góc của Apple.
- `CardCorners` (2026-10-30): `large` 28 (mọi thẻ, danh sách, thẻ hũ) · `inset` 24 (nhóm form, thẻ Cài đặt) · `flow` 20 (ô nhỏ trong thẻ) · `field` 12 · `icon` 10 · `calendarDay` 8.
- `Spacing` bội 4: lề màn 20; giữa các phần 28; đệm thẻ 20; tiêu đề → thẻ `headerGap` 8; nội dung sheet form cách nhau 24.
- `RowMetrics`: lề 16; icon 20 trong cột 24; icon → chữ 14; vạch kẻ lùi 54; hàng một dòng đúng 52 (vừa switch native), có phụ đề ~62. `featureIcon` 44 (logo/icon đứng riêng), `iconChoice` 52, `toolbarGlyph` 22 / `toolbarGlyphFrame` 28.
- `ControlHeight`: nút 36 / 44 / 56. `ProgressBar` một cỡ 8pt.

## Thành phần

- **Nút (`TimiButton`):** Chính (màu chính) / Phụ / Nổi bật (vàng, chỉ cho Pro) / Xoá / Xoá vĩnh viễn; cỡ 36/44/56; Liquid Glass native. Nút tắt: viên xám `fill2`, chữ xám nhạt. Nút tròn trên thanh 44pt (`nativeCircleButton`).
- **Nút thêm giao dịch:** nút + tròn tách riêng cạnh tab bar (`Tab(role: .search)`, iOS 26), có ở mọi tab, mở sheet chứ không đổi tab (người dùng chọn kiểu B). iOS 17 là tab thứ 5 "Thêm".
- **Sheet form (`SheetScaffold`):** ✕ trái (huỷ), ✓ phải (lưu, màu chính) là nút hệ thống; không chân sheet. ✓ luôn bấm được: thiếu thì giữ sheet, rung lỗi, nhãn dòng đỏ, câu lỗi `FormErrorText` hiện mượt (VoiceOver đọc). Không lắc. Chặn bấm ✓ hai lần.
- **Phần đầu sheet tiền:** `SheetAmountHeader` (nhãn nhỏ + `TimiAmountField`), cuộn cùng nội dung; mở bàn phím ngay khi thêm mới. Chip gợi ý: số đã gõ × 10³…10⁹, tối đa 5 chip `vndCompact`, transition mặc định (không nảy, không lăn số).
- **Dòng form:** `FormTextRow` kiểu iOS (nhãn trái, giá trị phải, chung một thẻ, không icon); `FormAmountRow`; `FormPickerRow` → `ChoiceSheet` (hiện icon/logo lựa chọn đang chọn); `FormDateRow` và `FormTimeRow` là hai dòng riêng, mỗi dòng mở sheet có ✕/✓; `FormValueLabel` (nhãn, giá trị xám, ›); `FormInfoRow` / `FormNoteText` cho chỉ xem. Bỏ hẳn ô "nhãn trên ô" (`TimiTextField`).
- **Nhóm form:** `FormGroup(title:)` có tiêu đề nhỏ in hoa (2026-10-29), ví dụ THÔNG TIN · THỜI GIAN · GHI CHÚ; nhóm nút xoá không tiêu đề.
- **Tiêu đề phần:** `SectionHeader` hai kiểu — `.section` (17 SemiBold, màu mực) trên nền màn chính; `.group` (`overline` 12 in hoa, xám) trong sheet/form/Cài đặt. Cả hai lùi 16pt, cách thẻ 8.
- **Sheet:** luôn `.sheet` hệ thống, nền `Palette.background`. Sheet chọn cao vừa nội dung (`timiFittedSheet`). `OptionSheet` "Thêm mới" chọn xong đóng rồi mới mở form. Sheet xem dùng `DetailScaffold` mở đầu bằng `SummaryCard`. Ô tìm trong sheet là `.searchable` (iOS 26 nằm dưới cùng).
- **Dòng danh sách:** `ListRow` (› mặc định, `trailingSubtitle` dưới số tiền) trong `listCard()`, ngăn bằng `RowDivider`. Bấm dòng: `.row` (màu chính 10%, nhả mờ dần); bấm thẻ: `.card` (mờ + thu nhỏ nhẹ). Tài khoản khoá: `LockBadge` ở góc icon, số tiền xám, dòng phụ "Đã khoá".
- **Logo & icon dòng:** `RowIcon` vẽ glyph hoặc logo ngân hàng/ví (`InstitutionLogo`) cùng một ô; logo không to hơn icon.
- **Thẻ đầu trang:** `SummaryCard` căn trái (nhãn nhỏ, `MoneyText(.display)`, icon bên phải).
- **Chip:** chip lọc trên trang đổi bằng `ChipRow` (chip chọn màu `primary`, danh sách mờ sang nội dung mới, giữ tối thiểu một màn hình cao). Chip trong màn tìm là `TagChip` thường, không kính (thường / gợi ý / có × / nổi xanh). Hàng chip chỉ cuộn ngang khi tràn (`NoScrollEdgeEffect` + `GlassEffectContainer`).
- **Badge (`StatusBadge`):** trung tính / đã thu (xanh lá 12%) / Pro / thông tin / caution (cam nhạt) / warning "Quá hạn" (đỏ nhạt); có biến thể icon.
- **Trạng thái trống (`EmptyStateCard`):** icon trơn 44 màu mực, một câu ngắn, **không nút** (thêm mới đi qua nút + của trang).
- **Nút tháng (`MonthMenu`):** viên kính mặc định iOS "Tháng 10 ⌄" cao 44 (`GlassCapsule`), cả viên nhận chạm; mở `MonthPickerSheet` (năm ‹ ›, lưới T1–T12, tháng chưa tới mờ, "Tháng này"). Dùng ở thanh trên Thu chi và Lịch thu chi.
- **Biểu đồ chi theo ngày (`DailySpendingChart`, Swift Charts):** chạm cột là chọn, kéo ngang để dò, vuốt dọc vẫn cuộn trang; hôm nay màu chính, ngày chưa tới nhạt; cột chọn màu chính.
- **Ô tìm tự vẽ (`SearchField`)** cho màn tìm toàn màn hình.

## Tổng quan

- **Thẻ chính** (`HeroCard`, 2026-10-30): nền màu chính đặc, chỉ "TÀI SẢN RÒNG ›", số to trắng và biểu đồ tăng trưởng 6 tháng (đường trắng + vùng mờ, không trục). Bấm cả thẻ mở trang **Tài sản ròng** (`NetWorthView`): số hiện tại + "↑ x so với cuối tháng N", biểu đồ 6 tháng có tên tháng (kéo ngón để xem "Cuối tháng 8"); mục "Gồm": Tài khoản (số dư dương) / Hũ tiết kiệm / Cho vay / Nợ (thẻ âm + đi vay), mỗi dòng trượt sang trang con (`NetWorthPartView`: danh sách tài khoản → chi tiết tài khoản, các hũ → chi tiết hũ, các khoản cho vay → sheet khoản vay), Nợ mở `DebtSheet`. Không nhảy sang tab khác (người dùng thấy giật). Tài sản ròng = số dư (gồm hũ) + cho vay − nợ (có nợ thẻ tín dụng); không tính tài khoản khoá.
- **Lịch sử tài sản ròng** (`netWorthHistory`): không lưu theo ngày; giá trị cuối mỗi tháng = hiện tại trừ ngược mọi khoản thu/chi sau đó (gồm điều chỉnh số dư, khoản không tính báo cáo, phí chuyển khoản, lãi vay; bỏ tài khoản khoá). Chuyển khoản, nạp/rút hũ, gốc khoản vay không đổi tài sản ròng. Tài khoản và khoản vay coi như luôn có, nên thêm ví có sẵn tiền không thành "tăng trưởng".
- Lời chào to (display), hai dòng "Chào buổi sáng,\nQuyet". Toolbar: avatar và chuông tròn 44pt Liquid Glass; avatar mở Cài đặt. Nền trang có 2 đốm màu mờ (`primary`, `sky`).
- Thứ tự: thẻ chính → Làm quen → Cần chú ý → Tháng tổng quan → Lịch → Timi Pro (cuối).
- **Tháng X tổng quan**: ô Tiền vào / Tiền ra nền xanh/đỏ nhạt (bấm mở Báo cáo), thanh hạn mức theo `budgetColor` (bấm mở Hạn mức chi tiêu).
- **Timi Pro**: thẻ trắng, badge PRO vàng, 3 quyền lợi tick xanh trơn, nút "Tìm hiểu Timi Pro"; viền vàng chạy 1 vòng (2,4s) khi thẻ hiện rồi dừng (không chạy khi Giảm chuyển động). Bấm mở "Sắp ra mắt".
- **Làm quen với Timi:** 4 việc (Thêm ví, Ghi thu chi, Ghi cho vay, Hỏi AI), việc chưa xong là dòng bấm được có › dẫn tới form/tab tương ứng; xong thì tick trắng trên vòng xanh, gạch ngang; xong cả 4 thì ẩn thẻ. Mỗi việc +5 lượt AI thật.
- Tổng quan tháng + hạn mức: hạn mức do người dùng đặt (`AppStorage`, cùng mức mỗi tháng, dùng chung với Giao dịch và Cài đặt); không lấy thu nhập làm hạn mức.
- Cần chú ý: nhắc trả/thu khoản vay (dữ liệu mẫu, chưa gửi thông báo thật).
- **Lịch thu chi:** nút tháng `MonthMenu`; lưới bắt đầu T2; ô ngày phẳng bo 8, không kính. Số tiền trong ô cùng cỡ 11pt. Màu ô chỉ theo mức chi (người dùng chọn): đỏ 8% / 14% / 20% (<1tr, 1–3tr, ≥3tr); tiền thu không tô ô, chỉ hiện số xanh; không có gì → `fill1`; hôm nay viền xanh 1,5pt + số xanh; ngày chưa tới mờ 40%, không bấm được. Chạm ngày mở sheet giao dịch trong ngày.

## Tài khoản & Hũ

- Tiêu đề "Tài khoản" + nút + trên toolbar. Nút + mở sheet "Thêm mới": Tiền mặt, Tài khoản ngân hàng, Ví điện tử, Hũ tiết kiệm.
- Thẻ Tổng số dư: tổng, dòng "3 tài khoản · 3 hũ" (bỏ số 0), nhãn ổ khoá "Đã khoá …" khi có tài khoản khoá.
- Tài khoản thanh toán: một dòng mỗi tài khoản (logo/icon, tên, số dư, ›), mở thẳng màn chi tiết. Màn chi tiết: `SummaryCard`, dòng "Từ ngày …", mục "Lịch sử"; bút chì mở form sửa.
- Form tài khoản: Ngân hàng/Ví (bắt buộc với loại đó, `InstitutionPickerSheet`), Tên (bắt buộc, tự điền theo ngân hàng), Số dư âm, "Số dư tính từ" + Giờ, công tắc **Khoá tài khoản** (thay "Không tính vào báo cáo"; khoá thì không tính vào tổng và báo cáo, không có trong ô chọn), Ghi chú.
- Sửa số dư không ghi đè: chênh lệch thành giao dịch "Điều chỉnh số dư" (không tính báo cáo).
- Tài khoản đã có lịch sử chỉ **lưu trữ** được (ẩn khỏi danh sách, ô chọn, tổng; lịch sử giữ nguyên), có "Khôi phục"; chưa có lịch sử (hoặc chỉ có điều chỉnh số dư) thì xoá hẳn. Danh sách ở "Tài khoản đã lưu trữ".
- **Hũ tiết kiệm:** thẻ cuộn ngang rộng 3/5 trang, dừng đúng mép (kiểu C, người dùng chọn 2026-10-28): icon không nền, tên, số đã để dành, "Mục tiêu 40tr · 70%", thanh tiến độ. Phần trăm làm tròn xuống.
- Màn hũ: thẻ "Đã để dành" căn trái, "92% · 167k/tháng" / "Mục tiêu 6tr"; nút "Rút tiền" (trái) / "Nạp tiền" (phải); "Lịch sử". Nạp/rút như chuyển khoản, không tính thu chi; chip gợi ý "Mỗi tháng …", "Còn thiếu …".
- Form hũ: không có "Đã để dành" (hũ bắt đầu 0đ); Biểu tượng là `IconQuickPicker` (2 × 6, icon đang chọn có vòng xanh, "…" mở sheet đầy đủ); công tắc Thời hạn → "Đến ngày" và chú thích số cần để dành mỗi tháng.
- Vòng đời hũ: đang để dành → đủ mục tiêu ("Mua ngay", "Rút hết", "Mục tiêu mới") → đã đóng (rời dãy thẻ và tổng, vào "Hũ đã hoàn thành", lịch sử chỉ xem, có "Mở lại hũ"). Hũ quá hạn chưa đủ: badge đỏ "Quá hạn".
- **"Mua ngay"** (người dùng chọn, thay "Dùng tiền"): mở `AddTransactionView(buying:)` chỉ chi tiêu, tài khoản là hũ, số tiền mặc định cả hũ; phần còn lại chọn tài khoản nhận rồi đóng hũ.
- Xoá hũ còn tiền: hỏi tài khoản nhận lại tiền trước khi xoá.

## Giao dịch — Thu chi

- Tiêu đề "Giao dịch", segmented Thu chi / Vay nợ. Thanh trên (Thu chi): nút tháng bên trái nút tìm.
- Thẻ tổng quan tháng: Đã chi / Đã thu (kèm số giao dịch), biểu đồ cao 44, dòng "Đã dùng 47% hạn mức" + thanh; đệm 16. Thẻ là số báo cáo nên gồm phí chuyển khoản và lãi.
- Chip Tất cả / Thu / Chi / Chuyển khoản — **mỗi chip một chuyện** (người dùng chọn): phí ở với chuyển khoản, không lên chip Chi, không cộng tổng ngày. "Điều chỉnh số dư" chỉ ở Tất cả. Tổng chi của ngày luôn xám.
- Danh sách gộp theo ngày (`ActivityDayList`); dòng: hạng mục, dòng phụ là ghi chú (hoặc nhóm), số tiền + giờ. Chạm mở sheet xem (`TransactionDetailSheet` / `TransferDetailSheet`), bút chì mở form.
- **Giao dịch không có tên riêng** (người dùng chọn 2026-10-29): tên là hạng mục; mô tả nằm ở ghi chú.
- Sheet thêm: Chi tiêu / Thu nhập / Chuyển khoản. Hạng mục bắt buộc là hạng mục con, **không tự chọn** ("Chưa chọn"); `CategoryPickerSheet` có tìm, "Gần đây", bút chì mở trang Hạng mục. Tài khoản mặc định là tài khoản dùng gần nhất (hoặc tài khoản đang xem). Công tắc "Không tính vào báo cáo".
- Chuyển khoản: Từ, Đến (hai tài khoản khác nhau, không gồm hũ), Phí (nằm trên chuyển khoản, tính là chi tiêu), không có dòng phí riêng.
- **Tìm kiếm:** kính lúp mở màn tìm toàn màn hình (`TransactionSearchView`, `fullScreenCover`, người dùng chọn): `SearchField` + ✕, chip "Bộ lọc" và chip lọc nhanh, "Tìm kiếm gần đây" (tối đa 8). Kết quả mọi tháng, không phân biệt dấu, nhiều từ không cần đúng thứ tự. Bộ lọc: Loại, Khoảng thời gian, Số tiền, Tài khoản, Nhóm hạng mục.
- Trang Hạng mục (Cài đặt → Hạng mục): nhóm là các dòng như Cài đặt iOS; hạng mục có giao dịch thì ẩn, không xoá; tên tối đa 30 ký tự, không trùng.

## Vay nợ

- Chỉ khoản vay với người (người dùng chọn); nợ thẻ tín dụng không ở đây nhưng vẫn tính vào Nợ ở Tổng quan và Trợ lý. Không có mục "Cần chú ý" (nhắc hạn ở Tổng quan).
- Thẻ tổng quan: "Chênh lệch" + số ròng, `SplitBar` (xanh lá cho vay / đỏ đang nợ), hai ô "Cho vay · 80tr · 2 người" / "Đang nợ · … người".
- Chip Tất cả / Cho vay / Đi vay (không có "Đã tất toán"). Khoản tất toán vào dòng "Khoản vay đã tất toán · N ›" cuối trang.
- `LoanCard`: chữ cái đầu, tên, "Hạn 6/11 · Lãi 375k", badge theo hạn, "Còn 45tr / 75tr", "Đã trả 40%", thanh tiến độ. Khoản gấp lên trước.
- Badge hạn (`LoanUrgency`): quá hạn đỏ; 0–7 ngày cam; 8–30 ngày xám; > 30 ngày xanh lá; không hạn xám; tất toán xanh lá.
- Form khoản vay: người chọn từ Danh bạ (`ContactPickerSheet`, "Thêm người mới" ở cuối); "Khoản có sẵn" (không đổi số dư) hoặc khoản mới (chọn tài khoản, ngày); lãi "% mỗi tháng" tính trên gốc; "Có hạn trả" → Hạn trả (sau ngày cho vay).
- Chạm khoản vay mở `LoanDetailSheet`; "Ghi nhận thu nợ / trả nợ" mở `LoanPaymentSheet` (tách gốc và lãi, chọn tài khoản). Lãi là thu/chi hệ thống vào báo cáo; gốc không. Tất toán bằng một lần thu/trả hết.

## Danh bạ

- Cài đặt → Chung → "Danh bạ" đẩy sang `ContactsView`: một thẻ, xếp A→Z theo tiếng Việt (`Locale.vietnam`), vòng chữ cái đầu, dòng phụ "Bạn bè · 1 khoản vay"; không chú thích dưới thẻ.
- Form: Tên (tối đa 40, không trùng, tự focus) và Mối quan hệ. Mối quan hệ có sẵn (Gia đình, Bạn bè, Đồng nghiệp, Người quen, Khác) + loại tự thêm có icon riêng (sửa/xoá được; xoá thì người thuộc loại đó về "Khác").
- Người còn khoản vay không xoá được. Người do app tự tạo tự xoá khi không còn khoản vay.

## Trợ lý AI & lượt AI

- Đầu trang "Timi" + dòng phụ trên toolbar, nút đồng hồ 44pt mở menu lịch sử trò chuyện trong phiên.
- Bong bóng trợ lý nền trắng + bóng card, bong bóng người dùng nền màu chính chữ trắng; avatar Timi là glyph xanh trơn. Ô nhập capsule, micro nhập giọng nói (`SFSpeechRecognizer` vi-VN), nút gửi tròn màu `primary`.
- Ghi/xoá giao dịch bằng câu lệnh theo quy tắc (chưa phải AI thật); xoá luôn hỏi xác nhận. Thẻ giao dịch trong chat mở sheet xem.
- **Lượt AI** (`AIQuota`, người dùng chọn): Miễn phí **20 lượt/tháng**, đầy lại ngày 1; Pro 300 (chưa bán). Mỗi việc "Làm quen" xong **+5 lượt thưởng** một lần, giữ tới khi dùng. Mỗi câu gửi (kể cả gợi ý) trừ lượt tháng trước, rồi lượt thưởng. Hết lượt: ô nhập thành thẻ "Đã dùng hết lượt AI · Lượt mới vào 1/11".

## Cài đặt

- Sheet cao toàn màn, ✕ trên trái; trang con đẩy (push) trong sheet.
- Từ trên xuống: thẻ hồ sơ (avatar vòng xanh nhạt + chữ Q xanh, "Dữ liệu mẫu · lưu trên máy", badge gói) → thẻ "Lượt AI tháng này" (số còn lại, thanh cam khi ≤ 3, lượt thưởng, ngày làm mới) → thẻ mời "Nâng cấp Timi Pro" (trắng, vương miện vàng trơn); 3 thẻ cách nhau 16 → Chung (Danh bạ, Hạng mục, Hạn mức chi tiêu, Báo cáo) → Thông báo → Hỗ trợ (gồm Giấy phép mã nguồn mở) → Nhà phát triển (Thư viện UI, Đặt lại dữ liệu mẫu).
- Mục chưa làm mở sheet ngắn "Sắp có", không để chạm vào mà không có gì. Thông báo: 3 công tắc chỉ lưu lựa chọn, chưa có tác dụng (chưa gửi thông báo, chưa đổi cảnh báo hạn mức).

## Hạn mức chi tiêu

- Trang đẩy từ Cài đặt → Chung (2026-10-30). Một hạn mức tổng mỗi tháng + hạn mức riêng cho từng nhóm hạng mục chi (tuỳ chọn). Cùng mức mọi tháng, **không cộng dồn** tiền dư.
- Chi tiêu tính như báo cáo (`total(.expense)`, gồm phí chuyển khoản và lãi vay; bỏ khoản không tính và tài khoản khoá).
- Thẻ trên cùng: "Còn lại" (hoặc "Đã vượt", đỏ), thanh `budgetColor`, "Đã chi x / y", và "Mỗi ngày chi được ~z" = còn lại ÷ số ngày còn lại tính cả hôm nay (chỉ tháng hiện tại, khi còn tiền). Badge "Sắp hết" từ 80%, "Vượt hạn mức" khi quá.
- **Xem rồi mới sửa** (2026-10-30): bấm thẻ tháng → Phân bổ hạn mức, bấm nhóm → chi tiết nhóm; sửa bằng ✎ trên thanh điều hướng của trang đó. Ngoài trang Hạn mức chỉ có "Đặt hạn mức tháng" khi chưa đặt.
- **Tổng hạn mức các nhóm ≤ hạn mức tháng** (`BudgetRules`): nhóm chỉ nhận tối đa phần chưa phân bổ; chưa có hạn mức tháng thì chưa đặt được cho nhóm; hạn mức tháng không hạ thấp hơn tổng các nhóm (bỏ hạn mức nhóm trước). Sai thì ✓ không lưu và báo đỏ dưới số tiền. Nhập 0 hoặc để trống để bỏ hạn mức.
- Thẻ "Còn lại" có "Phân bổ ›" và mở **Phân bổ hạn mức**: thanh chia hạn mức tháng theo nhóm (`ChartShades` như Báo cáo); "Chưa phân bổ" là phần rãnh trống (`muted`) với chấm rỗng viền xám; mỗi phần ghi đã chi / còn. Nhóm không có hạn mức riêng chi vào "Chưa phân bổ" và được liệt kê dưới đó. Mỗi nhóm mở trang chi tiết nhóm; ✎ sửa hạn mức tháng.
- Chip nhập nhanh: hạn mức tháng 5/10/15/20/30tr (bỏ mức thấp hơn tổng các nhóm); hạn mức nhóm 10% / 25% / 50% phần chưa phân bổ (làm tròn xuống 100k) và "Hết". Gõ số thì hiện gợi ý theo chữ số như mọi ô tiền.
- Chỉ nhóm chi đang dùng (`budgetGroupIDs`) có hạn mức: nhóm ẩn/xoá trả hạn mức về "Chưa phân bổ" (dọn khi mở trang Hạn mức và khi lưu); nhóm hệ thống (Phí chuyển khoản, Lãi vay) không có ✎. Hạn mức tháng về 0 thì trang Phân bổ tự đóng. "Đặt lại dữ liệu mẫu" đặt lại cả hạn mức.
- **Ghi giao dịch** (`BudgetNotice`): khoản chi đang nhập hiện một dòng dưới nhóm Chi tiết, đổi theo số tiền: "Ăn uống còn 170k → vượt 1,8tr". Lấy hạn mức nhóm, nhóm không có thì hạn mức tháng; nếu hạn mức tháng gặp nguy hơn thì báo hạn mức tháng. Xám khi ổn, cam từ 80%, đỏ khi vượt; không chặn lưu. Không hiện với thu nhập, chuyển khoản, khoản không tính, tài khoản khoá, chi từ hũ. Sửa giao dịch thì trừ số cũ trước. Khoản nhỏ làm số rút gọn không đổi (1,8tr → 1,8tr) thì ghi số đầy đủ.
- Hạn mức nhóm lưu ở `StorageKey.categoryBudgets` (`CategoryBudgets`, JSON theo id nhóm).

## Báo cáo

- Trang đẩy (2026-10-30), mở từ tiêu đề và hai ô tiền của thẻ "Tháng X tổng quan" (có ›) và dòng "Xem báo cáo" cuối thẻ tổng ở Giao dịch. Thanh tab giữ 4 mục.
- Kỳ: Tuần (thứ Hai → Chủ nhật) / Tháng bằng segmented (bỏ Năm, 2026-10-30); ‹ › là nút tròn Liquid Glass như nút tìm kiếm, › dừng ở kỳ có hôm nay.
- Thứ tự: Đã chi / Đã thu kèm "↑ x% so với … trước" (chi tăng đỏ, thu tăng xanh) và "Dư ra" → Chi theo hạng mục (vòng tròn 4 màu `ChartShades` + "Khác", chấm của nhóm thuộc "Khác" có viền xám mảnh; danh sách nhóm kèm % và mức thay đổi) → Thu chi 6 kỳ gần đây (cột xanh/đỏ, kỳ đang xem đậm, chạm cột để chuyển kỳ; trung bình chỉ tính kỳ có chi) → Theo tài khoản.
- Chi tiết nhóm hạng mục: cùng thanh kỳ; thẻ đã chi + so sánh + % tổng chi + thanh hạn mức (chỉ khi xem theo tháng); hạng mục nhỏ kèm thanh % và › — bấm mở giao dịch của riêng hạng mục nhỏ đó, **không có Tuần/Tháng** (dùng kỳ đã chọn ở trang nhóm, ghi "Đã chi tháng 10"); danh sách giao dịch.
- Danh sách giao dịch ở Báo cáo (`ReportTransactionList`): tối đa 5 dòng + "Xem tất cả n giao dịch" đẩy trang đầy đủ. Bấm một dòng mở sheet xem/sửa như trang Giao dịch (`ActivityEditor`); phí chuyển khoản mở khoản chuyển, lãi vay mở khoản vay. Nút ✎ trên thanh điều hướng sửa hạn mức nhóm. Mở từ Báo cáo và từ dòng nhóm có hạn mức ở trang Hạn mức chi tiêu.
- Khi kỳ trước chưa có số liệu: ghi "Chưa có số … trước", không ghi "mới" ở từng nhóm.
- Mở thêm từ Cài đặt → Chung → Báo cáo (2026-10-30).
- So sánh với **cùng số ngày** của kỳ trước khi kỳ đang chạy (`ReportPeriod.comparison`, ghi "so với cùng kỳ tháng trước"); kỳ đã qua so với cả kỳ trước. Thay đổi trên 100% ghi bằng số tiền ("↑ 4,3tr") thay vì %. Kỳ đang chạy ghi ngắn "↑ 80% · cùng kỳ" cho vừa một dòng (VoiceOver đọc đủ).
- Thẻ tổng thêm "TB mỗi ngày" (chia số ngày đã qua) và "Lớn nhất" (khoản chi lớn nhất + hạng mục); xem theo tháng có thêm dòng hạn mức tháng + thanh, bấm mở Hạn mức chi tiêu đúng tháng đang xem.
- Dòng "Theo tài khoản" bấm mở trang tài khoản hoặc hũ.
- 6 kỳ đều trống thì thay đồ thị bằng dòng "Chưa có thu chi trong 6 tuần này."

## Để sau

- `DayTransactionsSheet` (chạm ngày ở Lịch thu chi) chưa giống trang Giao dịch: dòng chưa chạm để xem/sửa, chưa có chuyển khoản. Làm bằng `ActivityRow` + `ActivityEditor` như `TransactionsView`.
- Danh bạ: chưa có tìm kiếm trong `ContactsView`; gợi ý "Có phải Minh Trần?" khi gõ tên gần giống.
- "Cần chú ý" mẫu lưu tên dạng chữ; khi làm lời nhắc thật thì lưu id khoản vay.
- Timi Pro chưa bán; nút Pro chỉ mở "Sắp ra mắt".
- Logo ngân hàng/ví là thương hiệu: xem lại nguồn và quy định trước khi phát hành.
- Thẻ tháng ở Thu chi và thẻ tháng ở Tổng quan vẫn tự làm, có thể chuyển sang thành phần chung sau.
- Rung và hiệu ứng bấm cần thử lại trên máy thật; chưa kiểm tra đủ iOS 17.6 và cỡ chữ trợ năng lớn.
