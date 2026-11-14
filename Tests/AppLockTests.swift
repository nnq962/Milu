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
        let start = ContinuousClock.now
        // Opened again before the minute: still open.
        appLock.didReturnForTest(unlocked: true)
        appLock.didLeave(now: start)
        appLock.didReturn(now: start + .seconds(30))
        #expect(!appLock.isLocked)
        // Away a minute and more: locked.
        appLock.didLeave(now: start)
        appLock.didReturn(now: start + .seconds(61))
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
        appLock.didReturn(now: .now + .seconds(600))
        #expect(!appLock.isLocked)
    }

    /// The switcher's cover while inactive: on with the lock, not over a system sheet Milu opened
    /// (Mail, Quản lý gói), and never on the free plan.
    @Test func coversWhileInactiveButNotOverASystemSheet() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: true, pro: true, delay: .immediately)
        #expect(appLock.coversWhileInactive())
        appLock.isShowingSystemSheet = true
        #expect(!appLock.coversWhileInactive())
        appLock.isShowingSystemSheet = false
        #expect(appLock.coversWhileInactive())
        let (free, _) = lock(on: true, pro: false)
        #expect(!free.coversWhileInactive())
    }

    /// Just after Face ID: no cover until the app is back in front, then covered again, however
    /// long that took (user reports 2026-11-14: a time limit both ran out too soon and never ended).
    @Test func noCoverJustAfterFaceIDUntilBackInFront() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: true, pro: true, delay: .immediately)
        appLock.markJustAskedForTest()
        #expect(!appLock.coversWhileInactive())
        appLock.didBecomeActive()
        #expect(appLock.coversWhileInactive())
    }
}
