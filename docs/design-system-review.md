# Rà soát Design System Timi — 2026-10-31

> Hai lượt đọc độc lập (mình và một agent đọc riêng, không biết kết luận của nhau), gộp lại sau khi kiểm chứng từng điểm trên code. Phần nào chưa chạy thử trên máy thì ghi "cần thử". Dấu ★ là nên làm trước.

## Tổng quan

Nền tảng đã vững: 23 token màu đều có nơi gọi, không còn màu hay số viết cứng trong `Features/`, lớp kính đúng chỗ (hai nút `.glass` duy nhất là nút gửi chat cố định và nút đóng màn tìm), mọi icon đều có asset. Cái còn yếu nằm ở ba chỗ: **trợ năng ở cỡ chữ lớn** (icon và vạch kẻ trong form chưa co, nhãn ô nhập chưa đọc được), **lặp** (bốn kiểu dòng danh sách, bảy bản sao của mẹo xếp dọc ở cỡ trợ năng, ba vòng tròn chọn tự vẽ), và **API chưa đồng bộ** (cùng một thứ lúc gọi `title` lúc `label` lúc `text`, thứ tự tham số khác nhau giữa các picker).

## 1. Trợ năng và HIG (★ sửa trước)

| # | Phát hiện | Ở đâu | Sửa |
|---|---|---|---|
| 1 ★ | Badge "Quá hạn": chữ đỏ trên nền đỏ 10% chỉ **4,28:1**, dưới 4,5 cho chữ 13 | `StatusBadge` `.warning` | Chữ đậm hơn (#9E4030) hoặc nền trắng viền mảnh như "Đã thu" |
| 2 ★ | `Palette.warning` #E8890C **2,62:1** trên trắng nhưng dùng làm **thanh hạn mức và chấm** (đồ hoạ mang nghĩa cần 3:1); cam đồ thị đã sửa mà cam cảnh báo thì chưa | `Palette`, `ProgressBar.budgetColor`, `BadgeTone.caution` | `warning` → #D97706 (3,19:1), chữ vẫn `warningLabel` |
| 3 ★ | Icon dòng form (`FormRowIcon`, `RowIcon` trong `FormActionRow`/`FormDestructiveRow`/`PickerRowLabel`) **không co theo Dynamic Type**; `FormDivider` lùi cố định 54 — đúng lỗi `RowDivider` đã sửa cho danh sách. Form và danh sách lệch nhau ở chữ lớn | `FormGroup.swift`, `RowIcon.swift` | `RowIcon` và `FormRowIcon` tự `@ScaledMetric` bên trong; `FormDivider` lấy cùng lùi co giãn như `RowDivider`; bỏ `RowMetrics.dividerInset` |
| 4 ★ | Mỗi nơi gọi `RowIcon`/`InitialsAvatar` tự khai `@ScaledMetric` (~15 chỗ); quên là lỗi câm. `EmptyStateCard`, `SummaryCard` truyền 44 cố định, không co | nhiều file | Co bên trong thành phần, `size` là cỡ gốc |
| 5 ★ | `FormTextRow`/`FormAmountRow`: `TextField` là phần tử riêng nên VoiceOver đọc placeholder ("Ghi chú", "0") chứ không đọc nhãn "Tên", "Số dư"; nhãn `.fixedSize()` nên chữ lớn không xuống dòng, ép ô nhập | `FormTextRows.swift` | `.accessibilityLabel(title)` cho ô; ở cỡ trợ năng xếp nhãn trên ô |
| 6 | `MoneyText` không có nhãn VoiceOver: "10,3tr", "1,2tỷ", "đ" bị đọc nguyên chữ | `MoneyText.swift` | `accessibilityLabel` dạng đầy đủ "10 triệu 300 nghìn đồng" (chip ô tiền đã làm vậy) |
| 7 | `TimiButton(.small)` cao 36, vùng chạm 36 (chip đã lên 44, nút nhỏ thì chưa); `.small` không có nơi gọi thật | `TimiButton.swift` | Bỏ `.small`, hoặc vùng chạm 44 như chip |
| 8 | Nút xoá chữ trong `SearchField` rộng 28, màu `tertiaryLabel` 2,2:1 | `SearchField.swift` | Rộng 44, màu `secondaryLabel` |
| 9 | `FlatButtonStyle` và `FormGroup` (lỗi hiện), `IconQuickPicker` còn animation **không tôn trọng Reduce Motion** dù ghi chú nói đã có | `NativeButtons.swift:95`, `FormGroup.swift:29,46`, `IconQuickPicker.swift:39` | Một helper nhấn-mờ đọc `accessibilityReduceMotion`, dùng chung |
| 10 | `GlassEffectContainer` vẫn bọc chip phẳng trong ô tiền; comment còn nói "one glass layer" | `TimiAmountField.swift:162` | Bỏ |
| 11 | `StatusBadge` `lineLimit(1)` + `fixedSize(horizontal: true)`: chữ dài ("Quá hạn · 45%") tràn màn ở cỡ lớn | `StatusBadge.swift:77` | Bỏ `fixedSize`, cho 2 dòng ở cỡ trợ năng |
| 12 | Font tiêu đề lớn và phụ đề thanh được scale **một lần lúc khởi động** (`UIFontMetrics.scaledFont`), đổi cỡ chữ giữa chừng không theo (cần thử) | `Typography.configureNativeAppearance` | Chạy lại khi nhận thông báo đổi cỡ chữ |
| 13 | `Haptics.selection()` trong `IconQuickPicker` dù chính `Haptics` nói việc ở lại màn dùng `.sensoryFeedback` | `IconQuickPicker.swift:28` | `.sensoryFeedback(.selection, trigger:)` |
| 14 | `FormPickerRow`, dòng ngày thêm `.accessibilityValue` lên nút mà nhãn đã chứa giá trị → có thể đọc hai lần (cần thử) | `FormRows.swift:22`, `FormDateTimeRows.swift` | Ẩn giá trị bên trong hoặc bỏ `accessibilityValue` |
| 15 | Ô tiền: số vẽ và dấu nằm cạnh `TextField` trong suốt có nhãn → có thể đọc hai lần (cần thử); dấu trừ U+2212 trong ô, ASCII "-" ở `MoneyText` | `TimiAmountField.swift` | `accessibilityHidden` cho phần vẽ; một dấu trừ |
| 16 | Màn tìm (`fullScreenCover`) tự vẽ nút đóng kính ngoài toolbar (nơi gọi duy nhất của `nativeCircleButton`) | `TransactionSearchView.swift:90` | `NavigationStack` + toolbar, hoặc `.searchable` |

## 2. Lặp và cấu trúc

| # | Phát hiện | Sửa |
|---|---|---|
| 17 ★ | **Bốn kiểu dòng**: `ListRow` (DS), `AccountRow`, `LoanRow`, `GoalRow` (Features) cùng dựng lại HStack 14, chevron, khung dòng. `ListRow` lại **không xếp dọc ở cỡ trợ năng** trong khi ba dòng kia có → giao dịch và tài khoản cư xử khác nhau ở chữ lớn. `ListRow.isLocked`/`compactAmount` gần như không ai gọi; `AccountRow.dividerInset` chết; ổ khoá lệch `offset(5,5)` một nơi, `LockBadge.size/3` nơi kia | `ListRow` nhận slot `leading:` (logo, avatar, vòng) và xếp dọc ở AX; ba dòng kia dựng trên nó; xoá tham số chết |
| 18 ★ | Mẹo `AnyLayout(VStackLayout…)` xếp dọc ở cỡ trợ năng chép ở **7 file** | Một `AdaptiveStack` trong DS |
| 19 | `DetailScaffold` (sheet xem giao dịch) nằm trong `Features/Transactions`, lặp cuộn/đệm/tiêu đề của `SheetScaffold` | Chuyển vào DS hoặc `SheetScaffold` nhận nút phải (bút chì) |
| 20 | "Mọi sheet đi qua `SheetScaffold`" chưa đúng: `IconPickerSheet`, `ContactPickerSheet`, `InstitutionPickerSheet`, `SettingsView`, `ContactsView` tự dựng `NavigationStack` + `SheetCloseButton` | Đưa về scaffold (thêm biến thể có `.searchable`) hoặc sửa câu trong ghi chú |
| 21 | `SheetScaffold` không tự ẩn chỉ báo cuộn; 22 nơi phải nhớ `.timiSheetStyle()`, còn 5 sheet `fitsContent` thì **không có** nên có thể lộ thanh cuộn | Ẩn chỉ báo và đặt nền ngay trong scaffold, caller chỉ truyền detent |
| 22 | `focusesOnAppear` + `Task.sleep(450ms)` chép 4 lần | Một modifier `.focusOnAppear()` |
| 23 | `NoScrollEdgeEffect` giờ chỉ là vỏ bọc luôn bật (6 nơi gọi) | Gọi thẳng `.scrollEdgeEffectHidden`, xoá modifier |
| 24 | `FormDateRow` và `FormDateTimeRow` tự dựng lại "Hôm nay / Hôm qua / dd/MM/yyyy" dù `Date.shortDay` và helper đã có; `FormDateTimeRow` thiếu `icon`, `earliest`, `isInvalid` mà `FormDateRow` có | Dùng chung formatter, đồng bộ tham số |
| 25 | `NavigationRowLabel` và `FormNavigationRow` gần như một; `FormActionRow` và `FormDestructiveRow` lặp phần alert "Huỷ/OK" | Một dòng có `role`, một helper alert |
| 26 | Ba vòng tròn chọn tự vẽ (`IconChoiceLabel`, `QuickCategoryGrid.cell`, `QuickActions.action`); `MonthMenu.FilledCapsule` và `MessageRow.cardButton` dựng lại `TimiButton`; `FilledCapsule` và `IconChoice` dùng `.buttonStyle(.plain)` nên **không mờ khi nhấn** | `FlatButtonStyle` có biến thể viền mảnh, một `CircleChoice`; `MonthMenu` dùng `flatCapsuleButton` |
| 27 | `InstitutionLogo` và `RowIcon(tiled:)` vẽ cùng một ô với số 0,28 / 0,5 lặp; viền ô 0,5pt còn viền thẻ 1pt | Một `LogoTile`, hằng số có tên |
| 28 | Bốn vạch kẻ (`FormDivider`, `RowDivider`, `SplitLine`, `VerticalDivider`) mỗi cái viết cứng `1`; `ChoiceSheet`/`OptionSheet` kẻ bằng overlay còn `FormGroup` thì đặt `FormDivider` giữa dòng | `Hairline.width`; một cách kẻ |
| 29 | `ChipRow` và ô tiền tràn mép bằng `-Spacing.page`, vỡ nếu đặt trong lề khác; mẫu "cuộn khi tràn" chép 2 lần | Một `BleedingScroll` nhận lề |
| 30 | `IconCatalog` (311 icon, tên tiếng Việt) là nội dung app, không phải nền tảng | Chuyển ra `Features/Shared` hoặc `Resources` |

## 3. Token, số thô, trùng lặp

| # | Phát hiện | Sửa |
|---|---|---|
| 31 ★ | `TextRole.label` **trùng hoàn toàn** `.body` (cỡ, đậm, line box, text style), 6 nơi gọi | Xoá `.label` |
| 32 | Trùng giá trị: `rowPressed` = `primaryTint` (mực 10%); `ControlHeight.field` = `.regular`; `Spacing.xl` = `page` = `card` (20), `Spacing.xxl` = `leadCard` (24); thang thô `xl/xxxl` còn dùng 8 chỗ trong Features | Bỏ `field`, `xxxl`; cân nhắc gộp `rowPressed` |
| 33 | Số thô trong DS: `FormErrorText` icon 16, `SearchField` icon 18, ô tiền `minHeight: 56` (= `ControlHeight.large`), `StatusBadge` 24/10/6/6/14, `LockBadge` 15/9/1,5, `SelectionCheck` 20, `Typography` 17/14/10, dim 0,6 và đỏ 14% chưa là token | Đặt tên hoặc trỏ về token có sẵn |
| 34 | `TimiButton` tự gọi `Typography.font(.headline, size:…)` thay vì `textRole` (14 = `accessory`, 16 = `body`) | `.textRole(size == .small ? .accessory : .body)` |
| 35 | `FormGroup`: `.padding(.bottom, headerGap - s)` = 0, phép tính chết | Bỏ |
| 36 | `ProgressBar.budgetColor` viết `0.8` còn `BudgetStatusLine` lấy ngưỡng từ `BudgetProgress` → hai nguồn sự thật | Một ngưỡng |
| 37 | `TagChip` dùng `RowMetrics.chevron` cho glyph chip | Token riêng |

## 4. API chưa đồng bộ

| # | Phát hiện | Sửa |
|---|---|---|
| 38 ★ | Cùng một thứ nhiều tên: chữ hiện là `title` (TagChip, EmptyStateCard, HeaderLink, Form*), `text` (StatusBadge, FormErrorText), `label` (SummaryCard), `caption` (SheetAmountHeader); closure tên lựa chọn là `title` (ChipRow) hoặc `label` (ScaledSegmentedPicker, FormPickerRow, ChoiceSheet); `TimiAmountField.label` là tên VoiceOver còn `AmountPreset.label` là chữ hiện. Thứ tự tham số của 4 picker khác nhau | Quy ước: `title` cho chữ hiện, `accessibilityLabel` cho VoiceOver, thứ tự `(selection, options, title closure)` |
| 39 ★ | Mặc định `MoneyText.Tone` lệch: `MoneyText` và `SplitTotals` là `.plain` (số âm vẫn đen, trái quy tắc "tiền ra luôn đỏ"), `ListRow` và `SummaryCard` là `.negativeRed`; `.negativeRed` đặt tên theo màu | Mặc định `.negativeRed` mọi nơi, đổi tên case theo vai trò |
| 40 | `TagChip` ba cờ bool (`isProminent`, `isSuggestion`, `onRemove`) | `enum Style` |
| 41 | `…Label` nhưng là cả dòng (`FormValueLabel`, `NavigationRowLabel` có `formRowFrame`) trong khi `FormRowLabel`, `PickerRowLabel` là một phần; `FormValueLabel.icon` không có mặc định | Đổi tên `…Row`/`…Content`, `icon: nil` |
| 42 | `NavigationRowLabel`, `PickerRowLabel` bắt caller nhớ `.buttonStyle(.row)` | Bọc sẵn trong một `FormButtonRow` |
| 43 | `cardSurface(outlined: false)` là mặc định dù mọi thẻ đều viền; thứ tự tham số khác `card()` | Mặc định `true` |
| 44 | Tiền tố lẫn lộn: 4 kiểu `Timi…` trên ~90; `dismissesKeyboardOnTap()` thực ra là kéo; 5 màn gọi thẳng `scrollDismissesKeyboard` | Thống nhất, đổi tên |
| 45 | `BadgeTone` lẫn vai trò và nhãn nghiệp vụ (`.positive` tên "Đã thu", `.pro` dùng cho "+5 AI") | Tên theo hình, nhãn tiếng Việt để ở Thư viện UI |
| 46 | Tham số chết: `HeaderLink.color`, `MonthMenu.tint`, `ProgressRing.track`, `SheetOption.accent`, nhánh chỉ-giờ của `DateTimeSheet`, `TimiButtonRole.destructiveSolid`, `TimiButtonSize.small/.large` (chỉ Thư viện UI gọi), `Typography.body`, `CardCorners.icon` | Xoá |

## 5. Code dễ vỡ

| # | Phát hiện | Sửa |
|---|---|---|
| 47 ★ | `SheetScaffold` ghi `contentHeight`/`barHeight` vào `@State` ở mọi lần layout kể cả khi không `fitsContent` → body dựng lại theo từng phím gõ; detent đầu 300+44 rồi mới nhảy về đúng | Chỉ đo khi `fitsContent`, bắt đầu từ `nil` |
| 48 | `hasConfirmed` không bao giờ reset: nếu `onConfirm` không đóng sheet thì ✓ chết | `onConfirm` trả `Bool` hoặc reset |
| 49 | `SheetOption.id = UUID()` đổi mỗi lần dựng → `ForEach` mất danh tính | `id` do caller cấp |
| 50 | `fixedSize()` trên số tiền (`ListRow`, `FormAmountInfoRow`, `AccountRow`) vô hiệu `minimumScaleFactor` của `MoneyText`, số dài đẩy tên ra ngoài ở chữ lớn | `layoutPriority` hoặc đổi bố cục |
| 51 | `SegmentedBar`: phần 0đ vẫn vẽ 2pt; nhiều phần nhỏ cộng tối thiểu có thể vượt bề rộng; chú thích không có số nên cặp màu–tên dựa vào thứ tự | Lọc phần 0, chú thích kèm % |
| 52 | `HeaderLink`: `-10` âm trong `headerLinkButton` giả định dòng cao 24; chữ lớn thì vùng chạm lấn hàng kế | Lấy từ line height đã co |
| 53 | `GeometryReader` ở `ProgressBar`/`SegmentedBar` thay được bằng `Layout`; `FlowLayout` đo mỗi con hai lần, không cache, một `spacing` cho hai trục | Tối ưu khi rảnh |
| 54 | `ScaledSegmentedPicker` đổi `UISegmentedControl.appearance()` ngay trong `body` | Giữ làm ngoại lệ duy nhất, ghi rõ |

## 6. Tài liệu lệch code

`fill2` (DESIGN_NOTES dòng 10, 46; `ButtonsPart`), `StatusBadge .accent` → `.pro`, "vòng xanh" của `IconQuickPicker`, `CardCorners.field` "ô nhập 44" nhưng chỉ `AttentionCard` dùng; comment "17 SemiBold" ở `TextRole`/`SectionHeader`, "amount 16 Bold" ở `ListRow`, "40pt figure" và "web CurrencyInput" ở `TimiAmountField`, `FormTimeRow` không tồn tại, doc "multi-line note" đặt nhầm lên `FormNoteText`, alert "Huỷ" nhưng code "OK", `Metrics` "bội 4" nhưng `xxs = 2`, `SearchField` có nút xoá chữ trong khi ghi chú nói "không nút xoá nhanh trong ô".

## Tiến độ

- **Đợt 1 làm 2026-10-31:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13 và `FormValueLabel` xếp dọc (`AdaptiveStack` mới, mục 18 làm một phần). Còn 12, 14, 15, 16 cần thử VoiceOver trên máy.

## Đề xuất thứ tự làm

1. **Trợ năng (1–5, 9, 10, 11):** một buổi, không đổi API, sửa xong là app đúng ở chữ lớn và đạt tương phản.
2. **Một dòng danh sách (17, 18, 50):** một buổi, xoá được ba bản dựng lại và bảy bản sao xếp dọc.
3. **API và tên (31, 38, 39, 41, 43, 46):** nửa buổi tìm-thay, nên làm trước khi viết thêm màn mới.
4. **Sheet (19, 20, 21, 47, 48):** nửa buổi.
5. Phần còn lại dọn dần khi chạm vào file đó; tài liệu sửa cùng từng đợt.
