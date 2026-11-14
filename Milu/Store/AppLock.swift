import Foundation
import LocalAuthentication
import UIKit
import Observation

/// What the user's plan allows: Milu Pro when the App Store says it is owned (`ProStore`, its last
/// answer kept in UserDefaults); Debug can also pretend (Cài đặt → Nhà phát triển).
enum MiluPlan {
    /// Cài đặt → Nhà phát triển → "Giả lập Milu Pro", in a Debug build only: the switch is kept
    /// in UserDefaults, and a Release build installed over a Debug one read it as Pro.
    static func pretends(_ stored: Bool) -> Bool {
        #if DEBUG
        stored
        #else
        false
        #endif
    }

    static var isPro: Bool {
        let defaults = UserDefaults.standard
        #if DEBUG
        if defaults.bool(forKey: StorageKey.debugPro) { return true }
        #endif
        return defaults.bool(forKey: StorageKey.proActive)
    }
}

/// "Khoá bằng Face ID", a Milu Pro feature (user request 2026-11-12): the app opens behind a lock
/// that Face ID, Touch ID or the iPhone's passcode lifts, on every launch and on coming back after
/// `delay`. While the app is not in front its content is covered, so the app switcher shows no
/// balance. Per device: never synced (another phone has its own face and passcode).
@MainActor
@Observable
final class AppLock {
    enum Delay: Int, CaseIterable, Identifiable {
        case immediately = 0, oneMinute = 60, fiveMinutes = 300

        var id: Self { self }

        var title: String {
            switch self {
            case .immediately: "Ngay lập tức"
            case .oneMinute: "Sau 1 phút"
            case .fiveMinutes: "Sau 5 phút"
            }
        }
    }

    private(set) var isLocked = false
    /// Asking Face ID now: the button waits rather than asking twice.
    private(set) var isAuthenticating = false
    /// Face ID has just answered (yes, or cancelled, failed) and the app is not yet back in front:
    /// the prompt leaves it inactive a moment longer, and the cover is not shown for that moment
    /// (user report 2026-11-12: after the scan the cover stayed a while before the app showed).
    /// Over once the app is active again (`didBecomeActive`), not after a time: on the iPhone that
    /// moment ran past a second, and the cover came up between the lock and the page. After a
    /// "no" too: the cover came over the lock as the prompt went, hiding its button, which then
    /// showed twice (user reports 2026-11-14).
    private(set) var isJustAsked = false
    /// A system screen Milu opened is up (the photo picker, Mail): it runs apart from the app and
    /// leaves it inactive, which is not the user leaving (user report 2026-11-12: the cover
    /// flickered over the photo picker the whole time).
    var isShowingSystemSheet = false

    @ObservationIgnored private let defaults: UserDefaults
    /// When the app went to the background, on the clock that keeps running while the phone
    /// sleeps and that changing the iPhone's time does not move: set back, the date let "Sau 1
    /// phút" never lock (review 2026-11-14).
    @ObservationIgnored private var leftAt: ContinuousClock.Instant?

    /// The app's lock: also for what asks iOS for something outside a view (dictation's microphone,
    /// the first recurring rule's notifications), so no cover comes over the prompt.
    static let shared = AppLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isLocked = isOn
    }

    /// Turned on, and the plan allows it: a free plan opens freely even if it was on.
    var isOn: Bool { MiluPlan.isPro && defaults.bool(forKey: StorageKey.appLock) }

    var delay: Delay {
        Delay(rawValue: defaults.integer(forKey: StorageKey.appLockDelay)) ?? .immediately
    }

    // MARK: Khi rời và quay lại

    /// The app went to the background.
    func didLeave(now: ContinuousClock.Instant = .now) {
        guard isOn, !isLocked else { return }
        leftAt = now
    }

    /// Back in front: locked again once away for `delay` or more. A Face ID prompt also makes the
    /// app inactive for a moment; it never went to the background, so that does not lock.
    func didReturn(now: ContinuousClock.Instant = .now) {
        guard isOn, let leftAt else { return }
        self.leftAt = nil
        if now - leftAt >= .seconds(delay.rawValue) { isLocked = true }
    }

    /// Whether the cover goes over the app while it is `inactive`: not while Face ID asks or just
    /// after it opened the app (the prompt's own inactive moment), else the app switcher.
    func coversWhileInactive() -> Bool {
        isOn && !isAuthenticating && !isShowingSystemSheet && !isJustAsked
    }

    /// Face ID answered: no cover for the prompt's own inactive moment. Already active (the
    /// prompt gone first): there is no such moment, and the next switcher is covered.
    private func markJustAsked() {
        isJustAsked = UIApplication.shared.applicationState != .active
    }

    /// iOS asking something over Milu (the notification permission): it leaves the app inactive,
    /// which is not leaving, so no cover over it or as it goes (user report 2026-11-14: the garden
    /// covered Cài đặt behind the notifications prompt).
    func whileSystemAsks<T>(_ ask: () async -> T) async -> T {
        isShowingSystemSheet = true
        let answer = await ask()
        isShowingSystemSheet = false
        markJustAsked()
        return answer
    }

    /// The app is in front again: the moment after Face ID is over.
    func didBecomeActive() {
        if isJustAsked { isJustAsked = false }
    }

    /// Turned off (or the plan lapsed): open at once.
    func refresh() {
        if !isOn { isLocked = false }
    }

    #if DEBUG
    /// Tests: as if Face ID had said yes.
    func didReturnForTest(unlocked: Bool) { if unlocked { isLocked = false } }
    /// Tests: as if Face ID had just answered with the app not yet back in front.
    func markJustAskedForTest() { isJustAsked = true }
    #endif

    // MARK: Mở khoá

    /// Face ID (or Touch ID), then the iPhone's passcode if it fails: never locked out of the app.
    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        // No passcode on the phone any more (taken off in iOS's Settings, Face ID with it):
        // nothing can say who holds it, and asking would keep the owner out of Milu for good
        // (review 2026-11-14). The phone itself is open, so Milu opens too.
        guard Self.isAvailable else {
            isLocked = false
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let yes = await Self.authenticate(reason: "Mở khoá Milu")
        markJustAsked()
        if yes { isLocked = false }
    }

    /// Asked as the switch is turned on, so a face that is not set up, or a "no" to Face ID,
    /// leaves it off instead of locking the user out later; and as it is turned off, so whoever
    /// holds the phone with Milu open cannot take the lock away (review 2026-11-14). As an
    /// unlock: the prompt's inactive moment, and the one after it, show no cover (user report
    /// 2026-11-14: the cover came up behind Cài đặt as the switch went on).
    func confirmOwner(turningOn: Bool) async -> Bool {
        isAuthenticating = true
        defer { isAuthenticating = false }
        let reason = turningOn ? "Bật khoá Milu bằng \(Self.biometryName)" : "Tắt khoá Milu"
        let yes = await Self.authenticate(reason: reason)
        markJustAsked()
        return yes
    }

    private static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }

    // MARK: Tên

    /// "Face ID", "Touch ID", or "mật mã" on a phone with neither.
    /// Asked once: a new `LAContext` on every draw of Cài đặt cost its sheet frames (Instruments on
    /// the iPhone 2026-11-13), and the kind of sensor does not change.
    static let biometryName: String = {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return switch context.biometryType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "mật mã"
        }
    }()

    /// The SF Symbol for the unlock button.
    static let biometrySymbol: String = {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return switch context.biometryType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        default: "lock.fill"
        }
    }()

    /// The phone has a passcode at least: without one nothing can lock the app.
    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}
