import RiveRuntime
import SwiftUI

/// Than on the welcome pages (`milu-welcome.riv`, built from design/rive/milu-welcome-05): the
/// same rig and faces as the tabs' characters, on its own 787 × 400 artboard. The app says which
/// face and when to nod or hop; breathing, blinking and the morph between faces are the file's.
@MainActor
@Observable
final class WelcomeThan {
    /// The five faces the file draws, as its `face` number.
    enum Face: Float {
        case original = 0, friendly, curious, happy, wink

        /// The face of an avatar Milu offers on the last page.
        init(_ look: MiluHero.Look) {
            switch look {
            case .nguyenBan: self = .original
            case .toMo: self = .curious
            case .vui: self = .happy
            case .nhayMat: self = .wink
            default: self = .friendly
            }
        }
    }

    /// The artboard's size, as the tabs' (`MiluRiveHero.artboardSize`).
    static let artboardSize = CGSize(width: 786.928, height: 400)

    /// The one Than of the welcome, loaded as the app launches into it (`preload`), so it is
    /// set up and drawn by the time it first rises.
    static let shared = WelcomeThan()

    static func preload() {
        Task { await shared.load(face: .happy, reduced: UIAccessibility.isReduceMotionEnabled) }
    }

    /// Done with the welcome: its canvas and file let go; loaded again if it is shown again.
    func release() {
        loading?.cancel()
        loading = nil
        canvas = nil
        instance = nil
        loadFailed = false
    }

    private(set) var canvas: RiveUIView?
    /// The file could not load: the page shows Milu's still face instead.
    private(set) var loadFailed = false
    @ObservationIgnored private var instance: ViewModelInstance?
    @ObservationIgnored private var loading: Task<Void, Never>?
    @ObservationIgnored private var face = Face.happy

    /// Loads the file once, already wearing `face` and settled, so it shows as it should.
    func load(face: Face, reduced: Bool) async {
        if let loading { return await loading.value }
        guard canvas == nil, !loadFailed else { return }
        let task = Task { await loadFile(face: face, reduced: reduced) }
        loading = task
        await task.value
    }

    private func loadFile(face: Face, reduced: Bool) async {
        do {
            let file = try await File(source: .local("milu-welcome", .main), worker: MiluRiveCharacter.worker())
            let artboard = try await file.createArtboard()
            let info = try await file.getDefaultViewModelInfo(for: artboard)
            let instance = try await file.createViewModelInstance(
                .name(info.instanceName, from: .artboardDefault(artboard)))
            let stateMachine = try await artboard.createStateMachine(binding: instance)
            self.instance = instance
            // One step lets the file's script start and listen; then the face, and a second of
            // the script's own steps so the face has settled before it shows.
            stateMachine.advance(by: 0.1)
            // The face last asked for (the page may have set one while this loaded).
            set(self.face)
            instance.setValue(of: BoolProperty(path: "reduced"), to: reduced)
            for _ in 0..<12 { stateMachine.advance(by: 0.1) }
            let rive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine,
                                      fit: .contain(alignment: .bottomCenter))
            let canvas = RiveUIView(rive: rive, isPaused: false)
            // 60 a second, as the tabs' characters: breathing and blinking look the same.
            canvas.frameRate = .fps(60)
            self.canvas = canvas
        } catch {
            loadFailed = true
        }
    }

    func set(_ face: Face) {
        self.face = face
        instance?.setValue(of: NumberProperty(path: "face"), to: face.rawValue)
    }

    func setReduced(_ reduced: Bool) {
        instance?.setValue(of: BoolProperty(path: "reduced"), to: reduced)
    }

    func setVisible(_ visible: Bool) {
        instance?.setValue(of: BoolProperty(path: "visible"), to: visible)
        canvas?.isPaused = !visible
    }

    /// A small nod: something it likes happened (a transaction recorded).
    func nod() {
        instance?.fire(trigger: TriggerProperty(path: "nod"))
    }

    /// A little jump: an avatar chosen, or Than tapped.
    func hop() {
        instance?.fire(trigger: TriggerProperty(path: "hop"))
    }
}

/// The character's canvas in the stage, or its still face while the file loads or if it cannot.
struct WelcomeThanView: View {
    let than: WelcomeThan
    let face: WelcomeThan.Face

    var body: some View {
        Group {
            if let canvas = than.canvas {
                ThanCanvas(canvas: canvas)
            } else if than.loadFailed {
                // The still faces are the Figma crop: the artboard's lower 86%.
                Image(still.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            } else {
                Color.clear
            }
        }
        .aspectRatio(WelcomeThan.artboardSize, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var still: MiluHero.Look {
        switch face {
        case .original: .nguyenBan
        case .friendly: .thanThien
        case .curious: .toMo
        case .happy: .vui
        case .wink: .nhayMat
        }
    }
}

private struct ThanCanvas: UIViewRepresentable {
    let canvas: RiveUIView

    func makeUIView(context: Context) -> UIView {
        let host = UIView()
        host.backgroundColor = .clear
        host.isUserInteractionEnabled = false
        return host
    }

    func updateUIView(_ host: UIView, context: Context) {
        if canvas.superview !== host {
            canvas.frame = host.bounds
            canvas.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            canvas.backgroundColor = .clear
            host.addSubview(canvas)
        }
    }
}
