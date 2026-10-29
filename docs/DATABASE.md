# Cơ sở dữ liệu Timi

Timi lưu dữ liệu trên máy bằng **SwiftData** (Apple, iOS 17+). Schema ở đây là **chuẩn gốc** cho mọi bản Timi: bản web sau này chuyển sang theo, rồi hai bên đồng bộ.

Code nằm ở `Timi/Persistence/`:

| File | Vai trò |
|---|---|
| `TimiSchemaV1.swift` | Định nghĩa 5 bảng (phiên bản 1) |
| `TimiSchemaV2.swift` … `TimiSchemaV6.swift` | Các bảng đổi ở V2 (hạng mục có nhóm), V3 (danh bạ, khoản vay nối với người), V4 (loại mối quan hệ tự thêm), V5 (đánh dấu người app tự tạo), V6 (khoản vay có sẵn hay mới, tài khoản, ngày, lãi suất) và kế hoạch chuyển phiên bản |
| `RecordMapping.swift` | Đổi qua lại giữa dòng trong database và kiểu dữ liệu các màn dùng |
| `FinanceDatabase.swift` | Đọc, ghi, nạp dữ liệu mẫu, đặt lại; mọi code SwiftData chỉ ở đây |

`FinanceStore` vẫn là nơi các màn đọc dữ liệu. Mở app thì nó nạp từ database. Mỗi lần thêm, sửa hoặc xoá, nó ghi ngay xuống database (write-through). Lần mở app đầu tiên, database trống nên được nạp dữ liệu mẫu. Cài đặt → Nhà phát triển → **Đặt lại dữ liệu mẫu** để làm lại từ đầu.

## Quy tắc chung

1. **`id` là UUID tạo trên máy.** Nhờ vậy tạo bản ghi được khi không có mạng; lúc đồng bộ không trùng id. Postgres dùng `uuid`.
2. **Tiền là số nguyên (`Int64`), đơn vị đồng.** VND không có số lẻ, và số nguyên cộng dồn không bị sai số như `Double`. Postgres dùng `bigint`, giống bản web hiện tại.
3. **Liên kết bằng id, không dùng relationship của SwiftData.** Ví dụ giao dịch giữ `accountID`, giống khoá ngoại trong SQL, nên chuyển sang Postgres là ánh xạ 1:1.
4. **Kiểu liệt kê lưu dạng chuỗi** (`"expense"`, `"bank"`, `"lent"`…), không lưu enum của Swift. Web và backend đọc được ngay.
5. **Mọi bảng có `createdAt` và `updatedAt`.** Đồng bộ sau này dựa vào `updatedAt` để biết dòng nào đã đổi.
6. **Không xoá cứng tài khoản đang có lịch sử**: tài khoản đã có giao dịch hoặc nạp/rút hũ chỉ được "Lưu trữ" (`archivedAt` = ngày lưu trữ), giữ nguyên số dư và lịch sử; app đọc cả tài khoản đã lưu trữ và hiện chúng ở "Tài khoản đã lưu trữ", không tính vào tổng, không có trong ô chọn. Khôi phục thì xoá `archivedAt`. Chỉ tài khoản chưa có lịch sử mới bị xoá hẳn. Hũ thì vẫn xoá hẳn được (tiền còn lại rút về tài khoản trước), các dòng nạp/rút cũ của hũ được giữ.
7. **Đổi schema = thêm phiên bản mới** (`TimiSchemaV2` + một bước trong `TimiMigrationPlan`), không sửa V1. Nếu sửa V1, máy đã cài app sẽ không mở được dữ liệu cũ.

## Icon

Cột icon (`goalIcon`, `CategoryRecord.icon`, `avatarValue` khi là icon) lưu **tên icon trong `IconCatalog`**: "hugeicons-" + mã của bộ Hugeicons, ví dụ "hugeicons-car-01". Bản web vẽ cùng icon bằng `hugeicons:car-01` (Iconify hoặc gói `@hugeicons/core-free-icons`). Máy đã cài bản cũ có thể còn tên Solar/MDI ("mdi-piggy-bank", "solar-calendar-linear"); `IconCatalog.migrated` đổi sang tên mới khi đọc. Bản web khi đồng bộ cần cùng bảng đổi tên này.

## Các bảng (V1)

### `AccountRecord` — tài khoản và hũ tiết kiệm

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | UUID | |
| name | String | "Vietcombank" |
| type | String | `cash` · `bank` · `eWallet` · `credit` · `savings` |
| institutionID | String? | id ngân hàng/ví trong `Institution` ("vietcombank", "momo"); nil với tiền mặt và hũ |
| detail | String | dòng phụ "•••• 4821" |
| openingBalance | Int64 | số dư lúc thêm tài khoản |
| balance | Int64 | số dư hiện tại; thẻ tín dụng mang số âm |
| creditLimit, paymentDueDate | Int64?, Date? | chỉ thẻ tín dụng |
| goalTarget, goalIcon, goalDueDate | Int64?, String?, Date? | chỉ hũ (`type = savings`); `goalIcon` là tên icon ("hugeicons-piggy-bank") |
| excluded | Bool | "Khoá tài khoản": không tính vào tổng số dư, giao dịch của nó không tính vào báo cáo (thu chi, lịch, biểu đồ, trợ lý); không chọn được khi ghi giao dịch hay nạp/rút hũ (app gọi là `isLocked`). Mở khoá là tính lại |
| archivedAt | Date? | đã lưu trữ |
| sortOrder | Int | thứ tự hiển thị |
| createdAt, updatedAt | Date | |

Hũ tiết kiệm là một loại tài khoản, giống bản web. Như vậy sau này "bỏ tiền vào hũ" chỉ là một giao dịch chuyển khoản giữa hai tài khoản.

### `CategoryRecord` — hạng mục (V2: có nhóm)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | String | có sẵn: nhóm dùng tên cố định (`food`, `salary`…), hạng mục con `food.breakfast`…; người dùng tạo: UUID dạng chuỗi |
| kind | String | `expense` · `income` |
| parentID | String? | **mới ở V2.** nil = nhóm ("Ăn uống"); id của nhóm = hạng mục con ("Ăn sáng") |
| name, icon | String | tên hiển thị; icon là tên trong `IconCatalog` ("hugeicons-car-01") |
| isBuiltIn | Bool | |
| sortOrder | Int | nhóm mặc định cách nhau 100, con của nhóm = nhóm + 1, 2…; mục mới = lớn nhất + 100 |
| archivedAt | Date? | "Ẩn": đã có giao dịch nên không xoá, chỉ không cho chọn nữa |
| createdAt, updatedAt | | |

Hai cấp: nhóm và hạng mục con, cho cả chi và thu. Giao dịch sẽ luôn được ghi vào **hạng mục con**, không ghi vào nhóm (người dùng chọn 2026-10-29), nên mỗi nhóm luôn còn ít nhất một hạng mục con đang dùng; tạo nhóm mới là tạo luôn hạng mục con đầu tiên. Xoá: chưa có giao dịch thì xoá hẳn, đã có thì ẩn (`archivedAt`); xoá/ẩn nhóm kéo theo các hạng mục con.

Chuyển V1 → V2 (lightweight, `TimiMigrationPlan`): 12 hạng mục cũ thành nhóm; lần mở app đầu tiên sau đó (khi chưa có dòng nào có `parentID`), `FinanceDatabase.addMissingDefaultCategories` thêm các hạng mục con và nhóm mặc định (`DefaultCategories`). Chỉ chạy **một lần** (cờ `categories.defaultsAdded` trong UserDefaults, đặt khi `seed()`/bổ sung xong; máy cũ đã có hạng mục con cũng tính là đã chạy): mục mặc định người dùng đã xoá không tự quay lại, kể cả khi xoá hết.

Ẩn nhóm (có giao dịch) thì ẩn luôn các hạng mục con cùng lúc (cùng `archivedAt`); hiện lại nhóm thì hiện lại đúng những hạng mục ẩn cùng lúc với nó, không hiện những hạng mục người dùng đã ẩn riêng trước đó. Hạng mục cuối cùng của nhóm không xoá/ẩn/chuyển nhóm riêng được. Mỗi loại (chi/thu) giữ ít nhất một nhóm đang dùng. Tên là duy nhất trong nhóm cùng loại / hạng mục cùng nhóm (kiểm ở form, không phân biệt hoa thường), tối đa 30 ký tự, không trùng "Điều chỉnh số dư" của hệ thống. Biểu tượng cũ không có trong bảng (`more-horizontal`, `add-01`, kể cả tên Solar cũ) được đổi mỗi lần mở app nếu còn (`replaceRetiredIcons`).

**Đã nối (2026-10-29):** `FinanceTransaction` có `categoryID` (chuỗi) và `kind` lưu riêng. Form giao dịch và "Dùng tiền" chọn **hạng mục con** đang dùng (`CategoryPickerSheet`: gần đây + các nhóm). Giao dịch cũ đang ở nhóm được **giữ nguyên** (người dùng chọn): vẫn hiện tên nhóm, vẫn tính đúng; khi mở sửa thì phải chọn hạng mục con mới lưu được. Báo cáo chi theo hạng mục (`expensesByCategory`) cộng dồn lên nhóm (`FinanceStore.groupID(of:)`). `SampleData` ghi vào hạng mục con.

Còn lại:
- Trợ lý AI (chưa thiết kế xong) vẫn ghi giao dịch vào nhóm (`MockAssistant.category(for:)`), nên quy tắc tạm "12 nhóm có sẵn chỉ ẩn, không xoá" (`FinanceStore.hasHistory`) vẫn giữ.
- "Dùng tiền" vẫn là `GoalSpendSheet` riêng (xem DESIGN_NOTES "Việc để sau").

Hai hạng mục hệ thống `adjustmentIn` (thu) và `adjustmentOut` (chi), tên "Điều chỉnh số dư", không cho người dùng chọn và không hiện trong "Hạng mục". Hạng mục hệ thống thứ ba `transferFee` ("Phí chuyển khoản", chi) không có dòng `CategoryRecord`: tên và biểu tượng lấy từ `TransactionCategory`.

### `TransactionRecord` — giao dịch

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | UUID | |
| kind | String | `expense` · `income` · `transfer` |
| amount | Int64 | luôn > 0; chiều tiền theo `kind` |
| fee | Int64 | phí chuyển khoản |
| accountID | UUID? | chi/thu: tài khoản |
| fromAccountID, toAccountID | UUID? | chuyển khoản: từ → đến |
| categoryID | String? | chi/thu: hạng mục |
| (title) | | luôn để trống (từ 2026-10-29): giao dịch hiện tên hạng mục; tên cũ được chuyển vào `note` khi mở app |
| loanID | UUID? | nếu là lần trả/thu nợ |
| title, note | String | |
| occurredAt | Date | thời điểm phát sinh (ngày + giờ) |
| excluded | Bool | không tính vào báo cáo |
| createdAt, updatedAt | Date | |

Quy tắc theo loại (sẽ thành `CHECK` trong Postgres):

- **chi/thu:** có `accountID` và `categoryID`, không có from/to, `fee = 0`. `excluded = true` khi người dùng bật "Không tính vào báo cáo" (vẫn đổi số dư).
- **chuyển khoản giữa hai tài khoản** (`AccountTransfer`): `kind = transfer`, `categoryID = "accountTransfer"` (để phân biệt với nạp/rút hũ, vốn không có `categoryID`), `fromAccountID ≠ toAccountID`, `fee` là phí, `excluded = true`. Tài khoản nguồn trả `amount + fee`, đích nhận `amount`. Phí **không có dòng riêng** (người dùng chọn 2026-10-29) nhưng vẫn tính là chi tiêu: báo cáo cộng nó vào qua `FinanceStore.reportableTransactions(inMonthOf:)` (hạng mục hệ thống `transferFee`). Dòng phí riêng của bản trước (id = id chuyển khoản lật byte cuối, `AccountTransfer.feeID`) được xoá khi mở app (`foldFeeRows`), số dư không đổi.
- **nạp/rút hũ** (`GoalTransfer`): `kind = transfer`, không có `categoryID`, một đầu là hũ.

- **điều chỉnh số dư:** chi/thu với `categoryID` là `adjustmentIn`/`adjustmentOut` và `excluded = true`. App tạo khi người dùng sửa số dư trong form "Sửa tài khoản": phần chênh lệch thành một giao dịch, để lịch sử luôn cộng lại đúng bằng số dư. Không tính vào tổng thu chi, biểu đồ, lịch tiền và trợ lý.

- **dùng tiền hũ:** chi tiêu bình thường (`kind = expense`, có hạng mục, tính vào báo cáo) nhưng `accountID` là id của hũ. Store trừ thẳng vào số tiền của hũ; phần còn lại (nếu chi ít hơn số trong hũ) thành một dòng rút hũ về tài khoản. Sau đó hũ được đóng.
- **nạp/rút hũ:** chuyển khoản giữa một tài khoản thanh toán và một hũ (hũ cũng là một `AccountRecord`). Nạp: `fromAccountID` = tài khoản, `toAccountID` = hũ; rút thì ngược lại. `excluded = true`, `title` là "Nạp vào hũ" / "Rút từ hũ". App đọc thành `GoalTransfer`; hiện ở màn hũ và màn tài khoản, không tính vào thu chi. Xoá hũ: số tiền còn lại được rút về tài khoản người dùng chọn (một dòng rút mới), rồi xoá hũ nhưng giữ các dòng nạp/rút cũ để lịch sử tài khoản vẫn cộng đúng (app đọc chúng với hũ "đã xoá", nhận hướng nhờ phía còn lại là tài khoản). Tài khoản có lịch sử không bị xoá (chỉ lưu trữ, xem quy tắc 6), nên các dòng nạp/rút của nó luôn còn. Sửa/xoá một lần nạp/rút thì cả hai số dư được tính lại; giao dịch và nạp/rút của hũ đã đóng hoặc đã xoá thì không sửa được.

Mỗi thao tác của người dùng (một lần nạp, một lần dùng tiền…) được lưu trong một lần `save` (`FinanceDatabase.batch`), nên không có trạng thái làm dở. `sortOrder` của tài khoản/hũ mới = lớn nhất hiện có + 1.

Hũ đóng (đã dùng tiền hoặc rút hết sau khi đủ mục tiêu): `AccountRecord.archivedAt` = ngày đóng, `detail` = cách kết thúc ("Đã dùng: Mua xe", "Đã rút về Vietcombank"). App vẫn đọc hũ đã đóng (khác tài khoản đã lưu trữ) để hiện ở "Hũ đã hoàn thành".

Màn hình hiện chỉ hiện chi/thu và nạp/rút hũ. Chuyển khoản giữa hai tài khoản đã có chỗ trong schema, sẽ làm giao diện sau.

### `LoanRecord` — vay nợ

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | UUID | |
| direction | String | `lent` (cho vay) · `borrowed` (đi vay) |
| counterparty | String | người vay / người cho vay; luôn bằng tên người trong danh bạ |
| contactID | UUID? | **mới ở V3.** người trong `ContactRecord`; nil ở dòng từ V2 cho tới khi app nối lúc mở |
| principal, outstanding | Int64 | gốc, còn lại |
| dueDate, settledAt | Date? | hạn trả, ngày tất toán |
| isExisting | Bool | **mới ở V6**, mặc định `true` (dòng cũ chưa từng đổi số dư). Khoản có từ trước khi dùng app: không đổi số dư tài khoản nào |
| accountID | UUID? | **mới ở V6.** Khoản mới: tài khoản tiền đi ra (cho vay) hoặc vào (đi vay); nil với khoản có sẵn |
| loanDate | Date? | **mới ở V6.** Ngày cho vay / đi vay; nil ở dòng cũ (dùng `createdAt`) |
| monthlyInterestRate | Double | **mới ở V6**, mặc định 0. % số gốc mỗi tháng, tháng nào cũng như nhau (không giảm dần) |
| note, createdAt, updatedAt | | |

Khoản mới (người dùng chọn 2026-10-29) trừ số gốc khỏi `accountID` khi cho vay, cộng vào khi đi vay; sửa thì hoàn lần cũ rồi áp lần mới, xoá thì hoàn lại. Không có dòng giao dịch riêng: "Thu chi" (chip Tất cả) và lịch sử tài khoản dựng dòng từ chính khoản vay, không tính là thu hay chi. Chuyển V5 → V6 (lightweight): chỉ thêm cột.

### `ContactRecord` — danh bạ (mới ở V3)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | UUID | |
| name | String | tên, duy nhất (kiểm ở form, không phân biệt hoa thường, có phân biệt dấu), tối đa 40 ký tự |
| isAutoCreated | Bool | **mới ở V5**, mặc định `false`. App tạo từ tên gõ ở khoản vay và người dùng chưa lưu lại trong Danh bạ: bị xoá khi không còn khoản vay nào |
| relationship | String | có sẵn: `family` · `friend` · `colleague` · `acquaintance` · `other`; tự thêm: `id` của `RelationshipRecord` (UUID dạng chuỗi) |
| createdAt, updatedAt | Date | |

Người mà khoản vay ghi theo (người dùng chọn 2026-10-29): khoản vay giữ `contactID`; đổi tên người thì app ghi tên mới vào `counterparty` của các khoản vay của họ. Người còn khoản vay (kể cả đã tất toán) không xoá được. Form khoản vay chọn người từ danh bạ (từ V6); khoản cũ chỉ có tên thì khi lưu app tìm người trùng tên, không có thì tạo người mới `other` (`FinanceStore.link`), nên mọi khoản vay đều có người.

Chuyển V2 → V3 (lightweight): thêm bảng và cột `contactID`; lần mở app đầu sau đó, mỗi tên trong khoản vay chưa có người thành một người `other` (trùng tên thì dùng chung). Chuyển V4 → V5 (lightweight): thêm cột `isAutoCreated` = `false` cho dòng cũ.

### `RelationshipRecord` — loại mối quan hệ tự thêm (mới ở V4)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | String | UUID dạng chuỗi, không trùng id có sẵn |
| name | String | "Hàng xóm"; duy nhất trong mọi loại kể cả loại có sẵn (kiểm ở form), tối đa 20 ký tự |
| icon | String | tên icon trong `IconCatalog` |
| createdAt, updatedAt | Date | |

Năm loại có sẵn không có dòng ở đây. Xoá một loại thì những người thuộc loại đó chuyển về `other`. Chuyển V3 → V4 (lightweight): chỉ thêm bảng.

### `ReminderRecord` — lịch thanh toán sắp tới ("Cần chú ý")

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id, title, amount, isIncome, dueDate, detail | | chưa phải tiền đã chuyển, không ảnh hưởng số dư |
| avatarKind, avatarValue | String | `icon` + tên icon ("hugeicons-…"), hoặc `initials` + chữ cái |
| loanID, accountID | UUID? | liên quan tới khoản vay / thẻ nào |

## So với bản web (Postgres) — việc web cần đổi khi theo chuẩn này

| Chủ đề | Web hiện tại | Chuẩn mới (app) |
|---|---|---|
| Id | `uuidv7()` do server tạo | UUID do máy tạo (web có thể tạo uuidv7 phía client, vẫn hợp lệ) |
| Ví điện tử | `type = 'e-wallet'` | `eWallet` — chọn một kiểu viết cho cả hai bên khi đồng bộ |
| Thẻ tín dụng | chưa là loại tài khoản | `type = 'credit'` có `creditLimit`, `paymentDueDate` |
| Hạng mục | `category_groups` + `category_items` (2 cấp) | một bảng phẳng; thêm nhóm cha ở V2 nếu cần |
| Vay nợ | `debts` + `debt_payments` + `contacts` | `LoanRecord` + `ContactRecord` (V3) + `RelationshipRecord` (V4); các lần trả là giao dịch có `loanID` |
| Tên giao dịch | chỉ `note` | có thêm `title` |
| Lưu trữ | `status = 'archived'` | `archivedAt` (biết cả thời điểm) |
| Hũ | màu `goal_color` | chưa có màu (app không dùng); thêm khi cần |

Những phần web có mà app chưa cần (người dùng, gói, thanh toán, thông báo, ngân sách theo hạng mục…) sẽ thêm thành bảng mới ở các phiên bản sau.

## Bước tiếp theo

1. ~~Màn **Hạng mục** đọc/ghi `CategoryRecord`; giao dịch chuyển sang dùng `categoryID` thay vì enum cố định.~~ Xong 2026-10-29.
2. ~~Giao diện **chuyển khoản** (`kind = transfer`)~~ (xong 2026-10-29); trả nợ ghi giao dịch có `loanID`.
3. Lưu **hạn mức** vào database (hiện ở `UserDefaults`).
4. Khi có backend: đồng bộ theo `updatedAt`, thêm `deletedAt` để báo xoá cho máy khác.
5. Nâng target lên iOS 18 để thêm `#Index` cho `occurredAt`, `accountID`.
