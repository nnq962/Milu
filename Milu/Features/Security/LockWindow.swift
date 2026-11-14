import SwiftUI
import UIKit

/// The lock and the app switcher's cover, in a window of their own above the app's (user report
/// 2026-11-14). Drawn over the app's root, they sat under any sheet open at the time: Cài đặt
/// stayed on top, could be scrolled and changed, and the cover showed only behind it.
@MainActor
@Observable
final class LockCurtain {
    /// The scene's phase, from UIKit's scene notifications (`LockWindowInstaller`).
    var phase: ScenePhase = .active
}

/// Put once in the app's view tree: on joining its window, it adds the lock's window to the same
/// scene.
struct LockWindowInstaller: UIViewRepresentable {
    let lock: AppLock
    let curtain: LockCurtain

    func makeUIView(context: Context) -> Probe {
        Probe(lock: lock, curtain: curtain)
    }

    func updateUIView(_ view: Probe, context: Context) {}

    final class Probe: UIView {
        private let lock: AppLock
        private let curtain: LockCurtain
        private var lockWindow: UIWindow?

        init(lock: AppLock, curtain: LockCurtain) {
            self.lock = lock
            self.curtain = curtain
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard lockWindow == nil, let scene = window?.windowScene else { return }
            let window = UIWindow(windowScene: scene)
            // Above sheets and alerts, which live in the app's window.
            window.windowLevel = .alert + 1
            window.backgroundColor = .clear
            window.overrideUserInterfaceStyle = AppAppearance.saved.style
            let root = UIViewController()
            root.view.backgroundColor = .clear
            let host = UIHostingController(rootView: LockLayer(lock: lock, curtain: curtain))
            host.view.backgroundColor = .clear
            root.addChild(host)
            host.view.frame = root.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            root.view.addSubview(host.view)
            host.didMove(toParent: root)
            // The cover as a picture: UIKit shows it in the same moment it is asked, before iOS
            // takes the switcher's picture; a SwiftUI view could be a frame late. Drawn only with
            // the lock on (`prepareCover`): most never turn it on, and drawing it cost the launch.
            let cover = UIImageView()
            cover.frame = root.view.bounds
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cover.contentMode = .scaleAspectFill
            cover.isHidden = true
            root.view.addSubview(cover)
            window.rootViewController = root
            lockWindow = window
            coverView = cover
            watch(scene)
            prepareCover()
            follow()
        }

        /// The cover's picture, drawn once the lock is on: at launch, and each time the app is in
        /// front (the lock may have been turned on since), so it is ready before it is needed.
        private func prepareCover() {
            guard lock.isOn, let coverView, coverView.image == nil,
                  let scene = lockWindow?.windowScene else { return }
            coverView.image = Self.coverPicture(size: scene.coordinateSpace.bounds.size,
                                                scale: scene.traitCollection.displayScale)
        }

        /// The scene's phase from UIKit, as it changes: SwiftUI's did not always say the app had
        /// gone inactive (the Face ID prompt as the lock was turned on), and the cover then never
        /// came up over the switcher (user report 2026-11-14).
        private func watch(_ scene: UIWindowScene) {
            let center = NotificationCenter.default
            let events: [(Notification.Name, @MainActor (Probe) -> Void)] = [
                (UIScene.willDeactivateNotification, { $0.set(.inactive) }),
                (UIScene.didEnterBackgroundNotification, { probe in
                    probe.lock.didLeave()
                    probe.set(.background)
                }),
                (UIScene.willEnterForegroundNotification, { probe in
                    // Locked again (if away long enough) as it starts coming back, while the cover
                    // is still up, so the cover gives way to the lock at once.
                    probe.lock.didReturn()
                    probe.set(.inactive)
                }),
                (UIScene.didActivateNotification, { probe in
                    probe.prepareCover()
                    probe.lock.didBecomeActive()
                    probe.lock.didReturn()
                    probe.set(.active)
                }),
            ]
            for (name, act) in events {
                observers.append(center.addObserver(forName: name, object: scene, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        guard let self else { return }
                        act(self)
                    }
                })
            }
        }

        private func set(_ phase: ScenePhase) {
            curtain.phase = phase
            follow()
            lockWindow?.rootViewController?.view.layoutIfNeeded()
        }

        /// Shows the window while there is something to show, hides it after: watched here, not
        /// from the view inside it, which a hidden window did not always update.
        private func follow() {
            let (shows, covers) = withObservationTracking {
                (LockLayer.shows(lock: lock, phase: curtain.phase),
                 LockLayer.covers(lock: lock, phase: curtain.phase))
            } onChange: { [weak self] in
                Task { @MainActor [weak self] in self?.follow() }
            }
            guard let lockWindow else { return }
            // Over the lock too while Milu is not in front: the lock is still being drawn under it.
            if covers { prepareCover() }
            coverView?.isHidden = !covers
            let behind = lockWindow.windowScene?.windows.filter { $0 !== lockWindow } ?? []
            if lock.isLocked {
                // The keyboard closed: it lives in a window above any of the app's, and stayed up
                // over the lock, typing into the field behind it (review 2026-11-14).
                behind.forEach { $0.endEditing(true) }
            }
            // VoiceOver reads the lock (or nothing) and not the balances behind it.
            lockWindow.accessibilityViewIsModal = shows
            behind.forEach { $0.accessibilityElementsHidden = shows }
            hiding?.cancel()
            if shows {
                lockWindow.isHidden = false
            } else if !lockWindow.isHidden {
                // After the fade, so it is seen going; hidden, it takes no touches.
                hiding = Task { @MainActor [weak lockWindow] in
                    try? await Task.sleep(for: .seconds(LockLayer.fade + 0.05))
                    guard !Task.isCancelled else { return }
                    lockWindow?.isHidden = true
                }
            }
        }

        private static func coverPicture(size: CGSize, scale: CGFloat) -> UIImage? {
            let renderer = ImageRenderer(content: PrivacyCover()
                .frame(width: size.width, height: size.height)
                .environment(\.locale, .vietnam))
            renderer.scale = scale
            return renderer.uiImage
        }

        private var coverView: UIImageView?
        private var observers: [NSObjectProtocol] = []
        private var hiding: Task<Void, Never>?
    }
}

/// What the lock's window shows: the lock while locked; else, with the lock on and Milu not in
/// front, the cover, so the app switcher's picture shows no balance.
struct LockLayer: View {
    let lock: AppLock
    let curtain: LockCurtain

    /// Quick: the face is already known, the app should be there at once.
    static let fade: Double = 0.2

    static func shows(lock: AppLock, phase: ScenePhase) -> Bool {
        lock.isLocked || covers(lock: lock, phase: phase)
    }

    static func covers(lock: AppLock, phase: ScenePhase) -> Bool {
        lock.isOn && (phase == .background || (phase == .inactive && lock.coversWhileInactive()))
    }

    var body: some View {
        let phase = curtain.phase
        ZStack {
            // The cover is a picture over this, in UIKit (`LockWindowInstaller`).
            if lock.isLocked {
                LockScreen(lock: lock)
                    .transition(.opacity)
            }
        }
        // Only the way in fades: the lock comes up at once, over the cover it takes the place
        // of, so nothing behind shows between them.
        .animation(lock.isLocked ? nil : .easeOut(duration: Self.fade), value: lock.isLocked)
        .environment(\.scenePhase, phase)
        .environment(\.locale, .vietnam)
        .font(TextRole.body.font)
    }
}
