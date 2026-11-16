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
    /// The app is on screen and in front (`scenePhase`), read by tasks as it is now.
    @State private var isActive = false
    /// The self-recording rules' pass waiting for iCloud (`autoRecord`); a new one replaces it.
    @State private var autoRecording: Task<Void, Never>?
    /// "Khoá bằng Face ID" (Milu Pro): locked from launch when on.
    @State private var appLock = AppLock.shared
    @State private var lockCurtain = LockCurtain()
    @AppStorage(StorageKey.welcomeSeen) private var welcomeSeen = false
    /// Cài đặt › Nhà phát triển › "Xem lại màn chào mừng": this iPhone only (`StorageKey.replayWelcome`).
    @AppStorage(StorageKey.replayWelcome) private var replayWelcome = false
    /// Tổng quan's Than is loaded: the first page waits for it, so it opens with Than there.
    @State private var heroReady = false
    /// The splash still over the first page; it fades off once the page is drawn under it.
    @State private var showsSplash = true
    @State private var splashFading = false
    /// A new user's first launch: iOS's launch picture, drawn again over the welcome, fades off
    /// it instead of cutting from the garden to the welcome (user request 2026-11-14).
    @State private var launchCover = false
    /// The welcome was finished: Tổng quan is built under it before it fades.
    @State private var homeUnderWelcome = false
    /// Milu's invitation to the 21:00 reminder, over Tổng quan on a new install (`NotificationInvite`).
    @State private var showsNotificationInvite = false
    /// The welcome on screen. Its own state, not `welcomeSeen`: a stored value changes after the
    /// animation's moment, and the welcome cut to Tổng quan instead of fading (2026-11-14).
    @State private var showsWelcome = false
    /// The welcome and the launch picture fading, before they are taken away: at the app's root
    /// only a change of opacity animates, a view taken away cuts (as the splash, 2026-11-14).
    @State private var welcomeFading = false
    @State private var launchFading = false
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
    /// How long the welcome takes to fade off Tổng quan, and the launch picture off the welcome.
    private static let welcomeFade: TimeInterval = 0.45

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
        // The welcome again, launched with `-showWelcome` (Xcode, devicectl): in Release too, to
        // see it on the phone, where Cài đặt's "Xem lại màn chào mừng" is Debug only. No one but
        // a developer's tools passes launch arguments. This launch only: `welcomeSeen` cleared
        // went to every device on the Apple ID through iCloud (audit round 4, 2026-11-16).
        let welcomes = ProcessInfo.processInfo.arguments.contains("-showWelcome")
            || !UserDefaults.standard.bool(forKey: StorageKey.welcomeSeen)
        _launchCover = State(initialValue: welcomes)
        _showsWelcome = State(initialValue: welcomes)
        // The welcome's Than, loaded while iOS's launch picture shows.
        if welcomes { WelcomeThan.preload() }
        #if DEBUG
        // Recurring rules overdue, on an archived account, coming soon (`RecurringDemo`).
        if ProcessInfo.processInfo.arguments.contains("-demoRecurring") { store.seedRecurringDemo() }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showsWelcome || homeUnderWelcome {
                    // Built under the splash once Tổng quan's Than is ready, so it is drawn and
                    // still when the splash fades off it; after the welcome, under the welcome.
                    if heroReady {
                        ContentView()
                            .id(generation)
                            .syncStatusPill()
                    }
                }
                if showsWelcome {
                    WelcomeView(onFinish: finishWelcome)
                        .opacity(welcomeFading ? 0 : 1)
                        .scaleEffect(welcomeFading ? 1.04 : 1)
                        .animation(Motion.gentle(.easeInOut(duration: Self.welcomeFade)), value: welcomeFading)
                        .allowsHitTesting(!welcomeFading)
                        .zIndex(1)
                }
                if showsWelcome && launchCover {
                    LaunchPicture()
                        .opacity(launchFading ? 0 : 1)
                        .animation(Motion.gentle(.easeInOut(duration: Self.welcomeFade)), value: launchFading)
                        .task {
                            // A moment as iOS left it, then the welcome comes through.
                            try? await Task.sleep(for: .milliseconds(120))
                            launchFading = true
                            try? await Task.sleep(for: .seconds(Self.welcomeFade))
                            launchCover = false
                        }
                        .zIndex(2)
                }
                if !showsWelcome && showsSplash {
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
                                // Gone at once under the lock as it fades: one fade from the lock
                                // to the page, not the lock's words giving way to the splash's
                                // (user report 2026-11-14).
                                showsSplash = false
                                return
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
                // Inside the modifiers below, so the sheet has the app's environment.
                .sheet(isPresented: $showsNotificationInvite) { NotificationInviteView() }
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
                // The lock, and the cover while Milu is not in front with the lock on, in a window of
                // their own above this one, so over any sheet open too (`LockWindowInstaller`).
                .background { LockWindowInstaller(lock: appLock, curtain: lockCurtain).frame(width: 0, height: 0) }
                // What came down from iCloud: read once, when the sync has gone quiet (see
                // `CloudSyncMonitor.takeNewData`). Watched by a small view of its own, not here:
                // read here, each round of the sync at launch rebuilt the app's root, and every
                // page under it redrew while Tổng quan's charts were still drawing (Instruments
                // on the iPhone 2026-11-13).
                .modifier(ReloadAfterSync(sync: sync, store: store))
                // The mark changed while the app runs: cleared by "Xem lại màn chào mừng" (Cài
                // đặt, Debug), or set by iCloud on a reinstall (`CloudSettings`), when the welcome
                // gives way to the splash and Tổng quan, as at a launch.
                .onChange(of: replayWelcome) { _, replay in
                    guard replay else { return }
                    replayWelcome = false
                    showsWelcome = true
                }
                .onChange(of: welcomeSeen) { _, seen in
                    if !seen {
                        showsWelcome = true
                    } else if showsWelcome && !homeUnderWelcome {
                        showsWelcome = false
                    }
                }
                // A new install: Milu's invitation to the 21:00 reminder once the welcome and the
                // splash (and the lock) are gone and Tổng quan is up (`NotificationInvite`, user
                // requests 2026-11-15).
                .task(id: showsWelcome || showsSplash) {
                    guard !showsWelcome, !showsSplash else { return }
                    // A moment on the page first, so the invitation comes over it, not its arrival.
                    try? await Task.sleep(for: .seconds(0.8))
                    // Not over another sheet, where it could not show (it then comes at a later
                    // launch); marked seen only once it is on screen (audit 2026-11-15).
                    guard !Task.isCancelled, await NotificationInvite.isDue(), !Presentation.isShowingSheet else { return }
                    showsNotificationInvite = true
                }
                // What recurring rules that record by themselves owe since the app was last open,
                // once this launch's download from iCloud is in (`autoRecord`). Launched by
                // iCloud in the background long before, the download that counts is one after
                // the screen came up (audit round 4, 2026-11-16: the old background one did).
                .task(id: generation) {
                    let launchedJustNow = ContinuousClock.now - sync.startedAt < .seconds(5)
                    autoRecord(since: launchedJustNow ? sync.startedAt : .now)
                }
                // Past midnight: today's are due now, by the same way in (audit round 4: this
                // one recorded at once, from what the app held, on a return the day after).
                .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
                    autoRecord(since: .now)
                }
                // Pro bought or lapsed: the AI allowance follows; the lock follows its switch.
                .onChange(of: ProStore.shared.isPro) {
                    appLock.refresh()
                    quota.reload()
                }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            isActive = phase == .active
            // The lock follows UIKit's scene notifications itself (`LockWindowInstaller`).
            if phase == .background {
                cameFromBackground = true
            }
            // Back from the background: anything that came in meanwhile.
            if phase == .active {
                // A plan cancelled or lapsed while away (Cài đặt › Đăng ký): Pro follows at once.
                Task { await ProStore.shared.refresh() }
                // Read again only when iCloud brought something meanwhile: every return read the
                // whole database on the main thread, years of it, for nothing (audit 2026-11-15).
                // On every coming to the front, not only from the background: started by iCloud
                // in the background, the app had its data written with no screen to read it, and
                // opened on what it held before (audit round 3, 2026-11-16).
                if sync.takeNewData() { store.reload() }
                guard cameFromBackground else { return }
                cameFromBackground = false
                sync.checkAccount()
                // What came due while away, once iCloud has sent what changed meanwhile.
                autoRecord(since: .now)
            }
        }
    }

    /// The one way the self-recording rules record by themselves (audit round 4, 2026-11-16:
    /// there were three, two of them without waiting): with the app in front, once a download
    /// from iCloud that ended after `since` has gone quiet (or none can come), on the database as
    /// iCloud left it, what came down read first (audit round 3: recorded on the copy from before
    /// the download, a payment or rule deleted on another device came back). A new call replaces
    /// one still waiting.
    private func autoRecord(since: ContinuousClock.Instant) {
        autoRecording?.cancel()
        autoRecording = Task {
            await sync.waitForFreshData(since: since)
            while !Task.isCancelled, !isActive {
                try? await Task.sleep(for: .milliseconds(250))
            }
            guard !Task.isCancelled else { return }
            if sync.takeNewData() { store.reload() }
            store.recordDueRecurring()
        }
    }

    /// The welcome is done: straight to Tổng quan, built under the welcome and still before it
    /// fades. No splash after it: the welcome was the greeting (user request 2026-11-14), and a
    /// new user's splash, never shown at launch, was still waiting to play.
    private func finishWelcome() {
        showsSplash = false
        Task { @MainActor in
            await MiluRiveCharacter.overviewReady()
            MiluRiveCharacter.park()
            homeUnderWelcome = true
            heroReady = true
            try? await Task.sleep(for: .seconds(Self.pageSettle))
            welcomeFading = true
            try? await Task.sleep(for: .seconds(Self.welcomeFade))
            showsWelcome = false
            welcomeFading = false
            welcomeSeen = true
            homeUnderWelcome = false
            WelcomeThan.shared.release()
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
        content
            .onChange(of: sync.isReceiving) { _, receiving in
                if !receiving { readNewData() }
            }
            .onChange(of: sync.quietImports) { readNewData() }
    }

    /// What came down, read. Nothing recorded here: a restore comes in rounds, and recording
    /// after the first wrote from data still behind (audit round 3, 2026-11-16); the launch and
    /// the return to the front record once the downloads have settled.
    private func readNewData() {
        guard !sync.isReceiving, sync.takeNewData() else { return }
        store.reload()
    }
}

