# Kế hoạch: dọn theme cũ và chuẩn hoá Design System theo Apple HIG

> Viết 2026-10-31 sau khi rà toàn bộ `Timi/DesignSystem` (41 file, 3.655 dòng) và cách `Features/` dùng nó. **Đã thực hiện cùng ngày** theo 6 đề xuất ở mục 5 (bước 0–5, mỗi bước một commit; bước 6 dark mode để sau). Quy tắc hiện hành nằm ở `DESIGN_NOTES.md`, nhật ký ở `docs/design-history.md`; file này giữ lại làm lý do của các quyết định.

## 0. Hiện trạng

**Điểm tốt, giữ nguyên**

- `Features/` gần như không viết cứng màu hay số: không có `Color(red:)` nào ngoài `Palette`/`AccentTrial`; 55 chỗ số thô thì hầu hết là `spacing: 0` hay `.frame(height: 1)` cho kẻ mảnh.
- Thang chữ `TextRole` + Manrope co giãn theo Dynamic Type, 14 chỗ đã xử lý cỡ chữ trợ năng, 154 modifier accessibility trong `Features/`.
- `RowMetrics` làm mọi dòng (form, danh sách, sheet) thẳng hàng; `MoneyText` là nơi duy nhất vẽ tiền.
- Lớp điều khiển đã đúng HIG: tiêu đề native `TabHeading`, nút trong `ToolbarItem` trơn để thanh tự vẽ kính, sheet hệ thống với ✕/✓ `role: .close/.confirm`, tab bar + nút + `Tab(role: .search)`.

**Tàn dư theme cũ (rêu, Sleek, Mực đêm)**

| # | Tàn dư | Ở đâu |
|---|---|---|
| 1 | `AccentTrial`: 6 combo (Đơn sắc, Rêu & Kem, Xanh biển, Lục bảo, Chàm, Hổ phách) với `Neutrals`/`Hues`; 20 token `Palette` là `static var` đọc singleton `@Observable` mỗi lần vẽ | `Foundations/AccentTrial.swift`, `Palette.swift`, `ReportParts.swift` (`ChartShades`), `StorageKey.accentTrial`, `SettingsView` row "Màu (thử)" |
| 2 | Token đặt tên theo màu cũ, giờ không còn đúng: `lime` (giờ là đen), `sky` (xanh dương), `green` (= mực), `chartCoral`, `limeTile`, `incomeTile` (= `green` 12% = xám 12%, chính là mảng xám bạn không thích) | `Palette`, `TimiButton .accent`, `StatusBadge .accent/.positive`, `FoundationPart` |
| 3 | `AccentColor` trong Assets vẫn rêu #3E5B3F (hộp thoại hệ thống, tint mặc định) | `Assets.xcassets/AccentColor` |
| 4 | Trial bố cục Tài khoản `AccountsLayout` (Hiện tại / A / B / A+B) + row Cài đặt; bạn đã chọn A+B từ 2026-10-30 | `AccountsLayoutTrial.swift`, `AccountsView`, `StorageKey.accountsLayout`, `SettingsView` |
| 5 | Tên gọi cũ không còn tả đúng: `HeaderCapsuleLabel` / `headerCapsuleGlass()` (không capsule, không kính), `sleekCard()` (từ mẫu Sleek), `nativeGlassButton` (0 nơi gọi), `TextRole.hero` / `.input`, `ControlHeight.row` / `.floating`, `CardCorners.sheet` (chỉ UI Library liệt kê) | `NativeButtons.swift`, `CardSurface.swift`, `TextRole.swift`, `Metrics.swift` |
| 6 | Comment còn nhắc Sleek / web `finance-tracker-v2` / `examples/` HTML làm "mẫu nguồn" | 6 file DS, `DESIGN_NOTES` đoạn mở đầu |
| 7 | `DESIGN_NOTES.md` lệch code: mục "Giao diện" còn tả token `night*` (đã xoá), "Bớt card… các tab khác chưa đổi", đồ thị "rêu / bạc hà / vàng / san hô", dòng 11 Nguyên tắc chung vẫn ghi "Tổng quan dùng thẻ kính + 4 nút nhanh kính", nút Nổi bật "vàng", `title` lúc ghi 17 Bold lúc 17 SemiBold (code: `.bold`) | `DESIGN_NOTES.md` |
| 8 | Rác ở gốc repo: `build-accounts/`, `build-flows/`, `build-loans/`, `build-overview/`, `build-settings/` chưa ignore; `docs/design-trials/` chưa track; `examples/` HTML không còn là mẫu | `.gitignore`, gốc repo |

**Chỗ chưa hợp HIG hoặc chưa nhất quán**

| # | Vấn đề | Vì sao đáng sửa |
|---|---|---|
| A | Hai khoảng cách giữa các phần: 28 (`Spacing.section`, 19 nơi) và 36 (`flatSection`, chỉ `AccountsView`) | Hai trang tab cạnh nhau nhịp khác nhau |
| B | Thẻ hai cột "Đã chi \| Đã thu" tự dựng 4 lần (`TransactionsView`, `LoansContent`, `ReportView`, `MonthCard`), mỗi nơi lại `HStack(spacing: 0)` + `VerticalDivider` + padding tay | Notes đã ghi "Để sau"; sửa một chỗ không lan ra chỗ khác |
| C | `CardButtonStyle` tự `scaleEffect(0.98)` + spring | Trái quy tắc đã ghi: "Button giữ hiệu ứng của Apple, không tự thêm scale/animation" |
| D | `StatusBadge` `.positive` (mực 12%) và `.neutral` (mực 6%) nhìn như nhau trong Đơn sắc | Badge "Đã thu" không còn nghĩa |
| E | Chữ dưới nút nhanh và lưới hạng mục nhanh bắt chạm bằng `onTapGesture` ngoài `Button` (`QuickActions`, `QuickCategoryGrid`) | VoiceOver/Switch Control không thấy; HIG: mọi thứ chạm được là control |
| F | Thẻ trắng trên nền #FAFAFA chỉ tách bằng bóng mềm (2,5% + 4%) | Bạn đã thấy "thẻ bắt đầu tan"; HIG tách nhóm nội dung bằng nền hoặc viền, bóng dùng tiết chế |
| G | `TimiAmountField` cỡ 52 → 38 → 28 nằm ngoài thang `TextRole` (`hero` 40 không ai dùng); `MoneyText` `minHeight: 42.5` / `32` số lẻ | Một thang chữ duy nhất |
| H | Chưa xử lý Reduce Motion, Differentiate Without Color (chỉ 1 chỗ) | HIG Accessibility; tiền ra chỉ phân biệt bằng đỏ |
| I | Thành phần dùng chung nằm rải trong `Features/`: `FlowLayout` (Assistant), `ProgressRing` (trong `Avatars.swift`), `NetWorthChart`, `ActivityDayList`, `SplitLine` (Reports) | Khó tìm, dễ dựng trùng |
| J | Hai họ icon: Hugeicons (343 asset) cho nội dung, SF Symbols cho tab bar / ✕ / + | Chấp nhận được nếu ghi rõ ranh giới: SF cho control hệ thống, Hugeicons cho nội dung |
| K | Target thật là iOS 17.6 (target-level), 19 nhánh `#available(iOS 26/18)` chưa từng chạy thử trên iOS 17 | Nửa code không được kiểm; README cũng ghi 17.6 |
| L | Dark mode khoá cứng `UIUserInterfaceStyle = Light` | HIG mong app theo giao diện hệ thống; không bắt buộc nhưng là quyết định cần ghi |

## 1. Hệ thống đích

Ba nguyên tắc, lấy từ HIG iOS 26:

1. **Hai lớp.** Lớp điều khiển (thanh trên, tab bar, nút + nổi, ✕/✓ trong sheet) là Liquid Glass do iOS vẽ. Lớp nội dung là bề mặt đặc: nền trang, thẻ trắng, dòng. Không kính trong nội dung cuộn, không thẻ trong thẻ.
2. **Màu theo vai trò, không theo tên màu.** Mỗi token nói nó dùng để làm gì (`label`, `separator`, `positive`, `accent`), nên khi đổi bảng màu không phải đổi tên. Đơn sắc: chữ và hành động là mực #111 trên trắng; chỉ đỏ (tiền ra), cam (cảnh báo) và bốn màu dữ liệu nhỏ là có màu.
3. **Hệ thống trước, tự vẽ sau.** `NavigationStack`, `Tab`, `.sheet`, `Toggle`, `Menu`, `Picker(.segmented)`, Swift Charts, `.searchable`. Tự vẽ chỉ khi hệ thống không có (ô tiền lớn, lịch thu chi, badge).

## 2. Token mới

### Palette: `static let`, một bảng, không còn `AccentTrial`

| Nhóm | Token mới | Giá trị Đơn sắc | Thay cho |
|---|---|---|---|
| Nền | `background` | #FAFAFA | `background` |
| | `surface` | #FFFFFF | `card` |
| | `surfaceMuted` | #F3F3F4 | `muted` |
| | `separator` | #E8E8EA | `border` |
| | `inputBackground` | #F5F5F6 | `input` |
| Chữ | `label` | #111111 | `ink` |
| | `secondaryLabel` | #6E6E73 | `secondaryText` |
| | `tertiaryLabel` | #AEAEB2 | `secondary` (chevron, glyph mờ) |
| Hành động | `primary` | #111111 | `primary` |
| | `onPrimary` | #FFFFFF | `onPrimary` (bỏ nhánh `isLight`) |
| | `primaryTint` / `primaryTrack` / `primaryDash` / `rowPressed` | mực 10 / 12 / 35 / 10% | giữ |
| | `fill1` / `fill2` / `fill3` | mực 4 / 6 / 10% | giữ |
| Nghĩa | `negative` | #B5543F | `red` |
| | `onNegative` | #FFFFFF | `onRed` |
| | `warning` / `warningLabel` | #E8890C / #8A4B08 | `warning` / `warningText` |
| | `positive` | **quyết định Q3** | `green` |
| | `info` | #2F7CF6 | `sky` |
| Nhấn | `accent` / `onAccent` | #111111 / #FFFFFF | `lime` / `onLime` (badge PRO, "+5 AI", nút `.accent`) |
| Dữ liệu | `chart: [Color]` | #2F7CF6 · #F5A623 · #F5555D · #7C4DFF | `ChartShades.steps`, `chartCoral` |
| | `chartRest` | #D1D1D6 | `chartRest` |
| Bỏ | `income` (= `label`, dùng thẳng), `incomeTile`, `limeTile`, `controlTint` (= `primary`) | | |

Bảng rêu cũ chỉ còn trong `docs/design-history.md`, không còn trong code.

### Chữ: `TextRole` giữ thang, dọn ca không dùng

- Bỏ `.hero` (40) và `.input`; thêm `.amountEntry` cho ô tiền với ba mức 52 / 38 / 28 lấy từ enum, không viết trong `TimiAmountField`.
- `.title` ghi thống nhất là **17 Bold** (code đang `.bold`); sửa comment và notes.
- `MoneyText` bỏ `minHeight` 42.5 / 32: dùng `lineHeight` của role.

### Khoảng cách & bo góc

- Một khoảng cách giữa các phần: `Spacing.section` 28. Bỏ `flatSection` 36, `AccountsView` về 28.
- `ControlHeight`: bỏ `.row` (dùng `RowMetrics.minHeight`) và `.floating` (= `.large`).
- `CardCorners`: bỏ `.sheet` (sheet hệ thống giữ bo góc Apple, không ai gọi).

## 3. Thành phần: giữ, đổi tên, gộp, bỏ

**Giữ nguyên:** `FormGroup`, các `Form*Row`, `SheetScaffold`, `SheetHeader`, `SheetCloseButton`, `ChoiceSheet`, `OptionSheet`, `NoteSheet`, `IconPickerSheet`, `ListRow`, `RowIcon`, `InstitutionLogo`, `RowDivider`, `MoneyText`, `TagChip`, `ChipRow`, `ScaledSegmentedPicker`, `ProgressBar`, `BudgetStatusLine`, `EmptyStateCard`, `SectionHeader`, `SummaryCard`, `TimiButton`, `SearchField`, `TimiAmountField`, `Haptics`, `Keyboard`.

**Đổi tên cho đúng nghĩa**

| Cũ | Mới |
|---|---|
| `sleekCard(padding:radius:)` | `card(padding:radius:)` |
| `HeaderCapsuleLabel` | `HeaderLink` (chữ 14 màu chính + › / ⌄) |
| `headerCapsuleGlass()` | `headerLinkButton()` |
| `MonthMenu(compact: true)` | giữ, nhãn dùng `HeaderLink` |
| `AccountRowDivider` | dùng thẳng `RowDivider(column: .logo)` |

**Gộp thành thành phần mới trong `DesignSystem/Components/Data`**

- `SplitTotals`: hai (hoặc ba) cột "nhãn nhỏ + `MoneyText(.large)` + dòng phụ tuỳ chọn", kẻ dọc giữa, xếp dọc ở cỡ chữ trợ năng. Thay 4 bản tự dựng (B).
- `SegmentedBar`: thanh 8pt nhiều đoạn + `LegendRow` chấm màu. Dùng cho `BalanceCard` (Tài khoản), `MonthCard` (Tổng quan), Phân bổ hạn mức.
- `SplitLine` chuyển từ `ReportParts` vào `ListRow.swift` cạnh `VerticalDivider`.
- Dời `FlowLayout` (Assistant) và `ProgressRing` (tách khỏi `Avatars.swift`) vào DS.

**Sửa theo HIG**

- `CardButtonStyle`: chỉ mờ 0,6 khi nhấn như `.plain` của hệ thống, bỏ scale/spring (C).
- `QuickActions`, `QuickCategoryGrid`: nhãn nằm trong `Button` cùng vòng tròn, một control, một `accessibilityLabel` (E).
- `StatusBadge .positive`: nền `surface` + viền `separator` + chấm `positive`, không còn nền xám (D).
- Bề mặt thẻ (F): **quyết định Q2**.
- Reduce Motion: tắt animation lăn số / fade chip khi `accessibilityReduceMotion`; Differentiate Without Color: tiền ra đã có dấu "-", thêm ↑/↓ cho tăng trưởng (H).

**Bỏ hẳn**

- `AccentTrial` + `AccentTrialRow` + `StorageKey.accentTrial` + row Cài đặt; `Palette` về `static let`.
- `AccountsLayout` + `AccountsLayoutTrialRow` + `StorageKey.accountsLayout`; `AccountsView` cố định A+B (`BalanceCard` + hũ cuộn ngang).
- `nativeGlassButton`, `TextRole.hero/.input`, `ControlHeight.row/.floating`, `CardCorners.sheet`, `Palette.income/incomeTile/limeTile/controlTint`.
- Nếu Q4 chọn iOS 26: mọi nhánh `#available`, `HiddenToolbarTitle`, `heading` leading item ở 3 tab, `TabView` kiểu cũ trong `ContentView`, `.bordered*` fallback.

## 4. Lộ trình

Mỗi bước là một commit riêng, build xong thì xem trên Simulator ở cỡ chữ mặc định và AX3 trước khi sang bước sau. Thứ tự này để bước sau không phải sửa lại bước trước.

**Bước 0: chốt mốc.** Commit toàn bộ việc Tổng quan đang có (104 file đang sửa chưa commit) với message "Tổng quan chuẩn HIG, bảng Đơn sắc". Dọn trên nền sạch, lỡ hỏng thì có chỗ quay về.

**Bước 1: dọn theme cũ** (~1 buổi)

- `Palette` thành bảng tĩnh Đơn sắc; xoá `AccentTrial.swift`, row Cài đặt, `StorageKey.accentTrial`; `ChartShades` đọc `Palette.chart`.
- `AccentColor` → #111111.
- Xoá `AccountsLayoutTrial.swift`, `StorageKey.accountsLayout`; `AccountsView` cố định.
- Xoá helper/token không ai gọi (mục 5 ở trên).
- `.gitignore` thêm `build*/`; quyết định `examples/` và `docs/design-trials/` (Q6).
- Xong khi: build sạch, Cài đặt → Nhà phát triển chỉ còn Thư viện UI, Lịch sử phiên bản, Đặt lại dữ liệu mẫu; `grep AccentTrial` trả về 0.

**Bước 2: đổi tên token và thành phần** (~1 buổi, phần lớn là tìm-thay)

- Đổi tên theo bảng mục 2 và 3; `FoundationPart` (Thư viện UI) liệt kê theo tên mới, nhóm theo vai trò (Nền / Chữ / Hành động / Nghĩa / Nhấn / Dữ liệu).
- Xoá comment nhắc Sleek / web.
- Xong khi: `grep -E "Palette\.(ink|red|lime|sky|green|muted|border|card)\b"` trả về 0; Thư viện UI hiện đủ token.

**Bước 3: thành phần chuẩn HIG** (~1–2 buổi)

- Làm `SplitTotals`, `SegmentedBar` + `LegendRow`; thay ở Thu chi, Vay nợ, Báo cáo, `MonthCard`, `BalanceCard`, Phân bổ hạn mức.
- Sửa C, D, E, G, H; thống nhất `Spacing.section`; bề mặt thẻ theo Q2.
- Dời `FlowLayout`, `ProgressRing`, `SplitLine` vào DS.
- Xong khi: `VerticalDivider` chỉ còn trong `SplitTotals`; không còn `scaleEffect` trong DS; `onTapGesture` chỉ còn ở ô nhập (focus) và `keyboardDismissArea`.

**Bước 4: rà từng màn với hệ mới** (~1 buổi)

Checklist cho mỗi màn: tiêu đề native, section 28, `SectionHeader` lùi 16, một thẻ trắng mỗi section, không thẻ trong thẻ, màu chỉ ở tiền ra / cảnh báo / dữ liệu, chạm ≥ 44, AX3 không cắt chữ. Màn: Tổng quan, Tài sản ròng, Tài khoản, Chi tiết tài khoản, Hũ, Thu chi, Vay nợ, Tìm kiếm, Báo cáo, Hạn mức, Cài đặt, Trợ lý AI, Thư viện UI.

**Bước 5: tài liệu**

- Viết lại `DESIGN_NOTES.md` phần "Nguyên tắc chung", "Giao diện", "Màu", "Bo góc & khoảng cách", "Thành phần" theo hệ mới, ngắn hơn, chỉ quy tắc hiện hành; sửa dòng 11 (thẻ kính) và những chỗ ở mục 7.
- Một mục ngày trong `docs/design-history.md` ghi lý do bỏ rêu, bảng cũ, và các quyết định Q1–Q6.
- README: target đúng theo Q4.

**Bước 6 (tuỳ chọn, sau):** dark mode. Với token theo vai trò thì là thêm một bộ giá trị trong `Palette` qua `Color(light:dark:)` và bỏ `UIUserInterfaceStyle = Light`; không phải chạm `Features/`.

## 5. Quyết định cần bạn chốt trước bước 1

| # | Câu hỏi | Mình đề xuất |
|---|---|---|
| Q1 | Chốt Đơn sắc là theme duy nhất, xoá rêu và 4 combo khác khỏi code? | **Có.** Bảng rêu lưu trong design-history là đủ; code gọn và `Palette` không còn đọc singleton mỗi lần vẽ. |
| Q2 | Thẻ trắng tách khỏi nền #FAFAFA bằng gì: (a) bóng mềm như hiện tại, (b) viền mảnh 1pt `separator` không bóng, (c) nền trang về xám hệ thống #F2F2F7 và thẻ trắng không bóng không viền (kiểu Settings của iOS)? | **(b) viền mảnh, không bóng.** Phẳng đúng HIG, giống mẫu Iconly, giữ được nền gần trắng bạn vừa chọn. (c) chuẩn Apple nhất nhưng quay lại xám. |
| Q3 | `positive` (tăng trưởng, hạn mức còn xa, đã tất toán, badge "Đã thu") là mực như hiện tại, hay một xanh lá nhỏ chỉ cho chấm / mũi tên / chữ 13, không bao giờ làm nền? | **Xanh lá nhỏ, ví dụ #1E9E5A**, cùng luật "màu tươi nhỏ" của bốn màu dữ liệu. Toàn mực thì "+2,3tr" tăng và "Đã thu" không khác chữ thường. |
| Q4 | iOS tối thiểu: giữ 17.6 (và phải test 19 nhánh fallback trên iOS 17) hay nâng lên 26 (xoá hết fallback, chỉ còn một đường)? | **Nâng lên 26** nếu bạn chưa định phát hành rộng trong vài tháng tới; toàn bộ thiết kế đã dựa trên Liquid Glass và `Tab(role: .search)`. Nếu cần máy cũ, 18 là mức giữa (giữ `Tab`, bỏ nhánh 17). |
| Q5 | Dark mode: để sau (bước 6) hay làm ngay? | **Để sau**, nhưng đặt tên token theo vai trò ngay từ bước 2 để lúc làm chỉ sửa một file. |
| Q6 | `examples/` (HTML Sleek) và `docs/design-trials/`: xoá khỏi repo hay giữ? | **Xoá `examples/`** (git history còn), **commit `docs/design-trials/`** vì là bản thử có ngày của chính app. |

## 6. Đối chiếu HIG sau khi dọn (duyệt khó tính 2026-10-31)

| Mục | Hiện tại | So với HIG | Kết luận |
|---|---|---|---|
| Bo góc thẻ | 28 (thẻ đệm 20), 24 (khối dòng, form), 20 (ô trong thẻ chat), 12 ô nhập, `.continuous` | Nhóm danh sách iOS 26 ≈ 26; góc đồng tâm = góc ngoài − lề | Đạt. Ô chat 20 trong bong bóng 24 lề 16 chưa đồng tâm (8), chỉ ở Trợ lý AI, chấp nhận. |
| Chiều cao | dòng 52 (phụ đề ~62), nút 36/44/56, ô nhập 44, chip 36 hình / 44 chạm, badge 24 (không chạm), ô lịch 44, thanh 8 | Chạm ≥ 44 × 44 | Đạt sau khi chip có vùng chạm 44. |
| Khoảng cách | lề 20, phần 28, tiêu đề → thẻ 8, đệm thẻ 20/24 | Grouped list: lề 16–20, giữa nhóm ~35 | Đạt; 28 gọn hơn Apple một chút, nhất quán toàn app. |
| Chữ | Manrope, body 16 SemiBold, title 17 Bold, co theo Dynamic Type, line box `.exact` | SF Pro, Body 17 Regular, Headline 17 SemiBold | Khác biệt lớn nhất với Apple là **mọi chữ SemiBold**; là lựa chọn thương hiệu, không lỗi. Dynamic Type đạt. |
| Màu chữ | label 18,9:1, secondaryLabel 4,9:1, tertiaryLabel 2,2:1 (chỉ chevron) | Chữ ≥ 4,5:1 | Đạt. |
| Màu nghĩa | negative 4,9:1; positive 5,0:1; warning 2,6:1 chỉ thanh, chữ dùng warningLabel 5,7:1 | Đồ hoạ mang nghĩa ≥ 3:1 | Đạt sau khi sửa positive. Đỏ #B5543F hơi ấm trên nền trung tính, có thể lạnh hơn (#C4453A) nếu muốn; chưa đổi. |
| Màu dữ liệu | chart 3,9 / 3,2 / 3,3 / 4,8:1; Khác 3,3:1 | ≥ 3:1 | Đạt sau khi sửa cam và Khác. |
| Phối màu | đen trắng + đỏ/cam/xanh lá nhỏ + 4 màu đồ thị | Một màu nhấn, màu theo nghĩa | Tốt; 3 thứ cùng đen (tab chọn, nút chính, badge Pro) là chủ ý của Đơn sắc. |
| Sheet form | `.sheet` + `NavigationStack` + toolbar ✕/✓ `role: .close/.confirm`, `.large`, nền `background` | Native | Đạt. |
| Sheet ngắn | `timiFittedSheet`: đo chiều cao nội dung → `.height()`; thanh trên tự vẽ (`SheetHeader`: ✕/✓ kính tròn) | Apple dùng detent `.medium`/`.height` và toolbar thật | Hành vi (vuốt đóng, mờ nền, bo góc) native; thanh trên là tự vẽ nhưng dùng đúng nút kính hệ thống. Nếu muốn thuần native: bọc `NavigationStack` + toolbar, giữ `.height`. |
| Sheet khác | Lịch ngày/giờ `timiFittedSheet`; chọn tháng `.height(320)` cứng; Lọc, Ngày, Nợ `.medium/.large` có grabber | Grabber khi đổi được cỡ | Đạt; 320 cứng chỉ hợp bánh xe cỡ mặc định. |
| Tìm kiếm | `fullScreenCover` với ô tìm tự vẽ | HIG ưu tiên `.searchable` trên thanh | Lựa chọn của người dùng 2026-10-29; giữ. |
| Thanh trên / tab | Tiêu đề native `.inlineLarge`, nút trơn trong `ToolbarItem`, tab bar + nút tìm-role | Liquid Glass lớp điều khiển | Đạt. |
| Nhấn | Nút hệ thống kính; nút tự vẽ mờ 0,6; dòng `rowPressed` | Giữ hiệu ứng Apple | Đạt (đã bỏ scale). |
| Trợ năng | VoiceOver label, Reduce Motion, ↑/↓ và dấu −, cột xếp dọc ở AX | | Đạt ở mức đã xem; chưa duyệt đủ AX5 mọi màn. |
