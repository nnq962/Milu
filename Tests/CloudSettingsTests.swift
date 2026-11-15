import Foundation
import Testing
@testable import Milu

/// Settings that follow the user through iCloud's key-value store (`CloudSettings`), and what the
/// sync pill and Cài đặt read (`CloudSyncMonitor`).
@MainActor
struct CloudSettingsTests {
    /// iCloud's key-value store, in memory.
    final class FakeCloud: KeyValueStore {
        var values: [String: Any] = [:]
        func object(forKey key: String) -> Any? { values[key] }
        func set(_ value: Any?, forKey key: String) { values[key] = value }
        func removeObject(forKey key: String) { values[key] = nil }
        var dictionaryRepresentation: [String: Any] { values }
        func synchronize() -> Bool { true }
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "CloudSettingsTests.\(UUID().uuidString)")!
    }

    /// A reinstall: nothing on the device, iCloud has the limit, the name and the AI allowance.
    @Test func aReinstallGetsItsSettingsBack() {
        let defaults = makeDefaults()
        let cloud = FakeCloud()
        cloud.values = [StorageKey.monthlyBudget: 8_000_000.0, StorageKey.profileName: "Quyết",
                        "ai.weekUsed": 7, "ai.week": "2026-W46", StorageKey.appearance: "dark"]
        CloudSettings(defaults: defaults, cloud: cloud).pull(keys: nil)
        #expect(defaults.double(forKey: StorageKey.monthlyBudget) == 8_000_000)
        #expect(defaults.string(forKey: StorageKey.profileName) == "Quyết")
        #expect(defaults.integer(forKey: "ai.weekUsed") == 7)
        // The appearance is this device's own choice.
        #expect(defaults.string(forKey: StorageKey.appearance) == nil)
    }

    /// A change here goes up; one erased here is erased in iCloud too; per-device keys stay here.
    @Test func changesGoUpAndErasingGoesUpToo() {
        let defaults = makeDefaults()
        defaults.set("Cũ", forKey: StorageKey.profileName)
        let cloud = FakeCloud()
        cloud.values = [StorageKey.profileName: "Cũ"]
        let settings = CloudSettings(defaults: defaults, cloud: cloud)
        defaults.set(5_000_000.0, forKey: StorageKey.monthlyBudget)
        defaults.set("dark", forKey: StorageKey.appearance)
        defaults.removeObject(forKey: StorageKey.profileName)
        settings.push()
        #expect(cloud.values[StorageKey.monthlyBudget] as? Double == 5_000_000)
        #expect(cloud.values[StorageKey.profileName] == nil)
        #expect(cloud.values[StorageKey.appearance] == nil)
    }

    /// A key only iCloud has has not come down yet: a change here leaves it there (audit
    /// 2026-11-15: taken for erased here, it was erased in iCloud).
    @Test func aKeyNotYetDownIsNotErased() {
        let defaults = makeDefaults()
        let cloud = FakeCloud()
        let settings = CloudSettings(defaults: defaults, cloud: cloud)
        settings.start()
        cloud.values[StorageKey.profileName] = "Quyết"
        defaults.set(5_000_000.0, forKey: StorageKey.monthlyBudget)
        settings.push()
        #expect(cloud.values[StorageKey.profileName] as? String == "Quyết")
        #expect(cloud.values[StorageKey.monthlyBudget] as? Double == 5_000_000)
    }

    /// A reinstall's first sync: everything comes down after launch, all of it, and stays in
    /// iCloud (audit 2026-11-15: writing the first key sent "erase" for the rest, on every device).
    @Test func theFirstSyncAfterAReinstallKeepsEverything() {
        let defaults = makeDefaults()
        let cloud = FakeCloud()
        let settings = CloudSettings(defaults: defaults, cloud: cloud)
        settings.start()
        let synced: [String: Any] = [StorageKey.monthlyBudget: 8_000_000.0, StorageKey.profileName: "Quyết",
                                     StorageKey.dailyReminder: true, "ai.weekUsed": 7, StorageKey.welcomeSeen: true]
        cloud.values = synced
        settings.pull(keys: Array(synced.keys))
        for (key, value) in synced {
            #expect((defaults.object(forKey: key) as AnyObject).isEqual(value), "\(key) on the device")
            #expect((cloud.values[key] as AnyObject).isEqual(value), "\(key) in iCloud")
        }
    }

    /// Two settings changed together on another device ("Bỏ hạn mức": the month's limit and the
    /// groups'): both come down, and neither old value goes back up (audit 2026-11-15).
    @Test func twoKeysChangedElsewhereBothComeDown() {
        let defaults = makeDefaults()
        defaults.set(5_000_000.0, forKey: StorageKey.monthlyBudget)
        defaults.set("{\"food\":1000000}", forKey: StorageKey.categoryBudgets)
        let cloud = FakeCloud()
        cloud.values = [StorageKey.monthlyBudget: 5_000_000.0, StorageKey.categoryBudgets: "{\"food\":1000000}"]
        let settings = CloudSettings(defaults: defaults, cloud: cloud)
        settings.start()
        cloud.values = [StorageKey.monthlyBudget: 0.0]
        settings.pull(keys: [StorageKey.monthlyBudget, StorageKey.categoryBudgets])
        #expect(defaults.double(forKey: StorageKey.monthlyBudget) == 0)
        #expect(defaults.object(forKey: StorageKey.categoryBudgets) == nil)
        #expect(cloud.values[StorageKey.monthlyBudget] as? Double == 0)
        #expect(cloud.values[StorageKey.categoryBudgets] == nil)
    }

    /// Another device changed the name and erased the limit: both come down.
    @Test func changesFromAnotherDeviceComeDown() {
        let defaults = makeDefaults()
        defaults.set(5_000_000.0, forKey: StorageKey.monthlyBudget)
        defaults.set("Cũ", forKey: StorageKey.profileName)
        let cloud = FakeCloud()
        cloud.values = [StorageKey.profileName: "Mới"]
        CloudSettings(defaults: defaults, cloud: cloud)
            .pull(keys: [StorageKey.profileName, StorageKey.monthlyBudget])
        #expect(defaults.string(forKey: StorageKey.profileName) == "Mới")
        #expect(defaults.object(forKey: StorageKey.monthlyBudget) == nil)
    }

    /// The pill shows while data comes down, not while it goes up; a success is remembered.
    /// An import the pill never tracked (the network dropped in the middle of it) still has its
    /// data read once it ends (audit 2026-11-15).
    @Test func anImportEndingUnseenIsStillRead() {
        let monitor = CloudSyncMonitor(defaults: makeDefaults())
        let download = UUID()
        monitor.handle(.init(id: download, isImport: true, ended: false))
        #expect(monitor.isReceiving)
        monitor.setOffline(true)
        #expect(!monitor.isReceiving)
        let before = monitor.quietImports
        monitor.handle(.init(id: download, isImport: true, ended: true))
        #expect(monitor.quietImports == before + 1)
        #expect(monitor.takeNewData())
    }

    /// What records by itself waits for this launch's download (audit round 2, 2026-11-15: an
    /// old iPad recorded from its own copy, bringing back a payment deleted on the iPhone); not
    /// where none comes, and not past the time limit.
    @Test func autoRecordingWaitsForTheDownload() async {
        let monitor = CloudSyncMonitor(defaults: makeDefaults(), syncs: true)
        let since = ContinuousClock.now
        let waiting = Task { await monitor.waitForFreshData(since: since, timeout: .seconds(5)) }
        try? await Task.sleep(for: .milliseconds(300))
        let download = UUID()
        monitor.handle(.init(id: download, isImport: true, ended: false))
        monitor.handle(.init(id: download, isImport: true, ended: true))
        await waiting.value
        #expect(ContinuousClock.now - since < .seconds(2))

        let noICloud = CloudSyncMonitor(defaults: makeDefaults(), syncs: false)
        let asked = ContinuousClock.now
        await noICloud.waitForFreshData(since: asked, timeout: .seconds(5))
        #expect(ContinuousClock.now - asked < .milliseconds(200))

        let nothingComes = CloudSyncMonitor(defaults: makeDefaults(), syncs: true)
        let began = ContinuousClock.now
        await nothingComes.waitForFreshData(since: began, timeout: .milliseconds(600))
        #expect(ContinuousClock.now - began >= .milliseconds(600))
    }

    @Test func theMonitorShowsOnlyDataComingDown() {
        let monitor = CloudSyncMonitor(defaults: makeDefaults())
        let upload = UUID()
        monitor.handle(.init(id: upload, isImport: false, ended: false))
        #expect(!monitor.isReceiving)
        let download = UUID()
        monitor.handle(.init(id: download, isImport: true, ended: false))
        #expect(monitor.isReceiving)
        monitor.handle(.init(id: download, isImport: true, ended: true))
        #expect(!monitor.isReceiving)
        #expect(monitor.lastSynced != nil)
        #expect(monitor.problem == nil)
    }
}

/// When the sync pill shows and goes (`SyncPillTimeline`).
struct SyncPillTimelineTests {
    /// A quick sync shows nothing.
    @Test func aQuickSyncShowsNothing() {
        var timeline = SyncPillTimeline()
        #expect(timeline.receivingChanged(true) == .show)
        #expect(timeline.receivingChanged(false) == .none)
        #expect(timeline.shown == nil)
    }

    /// A long one: the spinner, then "Đã đồng bộ", then gone.
    @Test func aLongSyncShowsThenSaysDoneThenGoes() {
        var timeline = SyncPillTimeline()
        let show = timeline.receivingChanged(true)
        #expect(timeline.fired(show, receiving: true) == .giveUp)
        #expect(timeline.shown == .receiving)
        let settle = timeline.receivingChanged(false)
        #expect(settle == .settle)
        #expect(timeline.shown == .receiving)
        let hide = timeline.fired(settle, receiving: false)
        #expect(timeline.shown == .done)
        #expect(timeline.fired(hide, receiving: false) == .none)
        #expect(timeline.shown == nil)
    }

    /// A restore in rounds with gaps: the spinner stays through the gaps, then "Đã đồng bộ" once.
    @Test func roundsWithGapsDoNotFlip() {
        var timeline = SyncPillTimeline()
        _ = timeline.fired(timeline.receivingChanged(true), receiving: true)
        for _ in 0..<3 {
            #expect(timeline.receivingChanged(false) == .settle)
            #expect(timeline.shown == .receiving)
            #expect(timeline.receivingChanged(true) == .giveUp) // the next round, before the settle
            #expect(timeline.shown == .receiving)
        }
        let settle = timeline.receivingChanged(false)
        _ = timeline.fired(settle, receiving: false)
        #expect(timeline.shown == .done)
    }

    /// A round starting while "Đã đồng bộ" shows: back to the spinner, and still nothing left up.
    @Test func aRoundDuringDoneStillEndsWithNothingUp() {
        var timeline = SyncPillTimeline()
        _ = timeline.fired(timeline.receivingChanged(true), receiving: true)
        _ = timeline.fired(timeline.receivingChanged(false), receiving: false) // "Đã đồng bộ"
        #expect(timeline.receivingChanged(true) == .giveUp)
        #expect(timeline.shown == .receiving)
        let settle = timeline.receivingChanged(false)
        let hide = timeline.fired(settle, receiving: false)
        _ = timeline.fired(hide, receiving: false)
        #expect(timeline.shown == nil)
    }

    /// The network going while the spinner shows: "no network" at once, then gone, never "done".
    @Test func goingOfflineSaysSoAndGoes() {
        var timeline = SyncPillTimeline()
        _ = timeline.fired(timeline.receivingChanged(true), receiving: true)
        let hide = timeline.wentOffline()
        #expect(hide == .hide)
        #expect(timeline.shown == .offline)
        #expect(timeline.receivingChanged(false) == .hide)
        #expect(timeline.shown == .offline)
        _ = timeline.fired(hide, receiving: false)
        #expect(timeline.shown == nil)
    }

    /// The network going with nothing up: nothing shows.
    @Test func goingOfflineWithNothingUpShowsNothing() {
        var timeline = SyncPillTimeline()
        #expect(timeline.wentOffline() == .none)
        #expect(timeline.shown == nil)
    }

    /// A sync whose end is never heard: the spinner gives up.
    @Test func aSyncThatNeverEndsStillGoes() {
        var timeline = SyncPillTimeline()
        let giveUp = timeline.fired(timeline.receivingChanged(true), receiving: true)
        _ = timeline.fired(giveUp, receiving: true)
        #expect(timeline.shown == nil)
    }
}
