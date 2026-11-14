//
//  MiluApp.swift
//  Milu
//
//  Created by Nguyen Ngoc Quyet on 10/25/26.
//

import SwiftData
import Combine
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
    /// "Khoá bằng Face ID" (Milu Pro): locked from launch when on.
    @State private var appLock = AppLock()
    @AppStorage(StorageKey.welcomeSeen) private var welcomeSeen = false
    /// Tổng quan's Than is loaded: the first page waits for it, so it opens with Than there.
    @State private var heroReady = false
    /// The splash still over the first page; it fades off once the page is drawn under it.
    @State private var showsSplash = true
    @State private var splashFading = false
    /// The app went to the background since it was last active: only then is the database read
    /// again, not after every banner, Control Centre or Face ID prompt (each left it inactive a
    /// moment, and the reload froze the screen ~170 ms, Instruments on the iPhone 2026-11-13).
    @State private var cameFromBackground = false

    /// When the app started, for the splash's shortest time.
    private static let launchedAt = Date.now
    /// How long the splash shows at least, iOS's launch picture included.
    /// (2.0 from 1.4: the greeting went too soon, user request 2026-11-14.)
    private static let splashTime: TimeInterval = 2.0
    /// How long the splash takes to fade off the first page.
    private static let splashFade: TimeInterval = 0.8
    /// The greeting's length (Than's pop-up), before the page is built under the splash.
    private static let greetingTime: TimeInterval = 0.9
    /// The page's first frames under the splash before it fades.
    private static let pageSettle: TimeInterval = 0.4

    /// Until `seconds` after launch.
    private static func wait(until seconds: TimeInterval) async {
        let left = seconds - Date.now.timeIntervalSince(launchedAt)
        if left > 0 { try? await Task.sleep(for: .seconds(left)) }
    }

    init() {
        _ = Self.launchedAt
        Typography.configureNativeAppearance()
        // Set before launch ends, so a tapped notification that opened the app is heard.
        _ = Reminders.shared
        // Before anything reads them: a reinstall gets its settings and AI allowance back.
        cloudSettings.start()
        // What the App Store says is owned, and every renewal or refund from now on.
        ProStore.shared.start()
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
        let store = FinanceStore(database: FinanceDatabase(context: container.mainContext), seedsSampleData: false)
        _store = State(initialValue: store)
        // Than for the three tabs, loaded now so each tab opens with it already there.
        MiluRiveCharacter.preload(store)
        // An install that already holds data (this one before the welcome existed) is not new.
        if !store.accounts.isEmpty || !store.transactions.isEmpty || !store.savingsGoals.isEmpty {
            UserDefaults.standard.set(true, forKey: StorageKey.welcomeSeen)
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-showWelcome") {
            UserDefaults.standard.set(false, forKey: StorageKey.welcomeSeen)
        }
        // Recurring rules overdue, on an archived account, coming soon (`RecurringDemo`).
        if ProcessInfo.processInfo.arguments.contains("-demoRecurring") { store.seedRecurringDemo() }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if welcomeSeen {
                    // Built under the splash once Tổng quan's Than is ready, so it is drawn and
                    // still when the splash fades off it.
                    if heroReady {
                        ContentView()
                            .id(generation)
                            .syncStatusPill()
                    }
                } else {
                    WelcomeView {
                        withAnimation(.easeInOut(duration: 0.45)) { welcomeSeen = true }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                }
                if welcomeSeen && showsSplash {
                    // Milu's greeting (`SplashScreen`) over the first page while it gets ready,
                    // then fading slowly off it (user requests 2026-11-13, -14).
                    SplashScreen()
                        .task {
                            await MiluRiveCharacter.overviewReady()
                            MiluRiveCharacter.park()
                            if appLock.isLocked {
                                // Opened with the lock on: the lock (the same garden) is over the
                                // splash, and the page is built under both. Once Face ID opens
                                // it, straight to the page, no splash again after the lock (user
                                // report 2026-11-14).
                                heroReady = true
                                try? await Task.sleep(for: .seconds(Self.pageSettle))
                                while appLock.isLocked {
                                    try? await Task.sleep(for: .milliseconds(50))
                                }
                            } else {
                                // The greeting plays first; the page is built under it once Than
                                // has popped up, the splash still, so its first heavy frame
                                // stalls nothing that moves.
                                await Self.wait(until: Self.greetingTime)
                                heroReady = true
                                // Shown long enough to be seen (user report 2026-11-14: it
                                // flashed by), and the page given time to be drawn: faded while
                                // it was still being built, the fade's frames were lost and it
                                // cut to the page.
                                try? await Task.sleep(for: .seconds(Self.pageSettle))
                                await Self.wait(until: Self.splashTime)
                            }
                            // A slow fade, soft at both ends, then gone: a transition at the app's
                            // root cut straight to the page (user request 2026-11-14).
                            splashFading = true
                            try? await Task.sleep(for: .seconds(Self.splashFade))
                            showsSplash = false
                        }
                        .opacity(splashFading ? 0 : 1)
                        // Tied to the splash itself: an animation started from the task did
                        // not run here, and it cut to the page.
                        .animation(Motion.gentle(.easeInOut(duration: Self.splashFade)), value: splashFading)
                        .allowsHitTesting(!splashFading)
                        .zIndex(1)
                }
            }
                .background { SavedAppearanceSetter().frame(width: 0, height: 0) }
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
                .environment(appLock)
                // Locked: the lock over everything. Not in front with the lock on: a cover, so
                // the app switcher's picture shows no balance.
                .overlay {
                    if appLock.isLocked {
                        LockScreen(lock: appLock)
                            .transition(.opacity)
                    } else if appLock.isOn, scenePhase == .background
                                || (scenePhase == .inactive && appLock.coversWhileInactive()) {
                        PrivacyCover()
                    }
                }
                // Quick: the face is already known, the app should be there at once.
                .animation(.easeOut(duration: 0.15), value: appLock.isLocked)
                // What came down from iCloud: read once, when the sync has gone quiet (see
                // `CloudSyncMonitor.takeNewData`). Watched by a small view of its own, not here:
                // read here, each round of the sync at launch rebuilt the app's root, and every
                // page under it redrew while Tổng quan's charts were still drawing (Instruments
                // on the iPhone 2026-11-13).
                .modifier(ReloadAfterSync(sync: sync, store: store))
                // What recurring rules that record by themselves owe since the app was last open.
                .task(id: generation) { store.recordDueRecurring() }
                // Past midnight with the app open: today's are due now.
                .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
                    store.recordDueRecurring()
                }
                // Pro bought or lapsed: the lock follows the plan, the AI allowance with it.
                .onChange(of: ProStore.shared.isPro) {
                    appLock.refresh()
                    quota.reload()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                appLock.didLeave()
                cameFromBackground = true
            }
            // Back from the background: anything that came in meanwhile.
            if phase == .active {
                appLock.didReturn()
                // A plan cancelled or lapsed while away (Cài đặt › Đăng ký): Pro follows at once.
                Task { await ProStore.shared.refresh() }
                guard cameFromBackground else { return }
                cameFromBackground = false
                store.reload()
                store.recordDueRecurring()
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

/// Reads the database again once the iCloud sync has gone quiet with new data.
private struct ReloadAfterSync: ViewModifier {
    let sync: CloudSyncMonitor
    let store: FinanceStore

    func body(content: Content) -> some View {
        content.onChange(of: sync.isReceiving) { _, receiving in
            if !receiving, sync.takeNewData() {
                store.reload()
                store.recordDueRecurring()
            }
        }
    }
}
