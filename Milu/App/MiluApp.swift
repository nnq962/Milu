//
//  MiluApp.swift
//  Milu
//
//  Created by Nguyen Ngoc Quyet on 10/25/26.
//

import SwiftData
import SwiftUI

@main
struct MiluApp: App {
    private let container: ModelContainer
    @State private var store: FinanceStore
    @State private var quota: AIQuota
    @State private var sync: CloudSyncMonitor
    /// Hạn mức, tên, lượt AI… theo người dùng sang máy khác qua iCloud (`CloudSettings`).
    private let cloudSettings = CloudSettings()
    @State private var chats = AssistantChats()
    /// Tăng mỗi lần xoá toàn bộ dữ liệu: `ContentView` mang id mới nên được dựng lại từ đầu (về tab
    /// Tổng quan, đóng mọi sheet đang mở).
    @State private var generation = 0
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Typography.configureNativeAppearance()
        // Set before launch ends, so a tapped notification that opened the app is heard.
        _ = Reminders.shared
        // Before anything reads them: a reinstall gets its settings and AI allowance back.
        cloudSettings.start()
        let quota = AIQuota(unlimited: AIQuota.unlimitedInDebug)
        _quota = State(initialValue: quota)
        cloudSettings.onChangeFromCloud = { [weak quota] in quota?.reload() }
        // Listening before the database opens, so its first sync (setup, then data coming down) is seen.
        let sync = CloudSyncMonitor()
        sync.start()
        _sync = State(initialValue: sync)
        let container = FinanceDatabase.makeContainer()
        self.container = container
        // A new install starts empty (the default categories only), never with sample data: with
        // iCloud the database is still empty at first launch while the user's data comes down,
        // and sample data made then synced up beside it, doubling every account (iPhone test
        // 2026-11-12; checking for an iCloud sign-in first missed it). Sample data stays one tap
        // away in Debug (Cài đặt → Nhà phát triển → Đặt lại dữ liệu mẫu).
        _store = State(initialValue: FinanceStore(database: FinanceDatabase(context: container.mainContext),
                                                  seedsSampleData: false))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(generation)
                .syncStatusPill()
                // The body role (16 SemiBold), so a Text with no role still matches the scale
                // (strict review 2026-10-31: 17 Regular sat outside it).
                .font(TextRole.body.font)
                .scrollIndicators(.hidden, axes: .vertical)
                .environment(store)
                .environment(quota)
                .environment(chats)
                .environment(sync)
                .modelContainer(container)
                .environment(\.locale, .vietnam)
                .environment(\.eraseAllData, EraseAllDataAction(action: eraseAllData))
                // What came down from iCloud: read once, when the sync has gone quiet (see
                // `CloudSyncMonitor.takeNewData`).
                .onChange(of: sync.isReceiving) { _, receiving in
                    if !receiving, sync.takeNewData() { store.reload() }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // Back from the background: anything that came in meanwhile.
            if phase == .active {
                store.reload()
                sync.checkAccount()
            }
        }
    }

    /// Xoá dữ liệu rồi dựng lại mọi thứ, giữ lượt AI (`DataReset`).
    private func eraseAllData() {
        DataReset.eraseEverything(database: store.database)
        Reminders.shared.removeAll()
        // Store mới trên database trống: chỉ thêm hạng mục mặc định, không dữ liệu mẫu
        // (`sampleDataOff`). Lượt AI đọc lại từ các khoá `ai.*` vẫn còn.
        store = FinanceStore(database: FinanceDatabase(context: container.mainContext), seedsSampleData: false)
        let quota = AIQuota(unlimited: AIQuota.unlimitedInDebug)
        self.quota = quota
        cloudSettings.onChangeFromCloud = { [weak quota] in quota?.reload() }
        chats = AssistantChats()
        // Giao diện về "Hệ thống" ngay, không đợi mở lại app.
        AppAppearance.system.apply(animated: false)
        generation += 1
    }
}
