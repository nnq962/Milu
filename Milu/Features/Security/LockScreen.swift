import SwiftUI

/// Over the whole app while it is locked (`AppLock`): the splash scene saying so, and the one
/// button that asks Face ID again. Asks by itself as it shows.
struct LockScreen: View {
    let lock: AppLock

    @Environment(\.scenePhase) private var scenePhase
    /// Went to the background since: back, it asks again. Not on the inactive moment the Face ID
    /// prompt itself brings, or a cancelled prompt would come straight back.
    @State private var wasAway = false

    var body: some View {
        // The splash's garden, "Milu" and Than, still, saying it is locked, with the one button
        // in the sky: opening, away and locked look the same (user choice 2026-11-14).
        SplashScreen(greets: false, caption: "Milu đang khoá. Mở khoá để xem số liệu.") {
            MiluButton(role: .primary, fullWidth: true) {
                Task { await lock.unlock() }
            } label: {
                Label("Mở khoá bằng \(AppLock.biometryName)", systemImage: AppLock.biometrySymbol)
            }
            .disabled(lock.isAuthenticating)
        }
        // Asked as it shows, and on coming back to it; the button is there if that was cancelled.
        .task { await ask() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { wasAway = true }
            if phase == .active, wasAway {
                wasAway = false
                Task { await ask() }
            }
        }
    }

    private func ask() async {
        // A beat, so the prompt comes over the page rather than over the launch.
        try? await Task.sleep(for: .seconds(0.3))
        await lock.unlock()
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
