# Cơ sở dữ liệu Timi

Timi lưu dữ liệu trên máy bằng **SwiftData** (Apple, iOS 17+). Schema ở đây là **chuẩn gốc** cho mọi bản Timi: bản web sau này chuyển sang theo, rồi hai bên đồng bộ.

Code nằm ở `Timi/Persistence/`:

| File | Vai trò |
|---|---|
| `TimiSchemaV1.swift` | Định nghĩa 5 bảng (phiên bản 1) và kế hoạch chuyển phiên bản |
| `RecordMapping.swift` | Đổi qua lại giữa dòng trong database và kiểu dữ liệu các màn dùng |
| `FinanceDatabase.swift` | Đọc, ghi, nạp dữ liệu mẫu, đặt lại; mọi code SwiftData chỉ ở đây |

`FinanceStore` vẫn là nơi các màn đọc dữ liệu. Mở app thì nó nạp từ database. Mỗi lần thêm, sửa hoặc xoá, nó ghi ngay xuống database (write-through). Lần mở app đầu tiên, database trống nên được nạp dữ liệu mẫu. Cài đặt → Nhà phát triển → **Đặt lại dữ liệu mẫu** để làm lại từ đầu.

## Quy tắc chung

1. **`id` là UUID tạo trên máy.** Nhờ vậy tạo bản ghi được khi không có mạng; lúc đồng bộ không trùng id. Postgres dùng `uuid`.
2. **Tiền là số nguyên (`Int64`), đơn vị đồng.** VND không có số lẻ, và số nguyên cộng dồn không bị sai số như `Double`. Postgres dùng `bigint`, giống bản web hiện tại.
3. **Liên kết bằng id, không dùng relationship của SwiftData.** Ví dụ giao dịch giữ `accountID`, giống khoá ngoại trong SQL, nên chuyển sang Postgres là ánh xạ 1:1.
4. **Kiểu liệt kê lưu dạng chuỗi** (`"expense"`, `"bank"`, `"lent"`…), không lưu enum của Swift. Web và backend đọc được ngay.
5. **Mọi bảng có `createdAt` và `updatedAt`.** Đồng bộ sau này dựa vào `updatedAt` để biết dòng nào đã đổi.
6. **Không xoá cứng tài khoản đang có lịch sử**: dùng `archivedAt`. Màn hình hiện chỉ đọc tài khoản chưa lưu trữ.
7. **Đổi schema = thêm phiên bản mới** (`TimiSchemaV2` + một bước trong `TimiMigrationPlan`), không sửa V1. Nếu sửa V1, máy đã cài app sẽ không mở được dữ liệu cũ.

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
| goalTarget, goalIcon, goalDueDate | Int64?, String?, Date? | chỉ hũ (`type = savings`) |
| excluded | Bool | không tính vào tổng và báo cáo |
| archivedAt | Date? | đã lưu trữ |
| sortOrder | Int | thứ tự hiển thị |
| createdAt, updatedAt | Date | |

Hũ tiết kiệm là một loại tài khoản, giống bản web. Như vậy sau này "bỏ tiền vào hũ" chỉ là một giao dịch chuyển khoản giữa hai tài khoản.

### `CategoryRecord` — hạng mục

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | String | 12 hạng mục có sẵn dùng tên cố định (`food`, `salary`…); hạng mục người dùng tạo dùng UUID dạng chuỗi |
| kind | String | `expense` · `income` |
| name, icon | String | tên hiển thị, icon Solar |
| isBuiltIn | Bool | |
| sortOrder, archivedAt, createdAt, updatedAt | | |

Hiện app vẫn đọc hạng mục từ code (`TransactionCategory`). Bảng này đã được tạo và nạp sẵn để làm màn "Hạng mục" trong Cài đặt.

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
| loanID | UUID? | nếu là lần trả/thu nợ |
| title, note | String | |
| occurredAt | Date | thời điểm phát sinh (ngày + giờ) |
| excluded | Bool | không tính vào báo cáo |
| createdAt, updatedAt | Date | |

Quy tắc theo loại (sẽ thành `CHECK` trong Postgres):

- **chi/thu:** có `accountID` và `categoryID`, không có from/to, `fee = 0`.
- **chuyển khoản:** có `fromAccountID ≠ toAccountID`, không có `accountID`/`categoryID`.

Màn hình hiện chỉ hiện chi/thu. Chuyển khoản đã có chỗ trong schema, sẽ làm giao diện sau.

### `LoanRecord` — vay nợ

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | UUID | |
| direction | String | `lent` (cho vay) · `borrowed` (đi vay) |
| counterparty | String | người vay / người cho vay |
| principal, outstanding | Int64 | gốc, còn lại |
| dueDate, settledAt | Date? | hạn trả, ngày tất toán |
| note, createdAt, updatedAt | | |

### `ReminderRecord` — lịch thanh toán sắp tới ("Cần chú ý")

| Trường | Kiểu | Ghi chú |
|---|---|---|
| id, title, amount, isIncome, dueDate, detail | | chưa phải tiền đã chuyển, không ảnh hưởng số dư |
| avatarKind, avatarValue | String | `icon` + tên Solar, hoặc `initials` + chữ cái |
| loanID, accountID | UUID? | liên quan tới khoản vay / thẻ nào |

## So với bản web (Postgres) — việc web cần đổi khi theo chuẩn này

| Chủ đề | Web hiện tại | Chuẩn mới (app) |
|---|---|---|
| Id | `uuidv7()` do server tạo | UUID do máy tạo (web có thể tạo uuidv7 phía client, vẫn hợp lệ) |
| Ví điện tử | `type = 'e-wallet'` | `eWallet` — chọn một kiểu viết cho cả hai bên khi đồng bộ |
| Thẻ tín dụng | chưa là loại tài khoản | `type = 'credit'` có `creditLimit`, `paymentDueDate` |
| Hạng mục | `category_groups` + `category_items` (2 cấp) | một bảng phẳng; thêm nhóm cha ở V2 nếu cần |
| Vay nợ | `debts` + `debt_payments` + `contacts` | `LoanRecord`; các lần trả là giao dịch có `loanID` |
| Tên giao dịch | chỉ `note` | có thêm `title` |
| Lưu trữ | `status = 'archived'` | `archivedAt` (biết cả thời điểm) |
| Hũ | màu `goal_color` | chưa có màu (app không dùng); thêm khi cần |

Những phần web có mà app chưa cần (người dùng, gói, thanh toán, thông báo, ngân sách theo hạng mục…) sẽ thêm thành bảng mới ở các phiên bản sau.

## Bước tiếp theo

1. Màn **Hạng mục** đọc/ghi `CategoryRecord`; giao dịch chuyển sang dùng `categoryID` thay vì enum cố định.
2. Giao diện **chuyển khoản** (`kind = transfer`) và trả nợ ghi giao dịch có `loanID`.
3. Lưu **hạn mức** vào database (hiện ở `UserDefaults`).
4. Khi có backend: đồng bộ theo `updatedAt`, thêm `deletedAt` để báo xoá cho máy khác.
5. Nâng target lên iOS 18 để thêm `#Index` cho `occurredAt`, `accountID`.
