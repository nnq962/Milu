import Foundation
import Testing
@testable import Milu

/// "Khoá bằng Face ID": when the app locks, and that the free plan never does.
@MainActor
@Suite(.serialized)
struct AppLockTests {
    private func lock(on: Bool, pro: Bool, delay: AppLock.Delay = .oneMinute) -> (AppLock, UserDefaults) {
        let defaults = UserDefaults(suiteName: "AppLockTests")!
        defaults.removePersistentDomain(forName: "AppLockTests")
        defaults.set(on, forKey: StorageKey.appLock)
        defaults.set(delay.rawValue, forKey: StorageKey.appLockDelay)
        UserDefaults.standard.set(pro, forKey: StorageKey.debugPro)
        return (AppLock(defaults: defaults), defaults)
    }

    @Test func locksFromLaunchAndAfterTheDelay() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: true, pro: true)
        #expect(appLock.isLocked)
        let start = Date(timeIntervalSince1970: 1_000_000)
        // Opened again before the minute: still open.
        appLock.didReturnForTest(unlocked: true)
        appLock.didLeave(now: start)
        appLock.didReturn(now: start.addingTimeInterval(30))
        #expect(!appLock.isLocked)
        // Away a minute and more: locked.
        appLock.didLeave(now: start)
        appLock.didReturn(now: start.addingTimeInterval(61))
        #expect(appLock.isLocked)
    }

    /// A Face ID prompt makes the app inactive for a moment, never backgrounded: no lock.
    @Test func comingBackWithoutLeavingDoesNotLock() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: true, pro: true, delay: .immediately)
        appLock.didReturnForTest(unlocked: true)
        appLock.didReturn(now: .now)
        #expect(!appLock.isLocked)
    }

    @Test func theFreePlanNeverLocks() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: true, pro: false, delay: .immediately)
        #expect(!appLock.isLocked)
        appLock.didLeave(now: .now)
        appLock.didReturn(now: .now.addingTimeInterval(600))
        #expect(!appLock.isLocked)
    }
}
