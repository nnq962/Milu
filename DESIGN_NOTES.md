# Ghi chú thiết kế Timi — quy tắc đang áp dụng

> Bản rút gọn, chỉ giữ quyết định mới nhất. Nhật ký đầy đủ theo ngày (lý do, các bản thử, số đo): [`docs/design-history.md`](docs/design-history.md). Quyết định mới: sửa thẳng mục tương ứng ở đây, rồi ghi một mục có ngày vào cuối file lưu trữ.

App iPhone SwiftUI, tiếng Việt, tiền VND. 3 tab: Tổng quan, Tài khoản, Giao dịch (Thu chi · Vay nợ), icon SF Symbols: tab đang chọn dạng đặc (người dùng 2026-10-30), tab khác dạng nét (đặc cả thì tab chưa chọn đen nặng hơn tab chọn; iOS 26 không nhận màu xám cho tab chưa chọn), + nút "+" tròn cạnh thanh tab. Trợ lý AI không còn là tab: Tổng quan đẩy sang trang riêng không có thanh tab (thanh tab cạnh ô nhập chữ trông rối); lịch sử chat giữ trong `AssistantChats` suốt phiên. Cài đặt mở từ avatar. Dữ liệu lưu trên máy (SwiftData), có dữ liệu mẫu. Mẫu nguồn: HTML Sleek trong `examples/`, design system của bản web (`finance-tracker-v2/docs/design`).

## Nguyên tắc chung

- **Native iOS trước:** `NavigationStack` + toolbar, `TabView`, `.sheet`, `Toggle`, alert, Swift Charts, `.searchable` của hệ thống. Chỉ đổi màu, font, cỡ, hình khi cần; không tự dựng lại thứ Apple đã có.
- **Thanh trên:** để iOS tự lo nền mờ / scroll-edge. Không tự làm header mờ bằng `Material`, blur, gradient, mask hay opacity theo offset. Tiêu đề màn và nút nằm trong `ToolbarItem`; nút tròn 44pt dùng glass riêng thì ẩn shared background của item trên iOS 26.
- **Liquid Glass chỉ trên lớp điều hướng** (người dùng 2026-10-31: bỏ kính trong nội dung): thanh trên, tab bar, nút + nổi, nút gửi trong ô chat cố định, nút đóng màn tìm. Mọi nút, chip, lưới nằm trong nội dung cuộn là nền phẳng (`flatCircleButton` / `flatCapsuleButton` / `TagChip`; thường `fill2` hoặc trắng viền mảnh, chọn thì `primary`), vì kính trong thẻ trôi chậm hơn thẻ khi cuộn. Ngoại lệ có chủ ý (người dùng 2026-10-31): Tổng quan dùng thẻ kính `glassCard()` trên nền `GlassBackdrop`, và 4 nút nhanh kính. Card trắng không viền, bóng ngắn sát mép dưới; ô nhỏ trong card không bóng.
- **Nút trên thanh điều hướng để thanh tự vẽ kính** (2026-10-30): trong `ToolbarItem` chỉ đặt `Button`/`Menu` trơn (nhãn là icon hoặc ảnh), không bọc `nativeCircleButton`/`glassEffect` và không `.sharedBackgroundVisibility(.hidden)`; nút cạnh nhau tách bằng `ToolbarSpacer(.fixed)`. Kính tự vẽ trong item không tham gia hiệu ứng push/pop nên hiện hình vuông lúc quay lại. Chữ "Q" vẽ thành `Image` để thanh xếp vào vòng tròn (chữ thì thành viên dài). Tiêu đề tab (Tài khoản, Giao dịch) là tiêu đề native `.inlineLarge` qua `TabHeading` (iOS 26), Manrope `pageTitle` 24: to bên trái, cuộn thì thu vào giữa thanh ở cả hai tab. Để vậy thanh phải còn chỗ: nút tháng của Thu chi nằm trong trang, cạnh "Đã chi" (dạng gọn chữ rêu 14, người dùng 2026-10-30), thanh chỉ còn tìm (và + ở Vay nợ). Trợ lý AI dùng `TabHeading` có phụ đề; không đặt chữ tiêu đề trong `ToolbarItem` (lúc quay lại nó hiện thành khối chữ nhật kính) và không ép nền thanh đặc; mép trên dùng lớp mờ mềm mặc định của iOS như Tổng quan, mọi tab giống nhau (người dùng 2026-10-30, bỏ kiểu `.hard`). Trợ lý AI cũng vậy, thêm phụ đề native (`navigationSubtitle`, Manrope `caption` xám, đặt qua `UINavigationBarAppearance` trong suốt); trang có nút ‹ nên iOS đặt tiêu đề giữa thanh.
- **Nút trên hàng tiêu đề phần** (người dùng 2026-10-30, sau khi thử viên kính nhỏ): chữ rêu 14 không kính, cao 44 để chạm, có › khi mở trang (`HeaderCapsuleLabel` + `.headerCapsuleGlass()`, giờ là nút trơn): "Lưu trữ (n) ›", "Đã xong (n) ›", "Xoá" ở Tìm kiếm gần đây, nút tháng ở Lịch thu chi. Chữ kết thúc đúng mép phải hàng tiêu đề.
- **Button giữ hiệu ứng của Apple:** không tự thêm scale/animation/shadow mô phỏng nhấn. iOS 26 dùng `glass` / `glassProminent`; `bordered*` chỉ để tương thích iOS cũ.
- **Không tự thêm CTA** hay đổi vị trí nút ngoài thiết kế.
- **Icon:** Hugeicons bản miễn phí, Stroke Rounded (MIT; người dùng chọn 2026-10-28, thay Solar). Asset `hugeicons-<mã>`, vẽ template qua `TimiIcon`; kho chung `IconCatalog` (311 icon, 15 nhóm). Thêm icon: bỏ SVG vào Assets + một dòng trong `IconCatalog`.
- **Icon không nền (không tile)** ở mọi dòng form, list, sheet, thẻ hũ, trạng thái trống. Trong một nhóm: hoặc mọi dòng có icon, hoặc không dòng nào. Ô nhập không kèm icon. Kiểu icon có ô nền cũ (`.formIconStyle(.tile)`, `IconCircle`) đã xoá 2026-10-31. Ngoại lệ: danh sách tài khoản đặt glyph tiền mặt trên ô trắng như logo ngân hàng (`RowIcon(tiled: true)`), để cột icon thẳng.
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
- **Bảng màu "TổngQuan"** (người dùng gửi và chốt 2026-10-30; thay bảng Sleek xanh ngọc): xanh rêu #3E5B3F (`primary`: nút chính, tab, chip chọn, switch, tiến độ, thẻ chính Tổng quan), xanh đậm #1E5A48 (`green`: dấu hiệu tốt — tăng trưởng, hạn mức còn xa, đã tất toán, cho vay), đỏ san hô #B5543F (`red`: tiền ra; bản mẫu #D9725B chỉ 3.2:1 nên làm đậm cho đạt 4.5:1), xanh chanh điện #C9F26B (`lime`; trước là vàng #E0A840, đổi 2026-10-31 theo hướng "Mực đêm"), đêm #14201A (`night`: thẻ Tài sản ròng, nút nhanh, banner Pro ở Tổng quan; chữ trên đó `onNight` trắng / `onNightMuted` trắng 64%, tiền âm `redOnNight` = san hô đồ thị, ô mờ `nightTile` trắng 10%), xanh lá nhạt #5FB89A (`sky`), cam `warning` cho hạn mức sắp hết, nền ấm #FAF7F2, chữ #1F2A22, chữ phụ #6F675B (mẫu #7A7266, đậm hơn một bậc), viền #ECE7DC.
- **Font** (2026-10-30): đã thử Be Vietnam Pro, Plus Jakarta Sans, Inter, SF Pro cạnh nhau trong app; người dùng chốt **Manrope ở đúng độ đậm ghi trong code**, các font kia đã gỡ.
- **Đơn sắc đang nghiên cứu** (người dùng 2026-10-31: "không dùng màu xanh rêu nữa", rồi "không thích màu xám": mono như ảnh Iconly, đen trắng là chính): combo "Đơn sắc" trong `AccentTrial` là **mặc định hiện tại**. Màu chính và chữ `ink` gần đen #111111; nền gần trắng #FAFAFA (người dùng 2026-10-31: "trắng hơn tí" so với #F5F5F7), `muted` #F3F3F4, `border` #E8E8EA chỉ làm khối nhạt và kẻ mảnh; `secondaryText` #6E6E73, `secondary` #AEAEB2 là xám duy nhất còn lại (chữ phụ, chevron). **Không có mảng xám vừa**: `green` (dấu hiệu tốt) = mực; `lime` (badge PRO, "+5 AI", nút `.accent`) = đen với chữ `onLime` trắng; nút nhanh là vòng trắng viền mảnh có bóng nhẹ. **Dữ liệu cần phân biệt thì dùng màu tươi nhỏ** như thanh Storage của mẫu: `chartSteps` xanh dương #2F7CF6 · cam #F5A623 · san hô #F5555D · tím #7C4DFF, "Khác" #D1D1D6; `sky` (cho vay, người) = xanh dương đó; `chartCoral` = san hô. Đỏ tiền ra #B5543F và cam cảnh báo giữ nguyên. Chuyển về rêu: Cài đặt → Nhà phát triển → Màu (thử) → "Rêu & Kem". Chốt đơn sắc thì sửa `AccentColor` trong Assets sang #111111.
- **Thử combo màu** (2026-10-30): Cài đặt → Nhà phát triển → "Màu (thử)" đổi ngay trên cả app (`AccentTrial`, lưu trên máy). Từ 2026-10-31 mỗi combo mang cả `neutrals` (ink, 2 xám) và `hues` (green, sky, lime, onLime, chartCoral, chartRest, `chartSteps` tuỳ chọn cho 4 màu đồ thị); các combo màu khác dùng bộ rêu mặc định, chỉ "Đơn sắc" đổi hết. `Palette.ink`, `secondaryText`, `secondary`, `green`, `sky`, `lime`, `onLime`, `chartCoral`, `chartRest`, `income`, `fill1/2/3`, `incomeTile`, `limeTile` và `ChartShades` đều là computed, đọc mỗi lần. 5 combo kiểu Apple, nền gần trắng pha nhẹ về phía màu chính, không xám: Rêu & Kem (mặc định), Xanh biển & Ngà lạnh, Lục bảo & Bạc hà, Chàm & Oải hương, Hổ phách & Giấy. Màu sáng (`isLight`) thì chữ trên nền chính, Q/chuông và thanh trạng thái Tổng quan chuyển màu mực. Chốt combo nào thì đặt nó làm mặc định trong `AccentTrial.choices` và `AccentColor` của Assets.
- **Đổi màu**: sửa bộ `moss` trong `AccentTrial.Neutrals`/`Hues` và combo tương ứng (màu chính, nền); `incomeTile` (= `green` 12%), `controlTint`, `rowPressed`, `fill1/2/3` tự theo. Riêng `AccentColor` trong Assets (nút hộp thoại hệ thống) phải sửa tay cho bằng `primary`. Màu đồ thị (`ChartShades`) lấy từ `Palette` nên cũng đổi theo.
- **Lime rất ít**: badge PRO, vương miện, viên "+5 AI", và trên nền đêm ở Tổng quan (đường tăng trưởng, icon nút nhanh, tick và link của banner Pro, số hôm nay trong lịch). Không dùng lime làm nền chữ dài.
- **Tiền vào màu mực có dấu "+" (`income` = `ink`), tiền ra luôn `red`** ở mọi nơi (dòng giao dịch, tổng, lịch, Cần chú ý, Trợ lý AI, ô nhập tiền). Người dùng chọn 2026-10-30: xanh đậm cũ lẫn với rêu của nút/tab. Cột "Thu" trong biểu đồ Báo cáo vẫn xanh để phân biệt cột.
- **Biểu tượng không có nền** ở mọi nơi (kể cả avatar Trợ lý AI: glyph xanh trơn); chỉ tô màu nét. Biểu tượng trên header (avatar, chuông, tìm, +, ‹ ›) màu chính.
- **Chữ**: tiêu đề, số tiền, chữ hoa nhỏ `.bold` = Manrope Bold; chữ khác `.semibold` = Manrope SemiBold. `Typography.instance(for:)` vẽ đúng độ đậm theo tên (người dùng 2026-10-30: bản hạ một bậc trông mỏng manh). Tab bar Manrope SemiBold.
- **Bo góc**: mọi thẻ 28 (`CardCorners.large`), nhóm form và thẻ trong Cài đặt 24 (`inset`), ô trong thẻ 20 (`flow`). Đệm thẻ 20 (`Spacing.card`), thẻ đầu trang 24. Khoảng cách giữa các khối 28 (`Spacing.section`). Vùng chạm ≥ 44.
- **Bóng** (người dùng 2026-10-30: nhẹ nhàng): mọi thẻ trắng dùng chung một bóng `softCardShadow()` (đen 2,5% r1 y0,5 + đen 4% r12 y4), không viền; qua `cardSurface(elevated:)`, `listCard()`, `sleekCard()`, bong bóng chat, thẻ hũ cuộn ngang. Không tự viết `.shadow` riêng cho thẻ.
- **Bớt card** (người dùng chọn 2026-10-30, kiểu Cake/MoMo/ZaloPay): mỗi trang chỉ một thẻ trắng nổi; còn lại là section phẳng trên nền (tiêu đề + dòng kẻ mảnh), khối nền nhạt không bóng, hoặc banner nền màu nhạt. Đang áp ở Tổng quan; các tab khác chưa đổi.
- **Đồ thị** (`ChartShades`, theo mẫu "TổngQuan"): 4 nhóm lớn nhất rêu `primary` / bạc hà `sky` / vàng `lime` / san hô `chartCoral`, "Khác" xanh xám `chartRest`.
- Bấm dòng: `.row` (màu chính 10%); bấm thẻ: `.card`.

## Màu

- Mọi màu lấy từ `Palette`; không viết cứng `.white` / `.black` (trừ chữ trắng trên thẻ xanh).
- `onPrimary` trắng; `controlTint` = `primary`; `onLime` = `ink`; `incomeTile` = `green` 12%; `fill1/2/3` = mực 4/6/10%.
- `ProgressBar` mặc định màu `primary`. Thanh hạn mức (`budgetColor`): màu mực < 80% (người dùng 2026-10-30: xanh dễ nhầm với màu chính), cam từ 80%, đỏ khi chạm/vượt 100%.

## Chữ & tiền tệ

- **Font Manrope** toàn app (cả tab bar — chữ SemiBold 10, segmented, tiêu đề thanh). Mỗi độ đậm trong code là đúng instance cùng tên của Manrope (`Typography.instance(for:)`), không còn đẩy lên một bậc.
- **Thang `TextRole`** (chốt 2026-10-28, nội dung 16), co giãn theo Dynamic Type; không đặt cỡ tay trong `Features/`:
  - hero 40 (số đang nhập) · display 34 (số dẫn đầu) · amountLarge 24 · pageTitle 24 · heading 20
  - title 17 Bold (tiêu đề phần trên màn chính, thẻ, sheet, hộp thoại)
  - body / amount / label 16 (tên dòng, giá trị, chữ gõ, số tiền cuối dòng)
  - caption / captionStrong 13 (phụ đề, chú thích, lỗi, chip, badge) · overline 12 in hoa (tiêu đề nhóm) · footnote 11
- Nút: 16 ở cỡ 44/56, 14 ở cỡ 36. Ô số tiền lớn co 52 → 38 → 28 khi số dài.
- **Tiền:** đầy đủ `10.000.000đ`, rút gọn `10,3tr` (`25k`, `2,5tr`, `1,2tỷ`). Đơn vị liền số, cùng font/cỡ/weight/baseline; dấu chấm phân nhóm, dấu phẩy thập phân; không dùng `₫`. Formatter chung `vnd` / `vndCompact`; số tiền vẽ bằng `MoneyText` (dấu, màu theo nghĩa).
- Ngày: "Hôm nay, 28/10", "Thứ Hai, 12/5"; năm khác thì ghi năm ("Thứ Ba, 27/10/2025"). Ngày ngắn một kiểu `Date.shortDay`: "6/11", năm khác "6/11/2025" (không số 0 đầu).
- Chính tả theo kiểu dấu "Xoá / Khoá / Hoá đơn / Sức khoẻ".

## Bo góc & khoảng cách

- `RoundedRectangle(..., style: .continuous)`; không path squircle tự vẽ, không capsule cho card. Sheet hệ thống giữ bo góc của Apple.
- `CardCorners` (2026-10-30): `large` 28 (thẻ có đệm 20: thẻ đầu trang, tổng, thẻ hũ) · `inset` 24 (nhóm form, thẻ Cài đặt, mọi khối danh sách `listCard`: đồng tâm với lề dòng 16 + góc icon ~9; người dùng: 28 làm 4 góc sát icon) · `flow` 20 (ô nhỏ trong thẻ) · `field` 12 · `icon` 10 · `calendarDay` 8.
- `Spacing` bội 4: lề màn 20; giữa các phần 28 (`section`), trang không card (Tổng quan, Tài khoản) 36 (`flatSection`); đệm thẻ 20, thẻ đầu trang / trạng thái trống 24 (`leadCard`); tiêu đề → thẻ `headerGap` 8 ở mọi trang; nội dung sheet form cách nhau 24.
- `RowMetrics`: lề 16; icon 20 trong cột 24; icon → chữ 14; vạch kẻ lùi 54; hàng một dòng đúng 52 (vừa switch native), có phụ đề ~62. `featureIcon` 44 (logo/icon đứng riêng), `iconChoice` 52, `toolbarGlyph` 22 / `toolbarGlyphFrame` 28.
- `ControlHeight`: nút 36 / 44 / 56. `ProgressBar` một cỡ 8pt.
- Token thêm 2026-10-31 (duyệt khó tính): `RowMetrics.chevron` 16 (`RowChevron`, › duy nhất của dòng), `linkChevron` 12 (› / ⌄ sau chữ rêu 14), `inlineGlyph` 14, `listLogo` 32 (logo tài khoản, avatar người, vòng hũ trong danh sách), `ringStroke` 3 (`ProgressRing`), `legendDot` 8 (`LegendDot`); màu `primaryTint`, `primaryTrack`, `primaryDash`, `limeTile`, `onRed`. Không viết cứng số trong `Features/` khi đã có token.

## Thành phần

- **Nút (`TimiButton`):** Chính (màu chính) / Phụ / Nổi bật (vàng, chỉ cho Pro) / Xoá / Xoá vĩnh viễn; cỡ 36/44/56; nền phẳng theo vai trò (Phụ `fill2`), mờ khi nhấn. Nút tắt: viên xám `fill2`, chữ xám. Nút trên thanh là `Button` trơn trong `ToolbarItem`, glyph `toolbarGlyph` 22 trong khung 28 (thanh tự vẽ kính); nút + luôn `hugeicons-add-circle`.
- **Nút thêm giao dịch:** nút + tròn tách riêng cạnh tab bar (`Tab(role: .search)`, iOS 26), có ở mọi tab, mở sheet chứ không đổi tab (người dùng chọn kiểu B). iOS 17 là tab thứ 5 "Thêm".
- **Sheet form (`SheetScaffold`):** ✕ trái (huỷ), ✓ phải (lưu, màu chính) là nút hệ thống; không chân sheet. ✓ luôn bấm được: thiếu thì giữ sheet, rung lỗi, nhãn dòng đỏ, câu lỗi `FormErrorText` hiện mượt (VoiceOver đọc). Không lắc. Chặn bấm ✓ hai lần.
- **Phần đầu sheet tiền:** `SheetAmountHeader` (nhãn nhỏ + `TimiAmountField`), cuộn cùng nội dung; mở bàn phím ngay khi thêm mới. Chip gợi ý: số đã gõ × 10³…10⁹, tối đa 5 chip `vndCompact`, transition mặc định (không nảy, không lăn số).
- **Dòng form:** `FormTextRow` kiểu iOS (nhãn trái, giá trị phải, chung một thẻ, không icon); `FormAmountRow`; `FormPickerRow` → `ChoiceSheet` (hiện icon/logo lựa chọn đang chọn); ngày và giờ là một dòng `FormDateTimeRow` ("Hôm nay, 17:12") mở một sheet có ✕/✓, `FormDateRow` khi chỉ cần ngày; `FormValueLabel` (nhãn, giá trị xám, ›); `FormInfoRow` / `FormNoteText` cho chỉ xem. Bỏ hẳn ô "nhãn trên ô" (`TimiTextField`).
- **Nhóm form:** `FormGroup(title:)` có tiêu đề nhỏ in hoa (2026-10-29), ví dụ THÔNG TIN · THỜI GIAN · GHI CHÚ; nhóm nút xoá không tiêu đề.
- **Tiêu đề phần:** `SectionHeader` hai kiểu — `.section` (17 Bold, màu mực) trên mọi trang chính, kể cả Báo cáo; `.group` (`overline` 12 in hoa, xám) trong sheet và form. **Mọi trang lùi 16** cho thẳng với chữ trong thẻ, kể cả trang không card như Tổng quan và Tài khoản (người dùng 2026-10-31). Tiêu đề và nút bên cạnh chung đường chân chữ, xếp dọc ở cỡ chữ trợ năng, VoiceOver đọc là tiêu đề. Không tự dựng tiêu đề riêng.
- **Duyệt sheet (2026-10-30):** ✓ luôn bấm được ở mọi form (đã sửa Hạng mục, Hũ, Nạp/rút hũ, Bộ lọc: thiếu thì báo đỏ "Nhập tên." / "Nhập mục tiêu." / "Nhập số tiền."); form chỉ xem thì không có ✓. Sheet vừa nội dung (`SheetHeader`) dùng nút ✕ / ✓ native (`role: .close` / `.confirm`, kính `.glass` / `.glassProminent` tròn, glyph hệ thống). Ghi chú ngắn (Cài đặt, Thông báo, Timi Pro) dùng chung `NoteSheet`. Sheet Dư nợ cuộn được, tiêu đề nhóm `SectionHeader(.group)` + `listCard`. Hạn mức chi tiêu cao `.large` như mọi form.
- **Sheet, đợt 2 (2026-10-30):** đã thử rồi bỏ bước hỏi "Bỏ thay đổi?" (người dùng: về như cũ, ✕ đóng ngay). Lưới hạng mục nhanh: nút tròn phẳng trắng viền mảnh (chọn thì nền rêu), lớn theo chữ, 3 cột khi chữ rất to; dùng `Grid` thường, không `LazyVGrid` (lưới lazy tính chiều cao trễ làm sheet Thêm giao dịch nháy khi mở). Tài khoản của giao dịch mới biết ngay khi tạo sheet (không đặt trong onAppear) để dòng "Tài khoản" không chèn vào sau. Chuyển khoản mới: "Từ" và "Đến" để trống ("Chọn"), người dùng tự chọn; bấm ✓ thiếu thì đỏ. "Không tính vào báo cáo" nằm trên ghi chú, như "Khoá tài khoản". Form thêm (tài khoản, hũ, nạp/rút, khoản vay) đều có tiêu đề nhóm. Tiêu đề nhóm (`SectionHeader(.group)`) in hoa nhỏ (`overline`) để khác chú thích. Thanh nắm sheet theo mặc định Apple (một chiều cao thì không có, nhiều chiều cao thì có); không ép `presentationDragIndicator`. Giao dịch trong sheet ngày (Lịch thu chi) chạm mở chi tiết, sửa bằng bút chì. Khoản vay: bớt chữ (dòng phụ "Khoản có sẵn" chỉ khi khoá, chú thích lãi chỉ khi có số). Bộ lọc: "Tài khoản", "Nhóm hạng mục" mỗi cái một dòng mở trang tick nhiều.
- **Sheet:** luôn `.sheet` hệ thống, nền `Palette.background`. Sheet chọn cao vừa nội dung (`timiFittedSheet`). `OptionSheet` "Thêm mới" chọn xong đóng rồi mới mở form. Sheet xem dùng `DetailScaffold` mở đầu bằng `SummaryCard`. Ô tìm trong sheet là `.searchable` (iOS 26 nằm dưới cùng).
- **Danh sách theo ngày (Thu chi, Tìm kiếm; duyệt HIG 2026-10-30):** mỗi ngày một thẻ (`ActivityDayList`), tiêu đề ngày 17 Bold + tổng ngày bên trên, thụt theo dòng trong thẻ (người dùng 2026-10-30: đã thử một khối liền, quá dài khó nhìn; không ghim tiêu đề vì nhoè dưới thanh). Tổng ngày luôn dạng gọn ("+850k  -120k"). Dòng phụ: ghi chú → nhóm hạng mục → tài khoản, không bao giờ lặp tên dòng. Biểu đồ chi theo ngày: ngày đã qua rêu 35%, hôm nay rêu, ngày tới xám. Chữ rất to: tổng ngày xuống dưới tên ngày, tên dòng 2 dòng, icon dòng lớn theo chữ (`ListRow`), nút chuyển Thu chi/Vay nợ to theo chữ (`ScaledSegmentedPicker`).
- **Dòng danh sách:** `ListRow` (› `RowChevron`, `trailingSubtitle` dưới số tiền, `compactAmount`) trong `listCard()`, ngăn bằng `RowDivider`. Tài khoản ở mọi danh sách (tab, Lưu trữ, Tài sản ròng, Nợ) là `AccountRow` + `AccountRowDivider`: logo/ô 32, tên `body`, số rút gọn `MoneyText`. Khoản vay `LoanRow` cùng cột 32 (vòng chữ cái đầu), cao 52. Bấm dòng: `.row`; bấm thẻ: `.card`.
- **Logo & icon dòng:** `RowIcon` vẽ glyph hoặc logo ngân hàng/ví (`InstitutionLogo`) cùng một ô; logo không to hơn icon.
- **Thẻ đầu trang:** `SummaryCard` căn trái (nhãn nhỏ, `MoneyText(.display)`, icon bên phải).
- **Chip:** chip lọc trên trang đổi bằng `ChipRow` (chip chọn màu `primary`, danh sách mờ sang nội dung mới, giữ tối thiểu một màn hình cao). Chip trong màn tìm là `TagChip` thường, không kính (thường / gợi ý / có × / nổi xanh). Hàng chip chỉ cuộn ngang khi tràn (`NoScrollEdgeEffect` + `GlassEffectContainer`).
- **Badge (`StatusBadge`):** trung tính / đã thu (xanh lá 12%) / Pro / caution (cam nhạt) / warning "Quá hạn" (đỏ nhạt); có biến thể icon.
- **Trạng thái trống (`EmptyStateCard`):** icon trơn 44 màu mực, một câu ngắn, **không nút** (thêm mới đi qua nút + của trang).
- **Nút tháng (`MonthMenu`):** `Menu` native, viên nền phẳng `fill2` cao 44 (không kính, 2026-10-31); dạng gọn ở Lịch thu chi là chữ rêu 14 + ⌄. Mỗi tháng dựng lại nút (`.id(title)`, không mờ chồng) để chiều rộng đúng khi đổi "Tháng 9" ↔ "Tháng 10". Năm khác ghi "Tháng 9/2025" ở cả nút và menu.
- **Thẻ tháng ở Thu chi (2026-10-30, người dùng: cân bằng, gọn):** ngay dưới segment, một thẻ trắng. Hàng trên: nút tháng (viên phẳng) bên trái, nút tròn phẳng biểu đồ mở Báo cáo bên phải, cùng cao 44. Dưới: "Đã chi" | "Đã thu" hai cột bằng nhau (`MoneyText(.large)`), kẻ dọc `VerticalDivider`; dòng hạn mức chỉ hiện từ 80%.
- **Vay nợ (2026-10-30, sửa 2026-10-31):** thẻ đầu trang như Thu chi: "Cho vay" | "Đi vay" hai cột bằng nhau (`MoneyText(.large)`, đi vay đỏ "-"), số người dưới mỗi cột. Dòng khoản vay `LoanRow` (vòng chữ cái 32, cao 52, ›).
- **Số tiền:** luôn `MoneyText` (cỡ `caption` / `row` / `large` / `display`; tone `signedIncome` "+" mực, `signedExpense` "-" đỏ, `signedNet` theo dấu, `negativeRed`, `muted`), không tự viết `Text(x.vnd)`. Cảnh báo hạn mức một kiểu: `BudgetStatusLine`.
- **Ô tìm tự vẽ (`SearchField`)** cho màn tìm toàn màn hình.

## Form Thêm giao dịch

- (Người dùng chọn 2026-10-30) Số tiền to 52 (38 / 28 khi dài). Giao dịch mới chi/thu có **hàng hạng mục chọn nhanh** (`QuickCategoryGrid`) dưới số tiền: 8 hạng mục dùng nhiều nhất (đếm giao dịch, thiếu thì lấy theo thứ tự danh sách), 4 cột, nút tròn trắng 52 + tên; chọn thì nền rêu, dòng "Hạng mục" bên dưới vẫn mở cả danh sách. Không hiện khi sửa hoặc "Mua ngay".
- Nhóm có tiêu đề như mọi form (người dùng 2026-10-31): **CHI TIẾT** (Hạng mục, Tài khoản, Thời gian — một dòng "Hôm nay, 17:12", `FormDateTimeRow`), **TUỲ CHỌN** ("Không tính vào báo cáo", chỉ chi/thu), **GHI CHÚ**.

## Tổng quan

- **Bố cục HIG, bề mặt đặc** (người dùng 2026-10-31, sau ba bản thử cùng ngày: "Mực đêm", "soft UI" card lồng card, thẻ kính): tiêu đề native "Tổng quan" `.inlineLarge` qua `TabHeading` như Tài khoản/Giao dịch; Q (vẽ thành `Image`) và chuông là nút trơn trong `ToolbarItem`, tách bằng `ToolbarSpacer`, thanh tự vẽ kính. Trang là các **section** cách nhau 28 (`Spacing.section`), mỗi section một `SectionHeader` (17 SemiBold, nút phải là chữ màu chính 14 `HeaderCapsuleLabel`) cách thẻ 8 (`headerGap`), và **một thẻ trắng** `sleekCard()` (bo 28, đệm 20, bóng mềm). **Không thẻ trong thẻ**: trong thẻ chỉ có chữ, số, đường kẻ mảnh `border`, thanh, icon tròn tô nhạt.
- **Liquid Glass đúng chỗ HIG**: chỉ thanh trên (nút Q, chuông), tab bar và nút + cạnh tab bar. Nội dung cuộn không có kính: thẻ đặc, nút nhanh là vòng phẳng. Đã thử thẻ kính + nền màu mờ (`glassCard`, `GlassBackdrop`) rồi bỏ cùng ngày vì HIG dành kính cho lớp điều khiển; nội dung trên kính khó đọc và phải bịa nền để kính có gì khúc xạ.
- Thứ tự: thẻ chính → nút nhanh → "Tháng này" → "Chi nhiều nhất" → Làm quen → Cần chú ý (đang ẩn) → Lịch thu chi.
- **Thẻ chính** (`HeroCard`, trắng, đệm 24): "Tài sản ròng" xám + › phải, số `display` mực (đỏ nếu âm), "↑ 15,6tr từ cuối tháng 5" (`NetWorthGrowth`: xanh / đỏ ↓ / xám 0), đường tăng trưởng 6 tháng màu chính cao 48. Bấm cả thẻ mở **Tài sản ròng** (`NetWorthView`, không đổi). Tài sản ròng = số dư (gồm hũ) + cho vay − nợ; không tính tài khoản khoá. Lịch sử: giá trị cuối tháng = hiện tại trừ ngược thu/chi sau đó.
- **Nút nhanh** (`QuickActions`): 4 vòng trắng 56 viền `border` 1pt + bóng `softCardShadow` (`flatCircleButton(fill: card)`, như nút tròn của mẫu Iconly; kính trước 2026-10-31, rồi tô `primaryTint` bị chê xám), icon màu chính, chữ 13 dưới (chạm chữ cũng mở): Ghi chi, Ghi thu, Chuyển tiền mở sheet thêm giao dịch đúng chế độ; Trợ lý AI trượt sang trang AI. Cỡ chữ trợ năng 2 cột.
- **Tháng này** (`MonthCard`, trắng; tiêu đề có "Báo cáo ›" mở `ReportRoute`): hai cột Đã thu / Đã chi (`captionStrong` xám + `MoneyText .large`, thu mực có "+", chi đỏ) ngăn bằng `VerticalDivider`; kẻ ngang `border`; "Chi theo nhóm" + "Hạn mức 30tr" (nếu có); **thanh 12pt** mỗi nhóm hạng mục một đoạn theo `ChartShades` (cùng màu Báo cáo, 4 nhóm lớn nhất), phần còn lại `chartRest`, phần trống = hạn mức còn lại (không hạn mức: thanh dài bằng số chi); chú thích chấm + tên (xếp dọc ở cỡ trợ năng). Chưa chi gì thì chỉ còn hai cột. Bấm thẻ mở Báo cáo.
- **Chi nhiều nhất** (`TopCategoriesCard`, trắng): 3 nhóm chi nhiều nhất tháng, mỗi nhóm icon 24 màu `ChartShades` trên vòng tròn 52 tô cùng màu 14%, tên `caption`, số rút gọn `captionStrong` xám. Không chi → ẩn cả section. Bấm thẻ mở Báo cáo.
- **Làm quen với Timi** (`OnboardingCard`, trắng): vòng màu chính 44 có "3/4", tên + bước kế tiếp xám, viên lime "+5 AI" (`StatusBadge .accent`), ›. Bấm làm bước đó; xong cả 4 thì ẩn; mỗi việc +5 lượt AI thật.
- **Cần chú ý:** đang ẩn (`showsAttention = false`, người dùng 2026-10-30).
- **Lịch thu chi**: `SectionHeader` + `MonthMenu` gọn (chữ màu chính 14) **ngoài thẻ** như mọi section (trang giữ `calendarMonth`), bên dưới `MoneyCalendarCard(displayedMonth:)` trong `sleekCard()`; lưới bắt đầu T2; ô ngày 44 chỉ số ngày + chấm mực nếu có tiền vào; màu ô theo mức chi đỏ 8/14/20%; hôm nay viền màu chính 1,5pt + số màu chính, không tô nền; ngày chưa tới mờ 40%, không bấm; chú thích nhỏ dưới lưới; chạm ngày mở sheet giao dịch trong ngày.
- **Timi Pro** không còn trên Tổng quan (banner bỏ 2026-10-31); mở từ Cài đặt.
- Token/khối của hai bản thử đã xoá: `night*`, `soft*`, `vivid*`, `SoftSurface`, `OverviewHeader`, `ActionDock`, `SpendingBarTile`, `MonthSummaryTiles`, `ProUpgradeCard`. `lime` giữ xanh chanh #C9F26B. `ProgressRing` có thêm `track:`, `HeaderCapsuleLabel` có `color:`, `MonthMenu` có `tint:` (đều mặc định như cũ).

## Tài khoản & Hũ

- Kiểu trang A+B (người dùng 2026-10-30, đổi được ở Cài đặt → Nhà phát triển): thẻ tổng `BalanceCard` (chung phần đầu `TotalBalanceHeader` với kiểu không thẻ), tài khoản trong `listCard`, hũ là thẻ cuộn ngang (bo 28, đệm 20). Các phần cách nhau 36.
- Tiêu đề "Tài khoản" + nút + trên toolbar nền đặc `background` (không chồng chữ khi cuộn). Dải rêu chỉ dùng ở Tổng quan (người dùng 2026-10-30).
- Tổng số dư nằm thẳng trên nền: nhãn, số to (`display`), "↑ x trong tháng này" xanh (↓ đỏ; `netWorthChange(since:)` từ ngày 1, ẩn khi 0), cạnh đó ổ khoá "Đã khoá …" khi có tài khoản khoá. Không có dòng đếm tài khoản hay thanh phân bổ.
- **Tài khoản** (người dùng chọn 2026-10-30, "một khối trắng"; lưới 2 cột xấu khi số tài khoản lẻ): các dòng trong một khối trắng bo góc có bóng (`listCard`), dòng chuẩn của app (đệm 10, tối thiểu 52; người dùng 2026-10-30: 64 cao hơn dòng Hạng mục): logo/icon 32, tên, số dư rút gọn (đỏ khi âm, xám khi khoá), ›; kẻ mảnh từ sau logo. Bấm mở màn chi tiết. "Lưu trữ (n) ›" chữ rêu nhỏ bên phải tiêu đề khi có tài khoản lưu trữ. (Đã thử: màu thương hiệu từng ngân hàng, dãy thẻ cuộn ngang, lưới 2 cột, dải rêu kiểu Tổng quan.) Duyệt HIG 2026-10-30: phần đầu tên "Ví & ngân hàng" (không lặp "Tài khoản" của tiêu đề trang); mọi icon trên cùng ô trắng viền mảnh như logo ngân hàng (`RowIcon(tiled: true)` trong `AccountRow`, ngoại lệ của quy tắc icon không nền, để cột trái thẳng hàng); hũ là dòng trong khối trắng giống tài khoản (`GoalRow`: vòng tiến độ 32 có icon, tên + hạn "6/11", "15tr / 50tr" + %), thay 2 thẻ to; cỡ chữ rất lớn thì số tiền xuống dưới tên. Tiêu đề trang trên thanh chỉ lớn thêm chút khi chữ to: giới hạn của iOS, không phải lỗi. Kiểu trang (2026-10-30; mặc định A + B, người dùng chọn), đổi thử ở Cài đặt → Nhà phát triển → "Kiểu trang Tài khoản (thử)", `AccountsLayout`): Hiện tại / Kiểu A (`BalanceCard`: tổng trong thẻ trắng, thanh tỉ lệ kiểu thanh dung lượng iPhone chỉ chia tiền dương của tài khoản không khoá + hũ, 4 phần lớn nhất màu biểu đồ, còn lại "Khác"; tài khoản âm ghi riêng dòng đỏ "Âm 2tr ở …"; tổng ≤ 0 thì số đỏ, ẩn thanh; chỉ một nơi có tiền cũng ẩn thanh) / Kiểu B (hũ là thẻ cuộn ngang `GoalCarouselTile` + ô "Hũ mới" viền đứt) / A + B.
- Form tài khoản: Ngân hàng/Ví (bắt buộc với loại đó, `InstitutionPickerSheet`), Tên (bắt buộc, tự điền theo ngân hàng), Số dư âm, "Số dư tính từ" + Giờ, công tắc **Khoá tài khoản** (thay "Không tính vào báo cáo"; khoá thì không tính vào tổng và báo cáo, không có trong ô chọn), Ghi chú.
- Sửa số dư không ghi đè: chênh lệch thành giao dịch "Điều chỉnh số dư" (không tính báo cáo).
- Tài khoản đã có lịch sử chỉ **lưu trữ** được (ẩn khỏi danh sách, ô chọn, tổng; lịch sử giữ nguyên), có "Khôi phục"; chưa có lịch sử (hoặc chỉ có điều chỉnh số dư) thì xoá hẳn. Danh sách ở "Tài khoản đã lưu trữ".
- **Hũ tiết kiệm:** dòng `GoalRow` (vòng tiến độ 32 `ProgressRing`, tên `body`, "10tr / 40tr" `MoneyText` rút gọn, ›) hoặc thẻ cuộn ngang `GoalCarouselTile` (vòng 56) theo kiểu trang; vòng đỏ khi quá hạn, "Đủ" khi đạt.
- Màn hũ: thẻ "Đã để dành" căn trái, "92% · 167k/tháng" / "Mục tiêu 6tr"; nút "Rút tiền" (trái) / "Nạp tiền" (phải); "Lịch sử". Nạp/rút như chuyển khoản, không tính thu chi; chip gợi ý "Mỗi tháng …", "Còn thiếu …".
- Form hũ: không có "Đã để dành" (hũ bắt đầu 0đ); Biểu tượng là `IconQuickPicker` (2 × 6, icon đang chọn có vòng xanh, "…" mở sheet đầy đủ); công tắc Thời hạn → "Đến ngày" và chú thích số cần để dành mỗi tháng.
- Vòng đời hũ: đang để dành → đủ mục tiêu ("Mua ngay", "Rút hết", "Mục tiêu mới") → đã đóng (rời danh sách và tổng, vào "Hũ đã hoàn thành", lịch sử chỉ xem, có "Mở lại hũ"). Hũ quá hạn chưa đủ: badge đỏ "Quá hạn".
- **"Mua ngay"** (người dùng chọn, thay "Dùng tiền"): mở `AddTransactionView(buying:)` chỉ chi tiêu, tài khoản là hũ, số tiền mặc định cả hũ; phần còn lại chọn tài khoản nhận rồi đóng hũ.
- Xoá hũ còn tiền: hỏi tài khoản nhận lại tiền trước khi xoá.

## Giao dịch — Thu chi

- Tiêu đề "Giao dịch", segmented Thu chi / Vay nợ. Thanh trên: nút tìm (Vay nợ thêm nút + `add-circle` như Tài khoản). Nút tháng nằm trong thẻ tháng.
- Tổng tháng: xem "Thẻ tháng ở Thu chi" ở mục Thành phần.
- Chip Tất cả / Thu / Chi / Chuyển khoản — **mỗi chip một chuyện** (người dùng chọn): phí ở với chuyển khoản, không lên chip Chi, không cộng tổng ngày. "Điều chỉnh số dư" chỉ ở Tất cả. Tổng ngày cạnh tiêu đề: "+" mực / "-" đỏ, rút gọn (`MoneyText(.caption)`).
- Danh sách gộp theo ngày (`ActivityDayList`); dòng: hạng mục, dòng phụ là ghi chú (hoặc nhóm), số tiền + giờ. Chạm mở sheet xem (`TransactionDetailSheet` / `TransferDetailSheet`), bút chì mở form.
- **Giao dịch không có tên riêng** (người dùng chọn 2026-10-29): tên là hạng mục; mô tả nằm ở ghi chú.
- Sheet thêm: Chi tiêu / Thu nhập / Chuyển khoản. Hạng mục bắt buộc là hạng mục con, **không tự chọn** ("Chưa chọn"); `CategoryPickerSheet` có tìm, "Gần đây", bút chì mở trang Hạng mục. Tài khoản mặc định là tài khoản dùng gần nhất (hoặc tài khoản đang xem). Công tắc "Không tính vào báo cáo".
- Chuyển khoản: Từ, Đến (hai tài khoản khác nhau, không gồm hũ), Phí (nằm trên chuyển khoản, tính là chi tiêu), không có dòng phí riêng.
- **Tìm kiếm:** kính lúp mở màn tìm toàn màn hình (`TransactionSearchView`, `fullScreenCover`, người dùng chọn): `SearchField` + ✕, chip "Bộ lọc" và chip lọc nhanh, "Tìm kiếm gần đây" (tối đa 8). Kết quả mọi tháng, không phân biệt dấu, nhiều từ không cần đúng thứ tự. Bộ lọc: Loại, Khoảng thời gian, Số tiền, Tài khoản, Nhóm hạng mục.
- Trang Hạng mục (Cài đặt → Hạng mục): nhóm là các dòng như Cài đặt iOS; hạng mục có giao dịch thì ẩn, không xoá; tên tối đa 30 ký tự, không trùng.

## Vay nợ

- Chỉ khoản vay với người (người dùng chọn); nợ thẻ tín dụng không ở đây nhưng vẫn tính vào Nợ ở Tổng quan và Trợ lý. Không có mục "Cần chú ý" (nhắc hạn ở Tổng quan).
- Đầu trang Vay nợ: thẻ hai cột "Cho vay" | "Đi vay" (xem mục Thành phần).
- Chip Tất cả / Cho vay / Đi vay (không có "Đã tất toán"). Khoản tất toán vào dòng "Khoản vay đã tất toán · N ›" cuối trang.
- `LoanRow`: vòng chữ cái 32, tên, dòng phụ "Hạn 6/11 · Lãi 375k · Đã trả 40%" (một dòng), số còn lại (đi vay đỏ "-"), ›. Khoản gấp lên trước. Ngày một kiểu "6/11", năm khác mới ghi năm.
- Badge hạn (`LoanUrgency`): quá hạn đỏ; 0–7 ngày cam; còn lại (8–30 ngày, > 30 ngày, không hạn) trung tính, cùng màu ở danh sách và sheet; tất toán xanh lá. Lần trả nợ của khoản đi vay là tiền ra (đỏ "-").
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
- Từ trên xuống: thẻ hồ sơ (avatar vòng xanh nhạt + chữ Q xanh, "Dữ liệu mẫu · lưu trên máy", badge gói) → thẻ "Lượt AI tháng này" (số còn lại + lượt thưởng, thanh vẽ phần **đã dùng** — 0/20 là thanh rỗng — cam khi còn ≤ 3, ngày làm mới); chữ ba thẻ ở cùng cột 54 với các dòng → thẻ mời "Nâng cấp Timi Pro" (trắng, vương miện vàng trơn); 3 thẻ cách nhau 16 → Chung (Hạng mục, Danh bạ, Báo cáo, Hạn mức chi tiêu) → Thông báo → Hỗ trợ (gồm Giấy phép mã nguồn mở) → Nhà phát triển (Thư viện UI, Màu (thử), Kiểu trang Tài khoản (thử), Lịch sử phiên bản, Đặt lại dữ liệu mẫu). Không dòng phiên bản lặp ở cuối trang.
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

- Trang đẩy (2026-10-30), mở từ nút biểu đồ trong thẻ tháng của Thu chi và từ Cài đặt. Tiêu đề phần `.section` + `listCard` (không dùng tiêu đề nhóm in hoa); "Đã chi" / "Đã thu" / "Dư ra" bằng `MoneyText` như Thu chi; dòng "Theo tài khoản" tiền ra đỏ.
- Kỳ: Tuần (thứ Hai → Chủ nhật) / Tháng bằng segmented (bỏ Năm, 2026-10-30); ‹ › là nút tròn phẳng (`flatCircleButton`), › dừng ở kỳ có hôm nay.
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

- `DayTransactionsSheet` chưa có chuyển khoản giữa các tài khoản.
- Danh bạ: chưa có tìm kiếm trong `ContactsView`; gợi ý "Có phải Minh Trần?" khi gõ tên gần giống.
- "Cần chú ý" mẫu lưu tên dạng chữ; khi làm lời nhắc thật thì lưu id khoản vay.
- Timi Pro chưa bán; nút Pro chỉ mở "Sắp ra mắt".
- Logo ngân hàng/ví là thương hiệu: xem lại nguồn và quy định trước khi phát hành.
- Thẻ hai cột (Thu chi, Vay nợ, Báo cáo) vẫn mỗi nơi tự dựng, có thể gộp thành một thành phần chung.
- Rung và hiệu ứng bấm cần thử lại trên máy thật; chưa kiểm tra đủ iOS 17.6 và cỡ chữ trợ năng lớn.
