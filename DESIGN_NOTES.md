# Ghi chú thiết kế Timi — quy tắc đang áp dụng

> Bản rút gọn, chỉ giữ quyết định mới nhất. Nhật ký đầy đủ theo ngày (lý do, các bản thử, số đo): [`docs/design-history.md`](docs/design-history.md). Quyết định mới: sửa thẳng mục tương ứng ở đây, rồi ghi một mục có ngày vào cuối file lưu trữ.

App iPhone SwiftUI, tiếng Việt, tiền VND. 3 tab: Tổng quan, Tài khoản, Giao dịch (Thu chi · Vay nợ), icon SF Symbols: tab đang chọn dạng đặc (người dùng 2026-10-30), tab khác dạng nét (đặc cả thì tab chưa chọn đen nặng hơn tab chọn; iOS 26 không nhận màu xám cho tab chưa chọn), + nút "+" tròn cạnh thanh tab. Trợ lý AI không còn là tab: Tổng quan đẩy sang trang riêng không có thanh tab (thanh tab cạnh ô nhập chữ trông rối); lịch sử chat giữ trong `AssistantChats` suốt phiên. Cài đặt mở từ avatar. Dữ liệu lưu trên máy (SwiftData), có dữ liệu mẫu. Mẫu nguồn cũ (HTML Sleek, design system web) đã bỏ 2026-10-31; thiết kế đi theo HIG và bộ Đơn sắc dưới đây. Kế hoạch dọn và các quyết định: [`docs/design-system-plan.md`](docs/design-system-plan.md).

## Nguyên tắc chung

- **Native iOS trước:** `NavigationStack` + toolbar, `TabView` (`Tab(role: .search)` cho nút +), `.sheet`, `Toggle`, `Menu`, `Picker(.segmented)`, alert, Swift Charts, `.searchable` của hệ thống. Chỉ đổi màu, font, cỡ, hình khi cần; không tự dựng lại thứ Apple đã có. **iOS 26 tối thiểu** (2026-10-31): không còn nhánh `#available` hay tiêu đề vẽ tay; thiết kế dựa thẳng trên Liquid Glass.
- **Hai lớp (HIG):** lớp điều khiển là Liquid Glass do iOS vẽ: thanh trên, tab bar, nút + cạnh tab bar, nút gửi trong ô chat cố định, nút đóng màn tìm, ✕/✓ của sheet. Lớp nội dung là bề mặt đặc: nền trang, thẻ trắng, dòng. **Không kính trong nội dung cuộn** (người dùng 2026-10-31: kính trong thẻ trôi chậm hơn thẻ khi cuộn), **không thẻ trong thẻ**. Mọi nút, chip, lưới trong nội dung là nền phẳng (`flatCircleButton` / `flatCapsuleButton` / `TagChip`: `fill2` hoặc trắng viền mảnh, chọn thì `primary`).
- **Thanh trên:** để iOS tự lo nền mờ / scroll-edge; không tự làm header bằng `Material`, blur, gradient hay opacity theo offset. Trong `ToolbarItem` chỉ đặt `Button`/`Menu` trơn (nhãn là icon hoặc ảnh), không bọc `glassEffect`; nút cạnh nhau tách bằng `ToolbarSpacer(.fixed)`. Chữ "Q" vẽ thành `Image` để thanh xếp vào vòng tròn. Tiêu đề tab là tiêu đề native `.inlineLarge` qua `TabHeading` (Manrope `pageTitle` 24, to bên trái, cuộn thì thu vào giữa thanh); Trợ lý AI thêm phụ đề native (`navigationSubtitle`, `caption` xám qua `UINavigationBarAppearance` trong suốt). Thanh phải còn chỗ cho tiêu đề: nút tháng của Thu chi nằm trong trang.
- **Nút trên hàng tiêu đề phần** (`HeaderLink` + `.headerLinkButton()`; người dùng 2026-10-30, sau khi thử viên kính nhỏ): chữ 14 màu chính, không nền, cao 44 để chạm, › khi mở trang, ⌄ khi mở menu: "Lưu trữ (n) ›", "Đã xong (n) ›", "Xoá", "Báo cáo ›", tháng của Lịch thu chi. Chữ kết thúc đúng mép phải hàng tiêu đề.
- **Button giữ hiệu ứng của Apple:** nút hệ thống là `glass` / `glassProminent`; nút tự vẽ chỉ mờ 0,6 khi nhấn (`FlatButtonStyle`, `.card`), dòng lấy màu `rowPressed` (`.row`). Không scale, không spring, không shadow mô phỏng nhấn (bỏ 2026-10-31).
- **Mọi thứ chạm được là một control:** nhãn dưới nút tròn (nút nhanh, lưới hạng mục) nằm trong `Button`, không `onTapGesture` riêng; `onTapGesture` chỉ để đưa focus vào ô nhập.
- **Trợ năng:** chữ co theo Dynamic Type (`textRole`, `@ScaledMetric` cho icon và nút), cỡ trợ năng thì hai cột xếp dọc (`SplitTotals`, `SectionHeader`), nút nhanh 2 cột, lưới hạng mục 3 cột; Reduce Motion tắt lăn số và animation (`accessibilityReduceMotion` ở ô tiền, dòng giá trị, dòng hạn mức, danh sách Thu chi, kiểu nhấn); màu không mang nghĩa một mình: tiền ra có "-", tăng giảm có ↑/↓, hạn mức có glyph. Mọi thứ bấm được có `accessibilityLabel`.
- **Không tự thêm CTA** hay đổi vị trí nút ngoài thiết kế.
- **Icon:** hai họ, ranh giới rõ: **SF Symbols** cho control hệ thống (tab bar, ✕ ✓ của sheet, +, xoá chữ trong ô tìm); **Hugeicons** Stroke Rounded (MIT; người dùng chọn 2026-10-28) cho nội dung: hạng mục, tài khoản, dòng form, nút trên thanh (asset `hugeicons-<mã>`, vẽ template qua `TimiIcon`; kho `IconCatalog`). Thêm icon: bỏ SVG vào Assets + một dòng trong `IconCatalog`.
- **Icon không nền (không tile)** ở mọi dòng form, list, sheet, thẻ hũ, trạng thái trống. Trong một nhóm: hoặc mọi dòng có icon, hoặc không dòng nào. Ô nhập không kèm icon. Ngoại lệ: danh sách tài khoản đặt glyph tiền mặt trên ô trắng như logo ngân hàng (`RowIcon(tiled: true)`), để cột icon thẳng.
- **Dòng hành động màu chữ (`label`):** việc hoàn tác được ("Lưu trữ tài khoản", "Khôi phục", "Mở lại hũ", "Thêm hạng mục") dùng `FormActionRow`, chữ và dấu + màu mực, không ›. Xoá dùng `FormDestructiveRow` đỏ, có icon thùng rác.
- **Xoá luôn hỏi lại** bằng alert giữa màn hình (Huỷ + nút đỏ lặp tên hành động), rung cảnh báo.
- **Xem trước, sửa sau:** chạm một mục mở màn/sheet xem; bút chì (`EditToolbarButton`) trên thanh mở form sửa; xoá nằm cuối form sửa. Không dùng menu nhấn giữ.
- **Lưu trữ thay vì xoá** khi đã có lịch sử (tài khoản); hũ đóng thay vì mất. Mục chỉ xem thì mở sheet xem, ghi lý do.
- **Ít chữ:** placeholder 1–3 từ; nhãn dòng tự nói nghĩa; chú thích dưới nhóm chỉ khi có thông tin tính sẵn hoặc lỗi; không footer giải thích dưới nút hành động.
- **Bàn phím:** không có thanh "Xong", không nút xoá nhanh trong ô; chạm ra ngoài hoặc kéo nội dung để đóng (`keyboardDismissArea()`).
- **Rung:** `.sensoryFeedback(.selection)` khi đổi chip/lựa chọn/cột biểu đồ; `Haptics.success` khi ✓ lưu; `Haptics.warning` khi xoá; `Haptics.error` khi lưu thiếu thông tin.
- **Ngày ghi tiền** không sau hôm nay (giao dịch, chuyển khoản, nạp/rút, thu/trả nợ) — người dùng chọn.
- Chuyển tab tức thì, không cross-fade (`InstantTabSwitch`). Ẩn chỉ báo cuộn dọc toàn app.

## Giao diện: Đơn sắc, một theme sáng (2026-10-31)

- **Chỉ một giao diện sáng**: app khoá sáng bằng `UIUserInterfaceStyle = Light`. Dark mode để sau: token đặt theo vai trò nên khi làm chỉ thêm một bộ giá trị trong `Palette`.
- **Bộ Đơn sắc** (người dùng 2026-10-31: "không dùng màu xanh rêu nữa", "không thích màu xám", mono như ảnh Iconly): chữ và mọi hành động là mực #111111 trên trang gần trắng #FAFAFA; xám chỉ còn ở khối nhạt #F3F3F4, kẻ mảnh #E8E8EA, chữ phụ #6E6E73 và chevron #AEAEB2. Màu chỉ mang nghĩa: tiền ra đỏ #B5543F, cảnh báo cam #E8890C, dấu hiệu tốt xanh lá #15803D **chỉ cho chấm, mũi tên, chữ 13, không bao giờ làm nền** (5:1 trên trắng), dữ liệu 4 màu nhỏ xanh dương #2F7CF6 · cam #D97706 · san hô #F5555D · tím #7C4DFF, "Khác" xám #8E8E93 (mỗi màu ≥ 3:1 trên trắng, HIG cho đồ hoạ mang nghĩa). PRO và "+5 AI" là viên `primary` đen chữ trắng, không có màu nhấn riêng. Bảng rêu cũ và các combo thử đã xoá khỏi code 2026-10-31 (xem `docs/design-history.md`); `AccentColor` trong Assets = #111111.
- **Token theo vai trò** (`Palette`, hằng số; đổi màu thì đổi giá trị, không đổi tên). **Mỗi token phải có nơi gọi**, không có thì xoá (người dùng 2026-10-31: quá nhiều màu); hiện 23: nền `background` / `surface` (thẻ) / `surfaceMuted` (khối nhạt, ô chat) / `separator`; chữ `label` / `secondaryLabel` / `tertiaryLabel`; hành động `primary` / `onPrimary` / `primaryTint` (10%: ổ avatar, rãnh vòng) / `primaryDash` / `rowPressed` / `fill` (mực 6%: nút phụ, badge trung tính); nghĩa `negative` / `onNegative` / `positive` / `warning` / `warningLabel`; dữ liệu `chart[4]` / `chartRest`. Thư viện UI (Cài đặt → Nhà phát triển) liệt kê đúng các token này với mã hex đọc từ màu.
- **Font** (2026-10-30): **Manrope** ở đúng độ đậm ghi trong code (`Typography.instance(for:)`), đã thử Be Vietnam Pro, Plus Jakarta Sans, Inter, SF Pro cạnh nhau. Tab bar Manrope SemiBold 10, segmented và tiêu đề thanh cũng Manrope.
- **Mép thẻ** (người dùng 2026-10-31, đề xuất Q2 của `docs/design-system-plan.md`): mọi thẻ trắng tách khỏi nền bằng **viền mảnh 1pt `separator`, không bóng** (`cardSurface(outlined: true)`, `card()`, `listCard()`, bong bóng chat `cardOutline`, nút tròn trắng). Ô nhỏ trong thẻ không viền. Bóng mềm cũ đã bỏ: trên nền gần trắng thẻ tan vào nền.
- **Bớt card** (người dùng 2026-10-30): mỗi section một thẻ; phần còn lại là tiêu đề phẳng trên nền. Không thẻ trong thẻ.
- **Tiền vào màu chữ có "+"**, **tiền ra luôn `negative`** ở mọi nơi (dòng, tổng, lịch, Trợ lý AI, ô nhập tiền). Cột "Thu" trong biểu đồ Báo cáo xanh lá để phân biệt cột.
- **Biểu tượng không có nền** ở mọi nơi; chỉ tô màu nét. Biểu tượng trên thanh màu chính.
- **Đồ thị** (`ChartShades` = `Palette.chart`): 4 nhóm lớn nhất xanh dương / cam / san hô / tím, "Khác" xám; dùng chung ở Báo cáo, Phân bổ hạn mức, `SegmentedBar` của Tổng quan và Tài khoản, `TopCategoriesCard`.

## Màu

- Mọi màu lấy từ `Palette`; không viết cứng `.white` / `.black` / hex trong `Features/` (trừ `Color(.placeholderText)` của ô nhập).
- `onPrimary` / `onNegative` trắng; `positive` chỉ cho dấu nhỏ; `fill` = mực 6%; `rowPressed` = `primary` 10%.
- `ProgressBar` mặc định `primary`. Thanh hạn mức (`budgetColor`): màu chữ < 80% (xanh dễ nhầm với màu chính), cam từ 80%, đỏ khi chạm/vượt 100%.
- Badge (`StatusBadge`): trung tính `fill2`; **"Đã thu" trắng viền mảnh chấm `positive`** (2026-10-31: nền xám 12% trùng Trung tính); Pro (`.pro`) `primary` đen chữ trắng, chấm trắng; caution cam 16% chữ `warningLabel`; warning đỏ 10% chữ đỏ.

## Chữ & tiền tệ

- **Thang `TextRole`** (chốt 2026-10-28, nội dung 16), co giãn theo Dynamic Type; không đặt cỡ tay trong `Features/`:
  - amountEntry 52 → 38 → 28 (số đang nhập, `TextRole.amountEntrySize(for:)`) · display 34 (số dẫn đầu, line box 42) · amountLarge 24 (số lớn trong thẻ, line box 32) · pageTitle 24 · heading 20
  - title 17 Bold (tiêu đề phần trên màn chính, thẻ, sheet, hộp thoại)
  - body / amount / label 16 SemiBold (tên dòng, giá trị, chữ gõ, số tiền cuối dòng: **cùng độ đậm với tên**, người dùng 2026-10-31, trước là Bold) · accessory 14 (nút cạnh tiêu đề)
  - caption / captionStrong 13 (phụ đề, chú thích, lỗi, chip, badge, chú thích đồ thị) · overline 12 in hoa (tiêu đề nhóm) · footnote 11 (trục đồ thị)
- Tiêu đề, số tiền, chữ hoa nhỏ `.bold` = Manrope Bold; chữ khác `.semibold`. Nút: 16 ở cỡ 44/56, 14 ở cỡ 36.
- **Tiền:** đầy đủ `10.000.000đ`, rút gọn `10,3tr` (`25k`, `2,5tr`, `1,2tỷ`). Đơn vị liền số, cùng font/cỡ/weight/baseline; dấu chấm phân nhóm, dấu phẩy thập phân; không dùng `₫`. Formatter chung `vnd` / `vndCompact`; số tiền vẽ bằng `MoneyText` (dấu, màu theo nghĩa).
- Ngày: "Hôm nay, 28/10", "Thứ Hai, 12/5"; năm khác thì ghi năm. Ngày ngắn một kiểu `Date.shortDay`: "6/11", năm khác "6/11/2025".
- Chính tả theo kiểu dấu "Xoá / Khoá / Hoá đơn / Sức khoẻ".

## Bo góc & khoảng cách

- `RoundedRectangle(..., style: .continuous)`; không path squircle tự vẽ, không capsule cho card. Sheet hệ thống giữ bo góc của Apple.
- `CardCorners`: `large` 28 (thẻ có đệm 20: thẻ đầu trang, tổng, thẻ hũ) · `inset` 24 (nhóm form, thẻ Cài đặt, mọi `listCard`: đồng tâm với lề dòng 16 + góc icon ~9) · `flow` 20 (ô nhỏ trong thẻ, bong bóng chat) · `field` 12 · `icon` 10 · `calendarDay` 8.
- `Spacing` bội 4: lề màn 20 (`page`); **giữa các phần 28 (`section`) ở mọi trang** (bỏ 36 của trang không thẻ, 2026-10-31); tiêu đề → thẻ 8 (`headerGap`); đệm thẻ 20 (`card`), thẻ đầu trang / trạng thái trống 24 (`leadCard`); nội dung sheet form cách nhau 24.
- `RowMetrics`: lề 16; icon 20 trong cột 24; icon → chữ 14; vạch kẻ lùi theo cột icon (`RowDivider(column:)`); hàng một dòng đúng 52, có phụ đề ~62; `featureIcon` 44, `iconChoice` 52, `toolbarGlyph` 22 / `toolbarGlyphFrame` 28, `chevron` 16 (`RowChevron`), `linkChevron` 12 (› ⌄ × sau chữ), `inlineGlyph` 14, `listLogo` 32, `ringStroke` 3, `legendDot` 8.
- `ControlHeight`: nút 36 / 44 / 56, ô nhập 44. Mọi thanh (`ProgressBar`, `SegmentedBar`) 8pt. Vùng chạm ≥ 44 ở mọi control, kể cả chip 36 (vùng chạm rộng hơn hình).

## Thành phần

- **Thẻ:** `card(padding:radius:)` (trắng, đệm 20, bo 28, viền mảnh) cho thẻ có nội dung tự do; `listCard()` (bo 24, không đệm) cho khối dòng; `cardSurface(radius:color:outlined:)` khi cần hình khác; `settingsCard()` ở Cài đặt (bo 24, chữ lùi 16). `SummaryCard` là thẻ đầu trang căn trái (nhãn nhỏ, `MoneyText(.display)`, icon phải).
- **Hai cột (`SplitTotals`, 2026-10-31):** "Đã chi | Đã thu" (Thu chi, Tổng quan, Báo cáo), "Cho vay | Đi vay": nhãn `captionStrong` xám, `MoneyText(.large)`, dòng phụ tuỳ chọn (số người, so với kỳ trước), kẻ dọc `VerticalDivider`; cỡ trợ năng xếp dọc với `SplitLine`. Không tự dựng hai cột nữa.
- **Thanh chia phần (`SegmentedBar` + `LegendRow`, 2026-10-31):** tiền ở đâu (Tài khoản), chi theo nhóm trên hạn mức (Tổng quan), hạn mức theo nhóm (Phân bổ); màu `ChartShades`, khe 2pt, phần trống là rãnh `surfaceMuted`, cao 8; chú thích chấm + tên (`FlowLayout`, `caption` xám).
- **Nút (`TimiButton`):** Chính (`primary`) / Phụ (`fill`) / Xoá (đỏ 14%) / Xoá vĩnh viễn (đỏ) — bỏ "Nổi bật" 2026-10-31 vì trong Đơn sắc nó y hệt Chính; cỡ 36/44/56; nền phẳng, mờ khi nhấn; nút tắt viên xám chữ xám. Nút trên thanh là `Button` trơn trong `ToolbarItem`, glyph 22 trong khung 28; nút + luôn `hugeicons-add-circle`. Nút tròn phẳng trong nội dung `flatCircleButton` (‹ › Báo cáo, biểu đồ ở Thu chi).
- **Nút thêm giao dịch:** nút + tròn tách riêng cạnh tab bar (`Tab(role: .search)`), có ở mọi tab, mở sheet chứ không đổi tab.
- **Sheet form (`SheetScaffold`):** ✕ trái (huỷ), ✓ phải (lưu, màu chính) là nút hệ thống `role: .close / .confirm`; không chân sheet. ✓ luôn bấm được: thiếu thì giữ sheet, rung lỗi, nhãn dòng đỏ, `FormErrorText` hiện mượt (VoiceOver đọc). Chặn bấm ✓ hai lần. **Mọi sheet đi qua `SheetScaffold`** (2026-10-31, người dùng chọn thanh thật thay thanh tự vẽ `SheetHeader`): sheet ngắn (chọn, ghi chú, lịch, Thêm mới) đặt `fitsContent: true` để cao vừa nội dung + thanh, cuộn khi vượt màn; sheet xem dài (Nợ, giao dịch trong ngày) thêm `.timiSheetStyle([.medium, .large])`. Ghi chú ngắn dùng `NoteSheet`. Nền sheet `background`; thanh nắm theo mặc định Apple.
- **Phần đầu sheet tiền:** `SheetAmountHeader` (nhãn nhỏ + `TimiAmountField` cỡ `amountEntry`), cuộn cùng nội dung; mở bàn phím ngay khi thêm mới. Chip gợi ý: số đã gõ × 10³…10⁹, tối đa 5 chip `vndCompact`, `TagChip` phẳng trong `GlassEffectContainer`.
- **Dòng form:** `FormTextRow` kiểu iOS (nhãn trái, giá trị phải, chung một thẻ); `FormAmountRow`; `FormPickerRow` → `ChoiceSheet`; `FormDateTimeRow` ("Hôm nay, 17:12") / `FormDateRow`; `FormValueLabel`; `FormInfoRow` / `FormAmountInfoRow` chỉ xem; `FormToggleRow` là `Toggle` native màu `primary`. Nhóm `FormGroup(title:)` tiêu đề nhỏ in hoa (`SectionHeader(.group)`), ngăn bằng `FormDivider`.
- **Tiêu đề phần:** `SectionHeader` — `.section` (17 Bold) trên mọi trang chính kể cả Báo cáo; `.group` (`overline` 12 in hoa, xám) trong sheet và form. Mọi trang lùi 16 cho thẳng với chữ trong thẻ. Tiêu đề và nút bên cạnh chung đường chân chữ, xếp dọc ở cỡ trợ năng.
- **Danh sách theo ngày (Thu chi, Tìm kiếm):** mỗi ngày một thẻ (`ActivityDayList`), tiêu đề ngày 17 Bold + tổng ngày gọn ("+850k  -120k"). Dòng phụ: ghi chú → nhóm hạng mục → tài khoản, không lặp tên dòng.
- **Dòng danh sách:** `ListRow` (› `RowChevron`, `trailingSubtitle` dưới số tiền, `compactAmount`) trong `listCard()`, ngăn bằng `RowDivider`. Tài khoản ở mọi danh sách là `AccountRow` + `RowDivider(column: .logo)`: logo/ô 32, tên `body`, số rút gọn. Khoản vay `LoanRow` cùng cột 32. Bấm dòng `.row`; bấm thẻ `.card`.
- **Logo & icon dòng:** `RowIcon` vẽ glyph hoặc logo ngân hàng/ví (`InstitutionLogo`) cùng một ô; logo không to hơn icon.
- **Chip:** `ChipRow` đổi bộ lọc (chip chọn `primary`); `TagChip` thường / gợi ý / có × / nổi: viên 36 nhìn thấy, nút 44 để chạm (HIG, 2026-10-31). Hàng chip chỉ cuộn ngang khi tràn (`NoScrollEdgeEffect`).
- **Badge (`StatusBadge`):** xem mục Màu; có biến thể icon.
- **Trạng thái trống (`EmptyStateCard`):** icon trơn 44 màu chữ, một câu ngắn, **không nút** (thêm mới đi qua nút + của trang).
- **Nút tháng (`MonthMenu`):** `Menu` native, viên phẳng `fill` cao 44; dạng gọn ở Lịch thu chi là `HeaderLink` ⌄. Năm khác ghi "Tháng 9/2025".
- **Thẻ tháng ở Thu chi:** một thẻ trắng ngay dưới segment: nút tháng (trái) + nút tròn phẳng biểu đồ mở Báo cáo (phải) cùng cao 44; dưới là `SplitTotals` Đã chi | Đã thu; dòng hạn mức (`BudgetStatusLine`) chỉ từ 80%.
- **Vay nợ:** thẻ đầu trang `SplitTotals` "Cho vay" | "Đi vay" (đi vay đỏ "-"), số người dưới mỗi cột.
- **Số tiền:** luôn `MoneyText` (cỡ `caption` / `row` / `heading` / `large` / `display`; tone `signedIncome` "+" mực, `signedExpense` "-" đỏ, `signedNet` theo dấu, `negativeRed`, `muted`), không tự viết `Text(x.vnd)`. Cảnh báo hạn mức một kiểu: `BudgetStatusLine`.
- **Tiến độ:** `ProgressBar` 8pt; `ProgressRing` (vòng hũ, Làm quen) nét 3.
- **Ô tìm tự vẽ (`SearchField`)** cho màn tìm toàn màn hình: capsule trắng viền mảnh.

## Form Thêm giao dịch

- (Người dùng chọn 2026-10-30) Số tiền to 52 (38 / 28 khi dài). Giao dịch mới chi/thu có **hàng hạng mục chọn nhanh** (`QuickCategoryGrid`) dưới số tiền: 8 hạng mục dùng nhiều nhất (đếm giao dịch, thiếu thì lấy theo thứ tự danh sách), 4 cột, nút tròn trắng 52 viền mảnh + tên trong cùng một nút; chọn thì nền mực chữ trắng, dòng "Hạng mục" bên dưới vẫn mở cả danh sách. Không hiện khi sửa hoặc "Mua ngay".
- Nhóm có tiêu đề như mọi form (người dùng 2026-10-31): **CHI TIẾT** (Hạng mục, Tài khoản, Thời gian — một dòng "Hôm nay, 17:12", `FormDateTimeRow`), **TUỲ CHỌN** ("Không tính vào báo cáo", chỉ chi/thu), **GHI CHÚ**.

## Tổng quan

- **Bố cục HIG, bề mặt đặc** (người dùng 2026-10-31, sau ba bản thử cùng ngày: "Mực đêm", "soft UI" card lồng card, thẻ kính): tiêu đề native "Tổng quan" `.inlineLarge` qua `TabHeading` như Tài khoản/Giao dịch; Q (vẽ thành `Image`) và chuông là nút trơn trong `ToolbarItem`, tách bằng `ToolbarSpacer`, thanh tự vẽ kính. Trang là các **section** cách nhau 28 (`Spacing.section`), mỗi section một `SectionHeader` (17 Bold, nút phải là chữ màu chính 14 `HeaderLink`) cách thẻ 8 (`headerGap`), và **một thẻ trắng** `card()` (bo 28, đệm 20, viền mảnh). **Không thẻ trong thẻ**: trong thẻ chỉ có chữ, số, đường kẻ mảnh `separator`, thanh, icon tròn tô nhạt.
- **Liquid Glass đúng chỗ HIG**: chỉ thanh trên (nút Q, chuông), tab bar và nút + cạnh tab bar. Nội dung cuộn không có kính: thẻ đặc, nút nhanh là vòng phẳng. Đã thử thẻ kính + nền màu mờ (`glassCard`, `GlassBackdrop`) rồi bỏ cùng ngày vì HIG dành kính cho lớp điều khiển; nội dung trên kính khó đọc và phải bịa nền để kính có gì khúc xạ.
- Thứ tự: thẻ chính → nút nhanh → "Tháng này" → "Chi nhiều nhất" → Làm quen → Cần chú ý (đang ẩn) → Lịch thu chi.
- **Thẻ chính** (`HeroCard`, trắng, đệm 24): "Tài sản ròng" xám + › phải, số `display` mực (đỏ nếu âm), "↑ 15,6tr từ cuối tháng 5" (`NetWorthGrowth`: xanh / đỏ ↓ / xám 0), đường tăng trưởng 6 tháng màu chính cao 48. Bấm cả thẻ mở **Tài sản ròng** (`NetWorthView`, không đổi). Tài sản ròng = số dư (gồm hũ) + cho vay − nợ; không tính tài khoản khoá. Lịch sử: giá trị cuối tháng = hiện tại trừ ngược thu/chi sau đó.
- **Nút nhanh** (`QuickActions`): 4 vòng trắng 56 viền mảnh (`cardOutline`, như nút tròn của mẫu Iconly; kính trước 2026-10-31, rồi tô `primaryTint` bị chê xám), icon màu chính, chữ 13 dưới, cả vòng lẫn chữ là một `Button` (`.card`): Ghi chi, Ghi thu, Chuyển tiền mở sheet thêm giao dịch đúng chế độ; Trợ lý AI trượt sang trang AI. Cỡ chữ trợ năng 2 cột.
- **Tháng này** (`MonthCard`, trắng; tiêu đề có "Báo cáo ›" mở `ReportRoute`): `SplitTotals` Đã thu / Đã chi (thu mực có "+", chi đỏ); kẻ ngang `SplitLine`; "Chi theo nhóm" + "Hạn mức 30tr" (nếu có); `SegmentedBar` 8pt mỗi nhóm hạng mục một đoạn theo `ChartShades` (4 nhóm lớn nhất), phần còn lại `chartRest`, phần trống = hạn mức còn lại (không hạn mức: thanh đầy); `LegendRow` chấm + tên. Chưa chi gì thì chỉ còn hai cột. Bấm thẻ mở Báo cáo.
- **Chi nhiều nhất** (`TopCategoriesCard`, trắng): 3 nhóm chi nhiều nhất tháng, mỗi nhóm icon 24 màu `ChartShades` trên vòng tròn 52 tô cùng màu 14%, tên `caption`, số rút gọn `captionStrong` xám. Không chi → ẩn cả section. Bấm thẻ mở Báo cáo.
- **Làm quen với Timi** (`OnboardingCard`, trắng): vòng màu chính 44 có "3/4", tên + bước kế tiếp xám, viên lime "+5 AI" (`StatusBadge .accent`), ›. Bấm làm bước đó; xong cả 4 thì ẩn; mỗi việc +5 lượt AI thật.
- **Cần chú ý:** đang ẩn (`showsAttention = false`, người dùng 2026-10-30).
- **Lịch thu chi**: `SectionHeader` + `MonthMenu` gọn (chữ màu chính 14) **ngoài thẻ** như mọi section (trang giữ `calendarMonth`), bên dưới `MoneyCalendarCard(displayedMonth:)` trong `card()`; lưới bắt đầu T2; ô ngày 44 chỉ số ngày + chấm mực nếu có tiền vào; màu ô theo mức chi đỏ 8/14/20%; hôm nay viền màu chính 1,5pt + số màu chính, không tô nền; ngày chưa tới mờ 40%, không bấm; chú thích nhỏ dưới lưới; chạm ngày mở sheet giao dịch trong ngày.
- **Timi Pro** không còn trên Tổng quan (banner bỏ 2026-10-31); mở từ Cài đặt.

## Tài khoản & Hũ

- Bố cục cố định (người dùng chọn "A + B" 2026-10-30; trial bố cục đã xoá 2026-10-31): thẻ tổng `BalanceCard`, tài khoản trong `listCard`, hũ là thẻ cuộn ngang (bo 28, đệm 20). Các phần cách nhau 28 như mọi tab.
- Tiêu đề "Tài khoản" native + nút + trên thanh.
- **Thẻ tổng** (`BalanceCard`): `TotalBalanceHeader` (nhãn, số to `display`, "↑ x trong tháng này" xanh lá / ↓ đỏ, ẩn khi 0; ổ khoá "Đã khoá …" khi có tài khoản khoá) + `SegmentedBar` kiểu thanh dung lượng iPhone chỉ chia tiền dương của tài khoản không khoá + hũ, 4 phần lớn nhất màu `ChartShades`, còn lại "Khác", `LegendRow` tên + %; tài khoản âm ghi riêng dòng đỏ "Âm 2tr ở …"; tổng ≤ 0 thì số đỏ, ẩn thanh; chỉ một nơi có tiền cũng ẩn thanh.
- **Tài khoản** (người dùng chọn 2026-10-30, "một khối trắng"; lưới 2 cột xấu khi số tài khoản lẻ): các dòng trong một khối trắng bo góc viền mảnh (`listCard`), dòng chuẩn của app (đệm 10, tối thiểu 52; người dùng 2026-10-30: 64 cao hơn dòng Hạng mục): logo/icon 32, tên, số dư rút gọn (đỏ khi âm, xám khi khoá), ›; kẻ mảnh từ sau logo. Bấm mở màn chi tiết. "Lưu trữ (n) ›" `HeaderLink` bên phải tiêu đề khi có tài khoản lưu trữ. (Đã thử: màu thương hiệu từng ngân hàng, dãy thẻ cuộn ngang, lưới 2 cột, dải rêu kiểu Tổng quan.) Duyệt HIG 2026-10-30: phần đầu tên "Ví & ngân hàng" (không lặp "Tài khoản" của tiêu đề trang); mọi icon trên cùng ô trắng viền mảnh như logo ngân hàng (`RowIcon(tiled: true)` trong `AccountRow`, ngoại lệ của quy tắc icon không nền, để cột trái thẳng hàng); hũ là dòng trong khối trắng giống tài khoản (`GoalRow`: vòng tiến độ 32 có icon, tên + hạn "6/11", "15tr / 50tr" + %), thay 2 thẻ to; cỡ chữ rất lớn thì số tiền xuống dưới tên. Tiêu đề trang trên thanh chỉ lớn thêm chút khi chữ to: giới hạn của iOS, không phải lỗi.
- Form tài khoản: Ngân hàng/Ví (bắt buộc với loại đó, `InstitutionPickerSheet`), Tên (bắt buộc, tự điền theo ngân hàng), Số dư âm, "Số dư tính từ" + Giờ, công tắc **Khoá tài khoản** (thay "Không tính vào báo cáo"; khoá thì không tính vào tổng và báo cáo, không có trong ô chọn), Ghi chú.
- Sửa số dư không ghi đè: chênh lệch thành giao dịch "Điều chỉnh số dư" (không tính báo cáo).
- Tài khoản đã có lịch sử chỉ **lưu trữ** được (ẩn khỏi danh sách, ô chọn, tổng; lịch sử giữ nguyên), có "Khôi phục"; chưa có lịch sử (hoặc chỉ có điều chỉnh số dư) thì xoá hẳn. Danh sách ở "Tài khoản đã lưu trữ".
- **Hũ tiết kiệm:** trên tab là thẻ cuộn ngang `GoalCarouselTile` (vòng 56) + ô "Hũ mới" viền đứt; trong danh sách khác (Tài sản ròng, Thư viện UI) là dòng `GoalRow` (vòng tiến độ 32 `ProgressRing`, tên `body`, "10tr / 40tr" `MoneyText` rút gọn, ›); vòng đỏ khi quá hạn, "Đủ" khi đạt.
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
- Bong bóng trợ lý nền trắng viền mảnh (`cardOutline`), bong bóng người dùng nền màu chính chữ trắng; avatar Timi là glyph xanh trơn. Ô nhập capsule, micro nhập giọng nói (`SFSpeechRecognizer` vi-VN), nút gửi tròn màu `primary`.
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
- Thẻ "Còn lại" có "Phân bổ ›" và mở **Phân bổ hạn mức**: thanh chia hạn mức tháng theo nhóm (`ChartShades` như Báo cáo); "Chưa phân bổ" là phần rãnh trống (`surfaceMuted`) với chấm rỗng viền xám; mỗi phần ghi đã chi / còn. Nhóm không có hạn mức riêng chi vào "Chưa phân bổ" và được liệt kê dưới đó. Mỗi nhóm mở trang chi tiết nhóm; ✎ sửa hạn mức tháng.
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
- Dark mode: token đã theo vai trò, còn thiếu bộ giá trị tối và bỏ `UIUserInterfaceStyle = Light`.
- Rung và hiệu ứng bấm cần thử lại trên máy thật; cỡ chữ trợ năng mới xem qua AX-large trên Simulator (2026-10-31), chưa duyệt đủ mọi màn ở AX5.
