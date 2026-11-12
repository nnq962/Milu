import Foundation
import SwiftUI

/// "Xoá toàn bộ dữ liệu" (Cài đặt): đưa dữ liệu về như lúc mới tải, trừ lượt AI.
///
/// Xoá mọi dòng trong SwiftData và mọi tuỳ chọn trong UserDefaults (hạn mức, nhắc nhở, giao diện,
/// lịch sử tìm kiếm…), **trừ lượt AI** (đã dùng, thưởng, các bước "Làm quen với Milu" đã nhận: khoá
/// `ai.*`), để không xoá đi làm lại lấy lượt mới (người dùng chọn 2026-11-08). Sau đó `MiluApp` dựng
/// lại store, lượt AI (đọc lại từ khoá giữ nguyên), các cuộc trò chuyện và cả cây giao diện, nên app
/// mở lại ở Tổng quan; các bước đã nhận vẫn tính là xong. Không thêm lại dữ liệu mẫu, kể cả ở các
/// lần mở sau (`StorageKey.sampleDataOff`), và hạn mức về 0 thay vì hạn mức mẫu: trước đây dữ liệu
/// mẫu quay lại y như cũ nên người dùng tưởng
/// xoá không chạy (2026-11-02). Chỉ còn các hạng mục mặc định.
///
/// App không lưu gì trong Keychain hay file riêng. Quyền mua Milu Pro (khi có) do StoreKit và
/// Apple ID giữ, app không xoá được: cứ để nguyên, "Khôi phục giao dịch mua" sẽ lấy lại.
@MainActor
enum DataReset {
    static func eraseEverything(database: FinanceDatabase?) {
        database?.deleteEverything()
        // The chats with Milu speak of the money too.
        AssistantChats.deleteSaved()
        let defaults = UserDefaults.standard
        // Từng khoá một, không dùng `removePersistentDomain`: sau lệnh đó, các giá trị ghi ngay bên
        // dưới bị mất khi app đóng, nên lần mở sau dữ liệu mẫu lại quay về (thử trên Simulator
        // 2026-11-02). Khoá của hệ thống (ngôn ngữ…) không nằm trong miền của app, nên xoá ở đây
        // không ảnh hưởng tới chúng.
        // Lượt AI (đã dùng, thưởng, các bước đã nhận) giữ nguyên: xoá dữ liệu không được đổi lấy
        // lượt mới, rồi làm lại các bước để nhận thêm (người dùng chọn 2026-11-08).
        // The welcome stays seen too: erasing is not starting the app anew.
        for key in defaults.dictionaryRepresentation().keys where !AIQuota.isOwnKey(key) && key != StorageKey.welcomeSeen {
            defaults.removeObject(forKey: key)
        }
        // Trống thật: không dữ liệu mẫu, không hạn mức mẫu (các `@AppStorage` lấy hạn mức mẫu làm
        // giá trị mặc định khi chưa có gì được lưu).
        defaults.set(true, forKey: StorageKey.sampleDataOff)
        defaults.set(0.0, forKey: StorageKey.monthlyBudget)
        defaults.set(CategoryBudgets().rawValue, forKey: StorageKey.categoryBudgets)
    }
}

/// Gọi từ một màn bất kỳ để xoá toàn bộ dữ liệu; `MiluApp` gắn việc thật vào đây.
struct EraseAllDataAction {
    let action: @MainActor () -> Void

    @MainActor func callAsFunction() { action() }
}

extension EnvironmentValues {
    /// Mặc định không làm gì (previews).
    @Entry var eraseAllData = EraseAllDataAction {}
}
