import Foundation
import Testing
@testable import Milu

/// "Khoá bằng Face ID": when the app locks, and that only Face ID opens it.
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

    /// The plan lapsing, or seeming to (the iPhone's date moved past its end), never opens the
    /// lock: not the one that is up, not the next launch's (audit 2026-11-15, and its round 2: a
    /// relaunch opened it). Only Face ID does, and on the free plan that also turns it off.
    @Test func aLapsedPlanDoesNotOpenTheLock() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, defaults) = lock(on: true, pro: true, delay: .immediately)
        #expect(appLock.isLocked)
        UserDefaults.standard.set(false, forKey: StorageKey.debugPro)
        appLock.refresh()
        #expect(appLock.isLocked)
        // Killed and launched again on the "free" plan: still locked.
        let relaunched = AppLock(defaults: defaults)
        #expect(relaunched.isLocked)
        // Opened with Face ID: the switch goes off, and it does not lock again.
        relaunched.didReturnForTest(unlocked: true)
        #expect(!defaults.bool(forKey: StorageKey.appLock))
        relaunched.didLeave(now: .now)
        relaunched.didReturn(now: .now + .seconds(5))
        #expect(!relaunched.isLocked)
        #expect(!AppLock(defaults: defaults).isLocked)
    }

    /// The switch itself turned off: open at once. On Pro, an unlock leaves the switch on.
    @Test func turningTheSwitchOffOpensAtOnce() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, defaults) = lock(on: true, pro: true, delay: .immediately)
        appLock.didReturnForTest(unlocked: true)
        #expect(defaults.bool(forKey: StorageKey.appLock))
        let other = AppLock(defaults: defaults)
        #expect(other.isLocked)
        defaults.set(false, forKey: StorageKey.appLock)
        other.refresh()
        #expect(!other.isLocked)
    }

    /// A Face ID prompt makes the app inactive for a moment, never backgrounded: no lock.
    @Test func comingBackWithoutLeavingDoesNotLock() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: true, pro: true, delay: .immediately)
        appLock.didReturnForTest(unlocked: true)
        appLock.didReturn(now: .now)
        #expect(!appLock.isLocked)
    }

    /// The switch off: never locks, whatever the plan.
    @Test func theSwitchOffNeverLocks() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: false, pro: true, delay: .immediately)
        #expect(!appLock.isLocked)
        appLock.didLeave(now: .now)
        appLock.didReturn(now: .now + .seconds(600))
        #expect(!appLock.isLocked)
        #expect(!appLock.coversWhileInactive())
    }

    /// The switcher's cover while inactive: on with the lock, not over a system sheet Milu opened
    /// (Mail, Quản lý gói), and never with the switch off.
    @Test func coversWhileInactiveButNotOverASystemSheet() {
        defer { UserDefaults.standard.removeObject(forKey: StorageKey.debugPro) }
        let (appLock, _) = lock(on: true, pro: true, delay: .immediately)
        #expect(appLock.coversWhileInactive())
        appLock.isShowingSystemSheet = true
        #expect(!appLock.coversWhileInactive())
        appLock.isShowingSystemSheet = false
        #expect(appLock.coversWhileInactive())
        let (off, _) = lock(on: false, pro: true)
        #expect(!off.coversWhileInactive())
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
