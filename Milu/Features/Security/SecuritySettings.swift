import SwiftUI

/// "Bảo mật" in Cài đặt: "Khoá bằng Face ID", a Milu Pro feature (user request 2026-11-12). On the
/// free plan the row says so and opens what Pro is; on Pro it is a switch, asking Face ID once as
/// it is turned on, and with it when the app locks again.
struct SecuritySettings: View {
    /// The free plan's row: what Milu Pro is.
    let onShowPro: () -> Void

    @Environment(AppLock.self) private var lock
    @AppStorage(StorageKey.appLock) private var isOn = false
    @AppStorage(StorageKey.appLockDelay) private var delaySeconds = AppLock.Delay.immediately.rawValue
    @State private var isExplainingNoPasscode = false

    private var title: String { "Khoá bằng \(AppLock.biometryName)" }

    var body: some View {
        FormGroup(title: "Bảo mật") {
            if MiluPlan.isPro {
                FormToggleRow(title: title, subtitle: "Mở Milu bằng khuôn mặt hoặc mật mã iPhone",
                              icon: "hugeicons-square-lock-02", isOn: toggle)
                if isOn {
                    FormDivider()
                    FormPickerRow(title: "Khoá lại", icon: "hugeicons-clock-01",
                                  selection: Binding { AppLock.Delay(rawValue: delaySeconds) ?? .immediately }
                                      set: { delaySeconds = $0.rawValue },
                                  options: AppLock.Delay.allCases) { $0.title }
                }
            } else {
                Button(action: onShowPro) {
                    HStack(spacing: Spacing.s) {
                        FormRowLabel(title: title, subtitle: "Dành cho Milu Pro", icon: "hugeicons-square-lock-02")
                        Spacer(minLength: Spacing.s)
                        StatusBadge(title: "Pro", tone: .pro, showsDot: false)
                            .fixedSize()
                    }
                    .formRowFrame()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.row)
                .accessibilityHint("Xem Milu Pro")
            }
        }
        .animation(.easeOut(duration: 0.2), value: isOn)
        .onChange(of: isOn) { lock.refresh() }
        .systemAlert("iPhone chưa có mật mã", isPresented: $isExplainingNoPasscode) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Đặt mật mã và \(AppLock.biometryName) trong Cài đặt của iPhone để khoá Milu.")
        }
    }

    /// On only once Face ID (or the passcode) says it is the owner: a face not set up, or a "no"
    /// to Face ID, leaves it off rather than locking the user out later.
    private var toggle: Binding<Bool> {
        Binding {
            isOn
        } set: { on in
            guard on else {
                isOn = false
                return
            }
            guard AppLock.isAvailable else {
                isExplainingNoPasscode = true
                return
            }
            Task {
                if await AppLock.confirmTurningOn() { isOn = true }
            }
        }
    }
}
