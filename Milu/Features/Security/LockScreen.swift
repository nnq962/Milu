import SwiftUI

/// Over the whole app while it is locked (`AppLock`): Milu, its finger on its lips, and the one
/// button that asks Face ID again. Asks by itself as it shows.
struct LockScreen: View {
    let lock: AppLock

    @Environment(\.scenePhase) private var scenePhase
    /// Went to the background since: back, it asks again. Not on the inactive moment the Face ID
    /// prompt itself brings, or a cancelled prompt would come straight back.
    @State private var wasAway = false

    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            Image(MiluHero.Look.ngaiNgung.image)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .accessibilityHidden(true)
            VStack(spacing: Spacing.s) {
                Text("Milu đang khoá")
                    .textRole(.pageTitle)
                    .accessibilityAddTraits(.isHeader)
                Text("Mở khoá để xem số liệu của bạn.")
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .multilineTextAlignment(.center)
            Spacer()
            MiluButton(role: .primary, fullWidth: true) {
                Task { await lock.unlock() }
            } label: {
                Label("Mở khoá bằng \(AppLock.biometryName)", systemImage: AppLock.biometrySymbol)
            }
            .disabled(lock.isAuthenticating)
            .padding(.horizontal, Spacing.page)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background.ignoresSafeArea())
        .foregroundStyle(Palette.label)
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
        ZStack {
            Palette.background
            Image(MiluHero.Look.ngaiNgung.image)
                .resizable()
                .scaledToFit()
                .frame(width: 140)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
