import Foundation
import LocalAuthentication
import Observation

/// What the user's plan allows: Milu Pro when the App Store says it is owned (`ProStore`, its last
/// answer kept in UserDefaults); Debug can also pretend (Cài đặt → Nhà phát triển).
enum MiluPlan {
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
    /// When Face ID last opened the app: the prompt leaves the app inactive a moment longer, and
    /// the cover is not shown over the app for that moment (user report 2026-11-12: after the
    /// scan the cover stayed a while before the app showed).
    private(set) var unlockedAt: Date?
    /// A system screen Milu opened is up (the photo picker, Mail): it runs apart from the app and
    /// leaves it inactive, which is not the user leaving (user report 2026-11-12: the cover
    /// flickered over the photo picker the whole time).
    var isShowingSystemSheet = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var leftAt: Date?

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
    func didLeave(now: Date = .now) {
        guard isOn, !isLocked else { return }
        leftAt = now
    }

    /// Back in front: locked again once away for `delay` or more. A Face ID prompt also makes the
    /// app inactive for a moment; it never went to the background, so that does not lock.
    func didReturn(now: Date = .now) {
        guard isOn, let leftAt else { return }
        self.leftAt = nil
        if now.timeIntervalSince(leftAt) >= TimeInterval(delay.rawValue) { isLocked = true }
    }

    /// Whether the cover goes over the app while it is `inactive`: not while Face ID asks or just
    /// after it opened the app (the prompt's own inactive moment), else the app switcher.
    func coversWhileInactive(now: Date = .now) -> Bool {
        guard isOn, !isAuthenticating, !isShowingSystemSheet else { return false }
        return unlockedAt.map { now.timeIntervalSince($0) > 1.5 } ?? true
    }

    /// Turned off (or the plan lapsed): open at once.
    func refresh() {
        if !isOn { isLocked = false }
    }

    #if DEBUG
    /// Tests: as if Face ID had said yes.
    func didReturnForTest(unlocked: Bool) { if unlocked { isLocked = false } }
    #endif

    // MARK: Mở khoá

    /// Face ID (or Touch ID), then the iPhone's passcode if it fails: never locked out of the app.
    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        if await Self.authenticate(reason: "Mở khoá Milu") {
            unlockedAt = .now
            isLocked = false
        }
    }

    /// Asked once as the switch is turned on, so a face that is not set up, or a "no" to Face ID,
    /// leaves it off instead of locking the user out later.
    static func confirmTurningOn() async -> Bool {
        await authenticate(reason: "Bật khoá Milu bằng \(biometryName)")
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
