import SwiftUI

/// Over the whole app while it is locked (`AppLock`): the splash scene saying so, and the one
/// button that asks Face ID again. Asks by itself as it shows.
struct LockScreen: View {
    let lock: AppLock

    @Environment(\.scenePhase) private var scenePhase
    /// Went to the background since: back, it asks again. Not on the inactive moment the Face ID
    /// prompt itself brings, or a cancelled prompt would come straight back.
    @State private var wasAway = false
    /// Face ID was asked and did not open the app (cancelled, failed): the button is needed now.
    /// Before, while Face ID asks by itself, the lock is the splash and the cover exactly, with
    /// no button: it came up as the app opened, but flashed by when coming back from the
    /// background, two ways to open (user report 2026-11-14).
    @State private var needsButton = false

    var body: some View {
        // The splash itself, still, with its own line, and the one button in the sky once it is
        // needed: opening, away and locked look the same (user choice 2026-11-14).
        SplashScreen(greets: false) {
            MiluButton(role: .primary, fullWidth: true) {
                Task { await ask(waiting: false) }
            } label: {
                Label("Mở khoá bằng \(AppLock.biometryName)", systemImage: AppLock.biometrySymbol)
            }
            // Not `disabled`: greyed while Face ID asked, it turned back as the lock faded on the
            // way in, a flash (user report 2026-11-14). It only ignores taps meanwhile.
            .allowsHitTesting(needsButton && !lock.isAuthenticating)
            // Kept in its place, unseen, so the words stand where the splash has them.
            .opacity(needsButton ? 1 : 0)
            .accessibilityHidden(!needsButton)
        }
        // Asked as it shows, and on coming back to it; the button comes if that was cancelled.
        .task { await ask(waiting: true) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                // Back, Face ID asks again with no button, as on any opening.
                wasAway = true
                needsButton = false
            }
            if phase == .active, wasAway {
                wasAway = false
                Task { await ask(waiting: true) }
            }
        }
    }

    /// Face ID now; the button once it did not open the app.
    private func ask(waiting: Bool) async {
        // A beat, so the prompt comes over the page rather than over the launch.
        if waiting { try? await Task.sleep(for: .seconds(0.3)) }
        // Already asking (a second call): that one's answer decides.
        guard !lock.isAuthenticating else { return }
        await lock.unlock()
        guard lock.isLocked, !needsButton else { return }
        // Once the prompt has gone (Milu back in front), simply there, with no motion: shown as
        // "Huỷ" was let go, it came under the prompt still closing (user report 2026-11-14), and
        // every way of bringing it in stuttered on the iPhone.
        for _ in 0..<60 where UIApplication.shared.applicationState != .active {
            try? await Task.sleep(for: .milliseconds(16))
        }
        guard lock.isLocked else { return }
        needsButton = true
    }
}

/// While Milu is not in front with the lock on: the app switcher's picture shows this, not the
/// balances.
struct PrivacyCover: View {
    var body: some View {
        // Milu's splash, still: the garden, "Milu" and Than (user request 2026-11-14).
        SplashScreen(greets: false)
            .accessibilityHidden(true)
    }
}
