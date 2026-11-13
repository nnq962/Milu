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
        let cloud = FakeCloud()
        cloud.values = [StorageKey.profileName: "Cũ"]
        let settings = CloudSettings(defaults: defaults, cloud: cloud)
        defaults.set(5_000_000.0, forKey: StorageKey.monthlyBudget)
        defaults.set("dark", forKey: StorageKey.appearance)
        settings.push()
        #expect(cloud.values[StorageKey.monthlyBudget] as? Double == 5_000_000)
        #expect(cloud.values[StorageKey.profileName] == nil)
        #expect(cloud.values[StorageKey.appearance] == nil)
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
