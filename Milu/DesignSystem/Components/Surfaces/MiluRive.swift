import RiveRuntime
import SwiftUI

/// Than in Rive on a tab's head (user request 2026-11-13): the three characters of
/// output/03-animations, each with its own lifecycle script inside the file. The app only tells it
/// what is true (there is data, the page is on screen, dark, Reduce Motion) and what just happened
/// (a tap, a wallet or a transaction saved); the motion, the faces and the timing are the file's.
enum MiluRiveScene: String {
    case overview = "milu-overview"
    case accounts = "milu-accounts"
    case transactions = "milu-transactions"
}

/// What a page knows: whether it has anything yet, and how many of each thing, so a new one
/// (a count that grew while the page was open) becomes the file's "saved" event.
struct MiluRiveFacts: Equatable {
    var hasData: Bool
    /// Keyed by the file's own event names: "wallet", "jar" (Tài khoản); "expense", "income"
    /// (Giao dịch). Tổng quan has none.
    var counts: [String: Int] = [:]

    /// Tổng quan: anything at all recorded.
    @MainActor static func overview(_ store: FinanceStore) -> MiluRiveFacts {
        MiluRiveFacts(hasData: !store.transactions.isEmpty || !store.accounts.isEmpty)
    }

    /// Tài khoản: the wallets (cash, bank, e-wallet) and the jars still open.
    @MainActor static func accounts(_ store: FinanceStore) -> MiluRiveFacts {
        let wallets = AccountType.paymentTypes.reduce(0) { $0 + store.accounts(of: $1).count }
        let jars = store.activeGoals.count
        return MiluRiveFacts(hasData: wallets + jars > 0, counts: ["wallet": wallets, "jar": jars])
    }

    /// Giao dịch: the expenses and the incomes recorded.
    @MainActor static func transactions(_ store: FinanceStore) -> MiluRiveFacts {
        let expenses = store.transactions.filter { $0.kind == .expense }.count
        return MiluRiveFacts(hasData: !store.transactions.isEmpty,
                             counts: ["expense": expenses, "income": store.transactions.count - expenses])
    }
}

/// The loaded file and the view model instance bound to its state machine, kept so the app can
/// set its booleans and fire its triggers.
@MainActor
@Observable
final class MiluRiveCharacter {
    let scene: MiluRiveScene
    private(set) var rive: Rive?
    /// Its own drawing view, made once and kept: a tab shows this one, already set up and drawn
    /// (`park`), not a new one that needs a moment for Metal (user report 2026-11-13: a blink
    /// the first time each tab opened, none when it opened again).
    @ObservationIgnored private(set) var canvas: RiveUIView?
    /// The file could not load: the page shows Milu's still face instead.
    private(set) var loadFailed = false
    @ObservationIgnored private var instance: ViewModelInstance?
    @ObservationIgnored private var facts: MiluRiveFacts?
    @ObservationIgnored private var loading: Task<Void, Never>?
    /// When it last reacted (a tap, a save): a scroll then does not cut the reaction short.
    @ObservationIgnored private var reactedAt = Date.distantPast
    @ObservationIgnored private var nudgedAt = Date.distantPast

    /// One worker for the three characters: it owns the render thread and the GPU context.
    @ObservationIgnored private static var sharedWorker: Task<Worker, Error>?

    init(scene: MiluRiveScene) {
        self.scene = scene
    }

    /// The three, one each, made and loaded at launch so a tab opens with its character already
    /// there (user request 2026-11-13: no appearing).
    static let overview = MiluRiveCharacter(scene: .overview)
    static let accounts = MiluRiveCharacter(scene: .accounts)
    static let transactions = MiluRiveCharacter(scene: .transactions)

    /// From launch, with what the store holds and the look the app opens in.
    static func preload(_ store: FinanceStore) {
        let dark = switch AppAppearance.saved {
        case .dark: true
        case .light: false
        case .system: UITraitCollection.current.userInterfaceStyle == .dark
        }
        let reduced = UIAccessibility.isReduceMotionEnabled
        // Tổng quan first, the tab the app opens on; the other two after it.
        Task {
            await overview.load(.overview(store), dark: dark, reduced: reduced)
            await accounts.load(.accounts(store), dark: dark, reduced: reduced)
            await transactions.load(.transactions(store), dark: dark, reduced: reduced)
        }
    }

    /// Puts each loaded canvas not on a page yet just past the window's right edge, the size it
    /// will have, so it sets up and draws its first frames out of sight; a little later it pauses
    /// there. Called as each loads and once the window exists.
    static func park() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: \.isKeyWindow)
        else { return }
        let width = window.bounds.width * SkyHeader.MascotPlacement.rive.width / 402
        let height = width * MiluRiveHero.artboardSize.height / MiluRiveHero.artboardSize.width
        for character in [overview, accounts, transactions] {
            guard let canvas = character.canvas, canvas.superview == nil else { continue }
            canvas.frame = CGRect(x: window.bounds.maxX + 20, y: 0, width: width, height: height)
            canvas.isUserInteractionEnabled = false
            window.addSubview(canvas)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                if canvas.superview === window { canvas.isPaused = true }
            }
        }
    }

    /// Until Tổng quan's character is ready (or failed), at most `timeout`: the app holds its
    /// first page back for it, so Than is there when the page shows.
    static func overviewReady(timeout: Duration = .seconds(2)) async {
        let deadline = ContinuousClock.now + timeout
        while overview.rive == nil, !overview.loadFailed, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    /// The warm-up before the character shows: 30 steps of 0.1 s.
    private static let step: TimeInterval = 0.1
    private static let warmUpSteps = 30

    private static func worker() async throws -> Worker {
        if let sharedWorker { return try await sharedWorker.value }
        let task = Task { @MainActor in try await Worker() }
        sharedWorker = task
        return try await task.value
    }

    /// Loads the file once, binding its own default instance (the one the designer authored).
    func load(_ facts: MiluRiveFacts, dark: Bool, reduced: Bool) async {
        if let loading { return await loading.value }
        guard rive == nil, !loadFailed else { return }
        let task = Task { await loadFile(facts, dark: dark, reduced: reduced) }
        loading = task
        await task.value
    }

    private func loadFile(_ facts: MiluRiveFacts, dark: Bool, reduced: Bool) async {
        do {
            let file = try await File(source: .local(scene.rawValue, .main), worker: Self.worker())
            let artboard = try await file.createArtboard()
            let info = try await file.getDefaultViewModelInfo(for: artboard)
            let instance = try await file.createViewModelInstance(
                .name(info.instanceName, from: .artboardDefault(artboard)))
            let stateMachine = try await artboard.createStateMachine(binding: instance)
            self.instance = instance
            // Told what is true and run ahead out of sight before it shows, so it opens already
            // as the page is (user report 2026-11-13: every launch replayed "no data → data",
            // though the data had been there for long). One short step first lets the file's
            // script start and listen; then the page's facts; then about three seconds, the
            // script's own steps of at most a tenth, which settles the face and the pose.
            stateMachine.advance(by: Self.step)
            set("visible", true)
            set("dark", dark)
            set("reduced", reduced)
            start(with: facts)
            for _ in 0..<Self.warmUpSteps {
                stateMachine.advance(by: Self.step)
            }
            let rive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine,
                                      fit: .contain(alignment: .bottomCenter))
            let canvas = RiveUIView(rive: rive, isPaused: false)
            // 60 a second, not the screen's 120: breathing and blinking look the same, and the
            // pages scroll beside it with half the drawing (Instruments on the iPhone 2026-11-13).
            canvas.frameRate = .fps(60)
            self.canvas = canvas
            self.rive = rive
            Self.park()
        } catch {
            loadFailed = true
        }
    }

    /// The page as it is when the character first shows: seeded with what is there, no
    /// celebration for things that were already made.
    private func start(with facts: MiluRiveFacts) {
        self.facts = facts
        switch scene {
        case .overview:
            set("hasData", facts.hasData)
        case .accounts, .transactions:
            fire(facts.hasData ? "seed" : "reset")
        }
    }

    /// A change on the page: data that came or went, or a thing made while it was open.
    func update(_ new: MiluRiveFacts) {
        guard let old = facts, rive != nil else { return }
        facts = new
        switch scene {
        case .overview:
            if new.hasData != old.hasData { set("hasData", new.hasData) }
        case .accounts, .transactions:
            // The file reacts to a form saved: open it for that kind, then confirm, a frame apart
            // so the script sees them in order. The first of its kind celebrates.
            guard let kind = new.counts.first(where: { $0.value > old.counts[$0.key, default: 0] })?.key
            else { return }
            reactedAt = .now
            fire(kind)
            Task {
                try? await Task.sleep(for: .milliseconds(60))
                fire("confirm")
            }
        }
    }

    func pet() {
        reactedAt = .now
        fire("pet")
    }

    /// The page scrolled: Than wakes if it dozed off (user request 2026-11-13). Tổng quan's file
    /// has a trigger for it; the other two wake on any command, and "reopen" changes nothing
    /// else, so it is not sent while a reaction plays. At most once a second.
    func nudge() {
        let now = Date.now
        guard rive != nil, now.timeIntervalSince(nudgedAt) > 1 else { return }
        nudgedAt = now
        switch scene {
        case .overview:
            fire("activity")
        case .accounts, .transactions:
            guard now.timeIntervalSince(reactedAt) > 3 else { return }
            fire("reopen")
        }
    }

    /// Back on screen (the tab chosen again, the app back in front): awake, as a scroll or a tap
    /// would leave it. The same for the three (user request 2026-11-13): asleep after a while
    /// left alone, awake on a tap, a scroll or coming back.
    func wake() {
        guard rive != nil else { return }
        nudgedAt = .now
        fire(scene == .overview ? "activity" : "reopen")
    }

    func set(_ name: String, _ value: Bool) {
        instance?.setValue(of: BoolProperty(path: name), to: value)
    }

    func fire(_ name: String) {
        instance?.fire(trigger: TriggerProperty(path: name))
    }
}

/// The character on the head, in the frame the static faces had (`SkyHeader`), drawn from the
/// file's 787 × 400 artboard standing on its lower edge. Loaded at launch (`preload`), so it is
/// there when the tab opens, with no fade; if it cannot load, the page shows Milu's still face.
struct MiluRiveHero: View {
    let facts: MiluRiveFacts
    let character: MiluRiveCharacter

    /// True from the start: made paused, the view drew nothing for a frame or two when a tab
    /// opened (screen recording 2026-11-13); it only exists on screen, and leaving sets it false.
    @State private var isOnScreen = true
    /// Still on the screen as the page scrolls: scrolled away, it stops drawing (2026-11-13).
    @State private var isInView = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppLock.self) private var appLock: AppLock?

    /// The artboard's size (output/03-animations/manifest.json).
    static let artboardSize = CGSize(width: 786.928, height: 400)

    /// Not under the lock: drawing on behind it, Than took frames from the lock's own button as
    /// it came (user report 2026-11-14).
    private var isVisible: Bool {
        isOnScreen && isInView && scenePhase == .active && appLock?.isLocked != true
    }

    var body: some View {
        stage
            .onGeometryChange(for: Bool.self) { $0.frame(in: .global).maxY > 0 } action: { isInView = $0 }
            .aspectRatio(Self.artboardSize, contentMode: .fit)
            .contentShape(Rectangle())
            .onTapGesture(perform: pet)
            .modifier(Lifecycle(facts: facts, character: character, isOnScreen: $isOnScreen))
            .accessibilityElement()
            .accessibilityLabel("Milu")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Chạm để vuốt ve Milu")
    }

    @ViewBuilder private var stage: some View {
        if let canvas = character.canvas {
            KeptCanvas(canvas: canvas, isPaused: !isVisible)
                .allowsHitTesting(false)
        } else {
            Color.clear
        }
    }

    private func pet() {
        Haptics.selection()
        character.pet()
    }

    /// Loading once, then telling the file what changes: on screen or not, the page's data, dark,
    /// Reduce Motion.
    private struct Lifecycle: ViewModifier {
        let facts: MiluRiveFacts
        let character: MiluRiveCharacter
        @Binding var isOnScreen: Bool
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.scenePhase) private var scenePhase
        @Environment(AppLock.self) private var appLock: AppLock?

        /// Under the lock counts as away: opened, Than wakes as on coming back.
        private var isVisible: Bool { isOnScreen && scenePhase == .active && appLock?.isLocked != true }

        func body(content: Content) -> some View {
            content
                .task {
                    await character.load(facts, dark: colorScheme == .dark, reduced: reduceMotion)
                    // What may have changed since launch.
                    character.update(facts)
                    character.set("dark", colorScheme == .dark)
                    character.set("reduced", reduceMotion)
                }
                .onAppear { isOnScreen = true }
                .onDisappear { isOnScreen = false }
                .onChange(of: isVisible) { _, visible in
                    character.set("visible", visible)
                    if visible { character.wake() }
                }
                .onChange(of: facts) { _, new in character.update(new) }
                .onChange(of: colorScheme) { _, scheme in character.set("dark", scheme == .dark) }
                .onChange(of: reduceMotion) { _, reduced in character.set("reduced", reduced) }
        }
    }
}

/// Shows a character's kept canvas (`MiluRiveCharacter.canvas`) in a page, taking it from where it
/// was parked; pauses it while the page is away.
private struct KeptCanvas: UIViewRepresentable {
    let canvas: RiveUIView
    let isPaused: Bool

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
            host.addSubview(canvas)
        }
        canvas.isPaused = isPaused
    }
}
