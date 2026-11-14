import SwiftUI

/// The four welcome pages (Figma "Chào mừng · Bản 05 · Trưng bày sản phẩm", 824:3568).
enum WelcomePage: Int, CaseIterable {
    case meet, record, assistant, profile
}

/// The stage over each page (user choice 2026-11-14, "Trưng bày sản phẩm"): one sky for all four,
/// and on it the app's own pieces, Than peeking from behind them. Drawn on Figma's 370 × 404
/// (236 on the last page) and scaled to the room it has; decorative, so out of VoiceOver.
///
/// Each page's pieces come in on their own as the page opens, in the beats of the approved Rive
/// demo (design/rive/milu-welcome-05); the page leaving fades. Than is one character moving from
/// page to page.
struct WelcomeStage: View {
    let page: WelcomePage
    let than: WelcomeThan
    /// The face of the avatar chosen on the last page.
    let avatarFace: WelcomeThan.Face
    /// Figma's 370 points to the screen's.
    let scale: CGFloat
    /// "Vào Milu" was tapped: Than is happy.
    let finishing: Bool

    static let size = CGSize(width: 370, height: 404)
    static let profileHeight: CGFloat = 236
    /// Figma's 32: the stage sits 16 in from the screen's edge.
    static let radius: CGFloat = 32

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    /// Than's bottom centre in the stage and its width.
    @State private var place = ThanPlace(x: 185, y: 450, width: 300)
    @State private var thanShown = false
    /// The page Than is on: it keeps its face while it ducks out of the last one.
    @State private var thanPage = WelcomePage.meet
    /// The page whose pieces are on the stage: leaving page 2, they stay until Than has hidden
    /// behind the chart (user request 2026-11-14: the cards went first and showed Than's flat
    /// base).
    @State private var scenePage = WelcomePage.meet
    @State private var sceneShown: Double = 1
    /// Page 2: the row was just recorded, Than is pleased for a moment.
    @State private var pleased = false
    /// Each move's number: a late step of an earlier move (page 1's wait) does nothing.
    @State private var moves = 0

    private var height: CGFloat { page == .profile ? Self.profileHeight : Self.size.height }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Palette.sky, Palette.surfaceMuted], startPoint: .top, endPoint: .bottom)
                .frame(height: height)
            // Moved by an offset, not laid out again: the canvas only slides, every frame alike.
            WelcomeThanView(than: than, face: face)
                .frame(width: ThanPlace.baseWidth, height: ThanPlace.baseHeight)
                .scaleEffect(place.width / ThanPlace.baseWidth, anchor: .bottom)
                .offset(x: place.x - ThanPlace.baseWidth / 2, y: place.y - ThanPlace.baseHeight)
                .opacity(thanShown ? 1 : 0)
            scene
                .id(scenePage)
                .opacity(sceneShown)
        }
        // Laid out at its full height, cut by a shape whose own height animates: cutting the
        // frame as it shrank (page 4), the cut was a plain rectangle for a moment, its lower
        // corners square (user report 2026-11-14).
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .clipShape(StageShape(height: height))
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: Self.size.width * scale, height: height * scale, alignment: .topLeading)
        .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.86), value: page)
        // The pieces are drawn at the size Figma has them, whatever the text size: they are a
        // picture of the app, read by no one.
        .dynamicTypeSize(.large)
        .accessibilityHidden(true)
        .onChange(of: page, initial: true) { _, page in move(to: page) }
        .onChange(of: face, initial: true) { _, face in than.set(face) }
        .onChange(of: scenePhase) { _, phase in than.setVisible(phase == .active) }
        .onChange(of: reduceMotion) { _, reduced in than.setReduced(reduced) }
        .task { await than.load(face: face, reduced: reduceMotion) }
    }

    private var face: WelcomeThan.Face {
        if finishing { return .happy }
        switch thanPage {
        case .meet: return .happy
        case .record: return pleased ? .happy : .curious
        case .assistant: return .friendly
        case .profile: return avatarFace
        }
    }

    @ViewBuilder private var scene: some View {
        switch scenePage {
        case .meet: MeetScene()
        case .record: RecordScene { recorded() }
        case .assistant: ChatScene()
        case .profile: ProfileScene()
        }
    }

    /// Than's place on each page, from Figma: the rig's bottom centre and its width.
    private static func target(_ page: WelcomePage) -> ThanPlace? {
        switch page {
        // On the stage's lower edge, the jars above (option B, user choice 2026-11-14): Than has
        // no body, so its flat base always rests on an edge, never in the open sky.
        case .meet: ThanPlace(x: 185, y: 404, width: 300)
        case .record: ThanPlace(x: 245.2, y: 86.7, width: 198.4)
        case .assistant: nil
        case .profile: ThanPlace(x: 185, y: 236, width: 320)
        }
    }

    /// Page to page: Than goes first, ducking down behind the edge it rests on (the stage's
    /// lower edge, or the chart while the cards are still there); the last page's pieces fade;
    /// then the next page's come and Than rises at its new place from behind that page's edge.
    /// Its flat base never crosses the open sky (user reports 2026-11-14: a body-less dog in
    /// mid-air looked cut off; leaving page 2 the cards went first and showed it).
    private func move(to page: WelcomePage) {
        pleased = false
        moves += 1
        let move = moves
        let target = Self.target(page)
        var instant = Transaction()
        instant.disablesAnimations = true
        if reduceMotion {
            withTransaction(instant) {
                if let target { place = target }
                thanShown = target != nil
                thanPage = page
                scenePage = page
                sceneShown = 1
            }
            return
        }
        Task { @MainActor in
            if thanShown {
                let behindChart = thanPage == .record
                withAnimation(.easeIn(duration: Self.duck)) {
                    place.y = behindChart ? Self.entry(.record, place).y : place.y + Self.height(place.width) + 8
                }
                // Off an edge, the pieces may fade with it; the chart waits until it is behind.
                if !behindChart, scenePage != page {
                    withAnimation(.easeOut(duration: Self.sceneFade)) { sceneShown = 0 }
                }
                try? await Task.sleep(for: .seconds(Self.duck))
                guard moves == move else { return }
                withTransaction(instant) { thanShown = false }
            }
            if scenePage != page {
                // Faded by its opacity, then swapped: a view's removal did not animate here.
                if sceneShown > 0 {
                    withAnimation(.easeOut(duration: Self.sceneFade)) { sceneShown = 0 }
                    try? await Task.sleep(for: .seconds(Self.sceneFade))
                    guard moves == move else { return }
                }
                withTransaction(instant) {
                    scenePage = page
                    sceneShown = 1
                }
            } else if sceneShown < 1 {
                // Back to the page whose pieces were going: they come back.
                withAnimation(.easeOut(duration: Self.sceneFade)) { sceneShown = 1 }
            }
            let began = ContinuousClock.now
            guard let target else { return }
            // Drawn and ready before it rises: a canvas set up mid-rise hitched (2026-11-14).
            await than.load(face: face, reduced: reduceMotion)
            guard moves == move else { return }
            // Placed out of sight, still unseen: behind the chart it would show through it
            // while the chart is still coming in.
            withTransaction(instant) {
                place = Self.entry(page, target)
                thanPage = page
            }
            try? await Task.sleep(until: began + .seconds(Self.entryDelay(page)), clock: .continuous)
            guard moves == move else { return }
            withTransaction(instant) { thanShown = true }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) { place = target }
        }
    }

    /// How long the last page's pieces take to fade.
    private static let sceneFade: Double = 0.18

    /// Than's artboard height at a width: as tall as it can show.
    private static func height(_ width: CGFloat) -> CGFloat {
        width * WelcomeThan.artboardSize.height / WelcomeThan.artboardSize.width
    }

    /// How long Than takes to duck out of sight, under an edge or behind the chart.
    private static let duck: Double = 0.2

    /// Where Than starts rising from, wholly out of sight: under the stage's lower edge by its
    /// own height, or on page 2 behind the chart (user report 2026-11-14: starting 24 points
    /// under the edge, most of it was already there and it popped up).
    private static func entry(_ page: WelcomePage, _ target: ThanPlace) -> ThanPlace {
        var start = target
        start.y = page == .record ? target.y + 110 : max(target.y, size.height) + height(target.width) + 8
        return start
    }

    /// From the page's opening. Page 1: once the jars are up; page 2: once the chart in front of
    /// it is solid, so it is never seen through it.
    private static func entryDelay(_ page: WelcomePage) -> Double {
        switch page {
        case .meet: 0.42
        case .record: 0.65
        case .assistant, .profile: 0.2
        }
    }

    private func recorded() {
        than.nod()
        pleased = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            pleased = false
        }
    }
}

/// The stage's outline: Figma's rounded rectangle, `height` tall from the top, animatable.
private struct StageShape: Shape {
    var height: CGFloat

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height),
             cornerRadius: WelcomeStage.radius, style: .continuous)
    }
}

/// Where Than stands: the bottom centre of its 787 × 400 artboard and the width it is drawn at.
struct ThanPlace: Equatable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat

    static let baseWidth: CGFloat = 320
    static let baseHeight = baseWidth * WelcomeThan.artboardSize.height / WelcomeThan.artboardSize.width
}

// MARK: - Shared pieces

/// A soft shadow under the pieces floating on the stage: the brand's deep blue in light, black
/// in dark, as Figma's.
private struct StageFloat: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(color: colorScheme == .dark ? .black.opacity(0.35) : Palette.deep.opacity(0.14), radius: 14, y: 12)
    }
}

private extension View {
    func stageFloat() -> some View { modifier(StageFloat()) }

    /// Waits `seconds` then runs `beat` with `animation`, or at once without it under Reduce Motion.
    func beat(_ seconds: Double, _ animation: Animation, reduced: Bool, _ change: @escaping () -> Void) -> some View {
        task {
            if reduced { change(); return }
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            withAnimation(animation) { change() }
        }
    }
}

/// Than's words on the stage, as on Figma: white, the deep blue, a soft shadow.
private struct StageBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .textRole(.button)
            .foregroundStyle(Palette.deep)
            .fixedSize()
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Palette.surface, in: Capsule())
            .shadow(color: Palette.deep.opacity(0.1), radius: 10, y: 8)
    }
}

private let pop = Animation.spring(response: 0.42, dampingFraction: 0.62)
private let rise = Animation.spring(response: 0.5, dampingFraction: 0.82)

// MARK: - 1 · Gặp Milu

/// Three of the app's jars, the middle one first, the other two fanning out from behind it; then
/// Than's greeting.
private struct MeetScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var middle = false
    @State private var sides = false
    @State private var greeting = false

    private struct Jar {
        let goal: SavingsGoal
        let water: Int
        let x: CGFloat
        let y: CGFloat
        let angle: Double
    }

    private static let jars = [
        Jar(goal: SavingsGoal(name: "Hũ tiết kiệm", icon: IconCatalog.emojiName("💰"), saved: 28_000_000, target: 40_000_000),
            water: 0, x: 72, y: 128, angle: -7),
        Jar(goal: SavingsGoal(name: "Du lịch Đà Nẵng", icon: IconCatalog.emojiName("🧳"), saved: 8_000_000, target: 20_000_000),
            water: 2, x: 298, y: 128, angle: 7),
        Jar(goal: SavingsGoal(name: "Mua xe", icon: IconCatalog.emojiName("🚗"), saved: 15_000_000, target: 50_000_000),
            water: 1, x: 185, y: 112, angle: 0),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Self.jars.indices, id: \.self) { index in
                let jar = Self.jars[index]
                let isMiddle = jar.angle == 0
                let shown = isMiddle ? middle : sides
                GoalJar(goal: jar.goal, water: Palette.jarWater(at: jar.water))
                    .frame(width: 114)
                    .fixedSize(horizontal: false, vertical: true)
                    .stageFloat()
                    .scaleEffect(0.88 * (shown ? 1 : 0.9))
                    .rotationEffect(.degrees(shown ? jar.angle : 0))
                    .position(x: shown ? jar.x : 185, y: jar.y + (shown ? 0 : 40))
                    .opacity(shown ? 1 : 0)
                    // Afloat once up, each on its own beat.
                    .modifier(Bob(isOn: shown && !reduceMotion, delay: Double(index) * 0.7))
            }
            StageBubble(text: "Gâu! Chào bạn nha")
                .scaleEffect(greeting ? 1 : 0.85, anchor: .bottomTrailing)
                .opacity(greeting ? 1 : 0)
                .frame(width: 352, alignment: .trailing)
                .offset(y: 254)
        }
        .frame(width: WelcomeStage.size.width, height: WelcomeStage.size.height, alignment: .topLeading)
        .beat(0.02, rise, reduced: reduceMotion) { middle = true }
        .beat(0.16, .spring(response: 0.55, dampingFraction: 0.68), reduced: reduceMotion) { sides = true }
        .beat(0.95, pop, reduced: reduceMotion) { greeting = true }
    }
}

/// A slow rise and fall of a few points, for the jars floating over Than.
private struct Bob: ViewModifier {
    let isOn: Bool
    let delay: Double
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .offset(y: up ? -3 : 0)
            .onChange(of: isOn, initial: true) { _, on in
                guard on, !up else { return }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.6 + delay)) { up = true }
            }
    }
}

// MARK: - 2 · Ghi chép

/// The chart rises and its bars grow; the day's list in front takes one more row, its total
/// rolling up, as the transactions page does it.
private struct RecordScene: View {
    let onRecorded: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chart = false
    @State private var bars = false
    @State private var list = false
    @State private var recorded = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            WelcomeChart(grown: bars)
                .frame(width: 360, height: 236)
                .scaleEffect(0.88, anchor: .topLeading)
                .offset(x: 27, y: 60 + (chart ? 0 : 24))
                .opacity(chart ? 1 : 0)
            day
                .frame(width: 338)
                .offset(y: list ? 0 : 18)
                .opacity(list ? 1 : 0)
                .frame(width: WelcomeStage.size.width, height: WelcomeStage.size.height - 14, alignment: .bottom)
        }
        .frame(width: WelcomeStage.size.width, height: WelcomeStage.size.height, alignment: .topLeading)
        .beat(0.04, rise, reduced: reduceMotion) { chart = true }
        .beat(0.32, .spring(response: 0.5, dampingFraction: 0.6), reduced: reduceMotion) { bars = true }
        .beat(0.18, rise, reduced: reduceMotion) { list = true }
        .beat(1.0, .smooth(duration: 0.45), reduced: reduceMotion) {
            recorded = true
            onRecorded()
        }
    }

    /// Today's card as on Giao dịch: the day and its total over the rows.
    private var day: some View {
        OutsideHeaderSection(title: Date.now.transactionDayTitle) {
            MoneyText(amount: recorded ? 100_000 : 45_000, size: .caption, tone: .outflow)
                .contentTransition(.numericText())
        } content: {
            VStack(spacing: 0) {
                ListRow(icon: IconCatalog.emojiName("🍚"), title: "Ăn trưa", subtitle: "Cơm trưa văn phòng",
                        trailingSubtitle: "12:15", amount: 45_000, amountTone: .outflow, showsChevron: false)
                if recorded {
                    RowDivider()
                    ListRow(icon: IconCatalog.emojiName("☕"), title: "Cà phê", subtitle: "Cà phê Highlands",
                            trailingSubtitle: "08:15", amount: 55_000, amountTone: .outflow, showsChevron: false)
                        .transition(.unfold)
                }
            }
            .listCard()
        }
        .padding(.top, 14)
        .padding([.horizontal, .bottom], Spacing.m)
        .background(Palette.background, in: RoundedRectangle(cornerRadius: CardCorners.card + Spacing.xs, style: .continuous))
        .stageFloat()
    }
}

/// "Chi theo ngày" as the design system draws it with a history (Figma 64:898, 360 × 236): this
/// week's days, Thursday the most.
private struct WelcomeChart: View {
    let grown: Bool

    private static let bars: [(day: String, height: CGFloat)] = [
        ("T2", 42), ("T3", 0), ("T4", 26.25), ("T5", 63), ("T6", 0), ("T7", 15.75), ("CN", 10.5),
    ]

    var body: some View {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
        ZStack(alignment: .topLeading) {
            Text("Chi theo ngày")
                .textRole(.title)
                .foregroundStyle(Palette.label)
                .offset(x: 16, y: 12)
            Text("\(start.dayMonth)–\(Date.now.dayMonth)")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .frame(width: 328, alignment: .trailing)
                .offset(x: 16, y: 15)
            Text(150_000.0.vnd)
                .textRole(.amountLarge)
                .foregroundStyle(Palette.label)
                .offset(x: 16, y: 44)
            axis("60.000đ", at: Self.top)
            axis("0đ", at: Self.base)
            ForEach(Self.bars.indices, id: \.self) { index in
                let bar = Self.bars[index]
                let centre = 98 + CGFloat(index) * 38
                if bar.height > 0 {
                    UnevenRoundedRectangle(topLeadingRadius: CardCorners.mark, topTrailingRadius: CardCorners.mark, style: .continuous)
                        .fill(Palette.primary)
                        .frame(width: 20, height: bar.height)
                        .scaleEffect(x: 1, y: grown ? 1 : 0.001, anchor: .bottom)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(index) * 0.06), value: grown)
                        .offset(x: centre - 10, y: Self.base - bar.height)
                }
                Text(bar.day)
                    .textRole(.footnote)
                    .foregroundStyle(Palette.secondaryLabel)
                    .frame(width: 34)
                    .offset(x: centre - 17, y: Self.base + 7)
            }
            Text("Thứ Năm chi nhiều nhất, 60.000đ.")
                .textRole(.caption)
                .foregroundStyle(Palette.label)
                .offset(x: 16, y: 199)
        }
        .frame(width: 360, height: 236, alignment: .topLeading)
        .cardSurface()
        .stageFloat()
    }

    private static let top: CGFloat = 96
    private static let base: CGFloat = 159

    /// A level's figure on the left and its line across.
    @ViewBuilder private func axis(_ label: String, at y: CGFloat) -> some View {
        Text(label)
            .textRole(.footnote)
            .foregroundStyle(Palette.secondaryLabel)
            .frame(width: 55, alignment: .trailing)
            .offset(x: 16, y: y - 9)
        Rectangle()
            .fill(Palette.separator)
            .frame(width: 264, height: 1)
            .offset(x: 79, y: y)
    }
}

// MARK: - 3 · Trợ lý AI

/// The chat as the app draws it: the field listening, the words flying up into the user's bubble,
/// Milu typing, then its answer with the recorded transaction and its two buttons.
private struct ChatScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var field = false
    @State private var listening = false
    @State private var said = false
    @State private var sender = false
    @State private var answered = false
    @State private var tools = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // The chat's bubble, drawn in SwiftUI: `UserBubble`'s UIKit words were measured again
            // as it flew up, and it showed "Sáng nay" alone, off to the right, for a moment
            // (user report 2026-11-14).
            Text("Sáng nay cà phê 35k nha")
                .textRole(.body)
                .foregroundStyle(Palette.onPrimary)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, Bubble.userInset.leading)
                .padding(.vertical, Bubble.userInset.top)
                .background(Palette.primary, in: Bubble.userShape)
                .scaleEffect(said ? 1 : 0.86, anchor: .bottomTrailing)
                .opacity(said ? 1 : 0)
                .frame(width: 354, alignment: .trailing)
                .offset(y: 20 + (said ? 0 : 182))
            VStack(alignment: .leading, spacing: Spacing.s) {
                AssistantSender()
                    .opacity(sender ? 1 : 0)
                if answered {
                    answer
                        .transition(.asymmetric(insertion: .scale(scale: 0.92, anchor: .topLeading).combined(with: .opacity),
                                                removal: .opacity))
                } else if sender {
                    TypingDots()
                        .frame(height: ControlHeight.small / 2 + Spacing.xs)
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.m)
                        .background { Bubble.assistantShape }
                        .transition(.opacity)
                }
                buttons
                    .offset(y: tools ? 0 : 10)
                    .opacity(tools ? 1 : 0)
            }
            .frame(width: 306, alignment: .leading)
            .offset(x: 16, y: 82)
            VoiceField(listening: listening)
                .frame(width: 338)
                .offset(x: 16, y: 332 + (field ? 0 : 20))
                .opacity(field ? 1 : 0)
        }
        .frame(width: WelcomeStage.size.width, height: WelcomeStage.size.height, alignment: .topLeading)
        .beat(0.04, rise, reduced: reduceMotion) { field = true }
        .beat(0.35, .linear(duration: 0), reduced: reduceMotion) { listening = !reduceMotion }
        .beat(1.55, .spring(response: 0.5, dampingFraction: 0.74), reduced: reduceMotion) {
            listening = false
            said = true
        }
        .beat(2.0, .easeOut(duration: 0.25), reduced: reduceMotion) { sender = true }
        .beat(2.95, .spring(response: 0.42, dampingFraction: 0.7), reduced: reduceMotion) { answered = true }
        .beat(3.3, rise, reduced: reduceMotion) { tools = true }
    }

    /// Milu's answer bubble: the words, then the transaction it recorded, as `MessageRow`.
    private var answer: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Mình ghi rồi nha!")
                .textRole(.body)
                .foregroundStyle(Palette.label)
            ListRow(icon: IconCatalog.emojiName("☕"), title: "Cà phê", subtitle: "Cà phê sáng",
                    trailingSubtitle: Date.now.dayMonth, amount: 35_000, amountTone: .outflow, showsChevron: false)
                .cardSurface(radius: CardCorners.card, color: Palette.surfaceMuted, outlined: false)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { Bubble.assistantShape }
    }

    /// "Xem" and "Xoá" under a recorded transaction, as the chat's flat capsules.
    private var buttons: some View {
        HStack(spacing: Spacing.s) {
            chatButton("Xem", icon: "hugeicons-eye", color: Palette.label)
            chatButton("Xoá", icon: "hugeicons-delete-02", color: Palette.negative)
        }
    }

    private func chatButton(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            MiluIcon(icon, size: RowMetrics.inlineGlyph)
            Text(title)
        }
        .textRole(.captionStrong)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
        .background(Palette.fill, in: Capsule())
    }
}

/// The chat's field while it listens: ✕, the voice as a line of dots, ■, and ↑ on the blue disc.
private struct VoiceField: View {
    let listening: Bool

    private static let button = ControlHeight.small

    var body: some View {
        HStack(spacing: Spacing.s) {
            round("xmark")
            ListeningDots(listening: listening)
                .frame(height: Self.button)
            round("stop.fill")
            Image(systemName: "arrow.up")
                .font(.system(size: IconSize.bar, weight: .semibold))
                .foregroundStyle(Palette.onPrimary)
                .frame(width: Self.button, height: Self.button)
                .background(Palette.primary, in: Circle())
        }
        .padding(Spacing.s)
        .background(Palette.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.separator, lineWidth: 1))
        .stageFloat()
    }

    private func round(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: IconSize.inline + 2, weight: .semibold))
            .foregroundStyle(Palette.label)
            .frame(width: Self.button, height: Self.button)
            .background(Palette.fill, in: Circle())
    }
}

/// The voice as `VoiceWaveform` draws it: dots 3 wide every 6 points, the newest on the right,
/// growing into bars with the voice, the oldest fading out on the left. A made-up voice here.
private struct ListeningDots: View {
    let listening: Bool
    @State private var startedAt = Date.now

    var body: some View {
        TimelineView(.animation(paused: !listening)) { timeline in
            let elapsed = listening ? timeline.date.timeIntervalSince(startedAt) : 0
            Canvas { context, size in
                let count = Int(size.width / 6)
                for index in 0..<count {
                    // `index` 0 is the newest, on the right.
                    let tau = elapsed - Double(index) * 0.045
                    var height: CGFloat = 3
                    if listening, tau > 0, tau < 1.2 {
                        let envelope = sin(.pi * tau / 1.2)
                        let voice = 0.25 + 0.75 * abs(sin(tau * 13.1 + Double(index) * 0.3) * sin(tau * 5.7 + 1.1))
                        height = 3 + 22 * envelope * voice
                    }
                    let x = size.width - 3 - CGFloat(index) * 6
                    let rect = CGRect(x: x, y: (size.height - height) / 2, width: 3, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(Palette.label))
                }
            }
        }
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.2),
                                   .init(color: .black, location: 0.94), .init(color: .clear, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        }
        .onChange(of: listening) { _, now in if now { startedAt = .now } }
    }
}

// MARK: - 4 · Tên & avatar

/// Than's hello over the smaller stage; the name and the avatars are in the page below.
private struct ProfileScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hello = false

    var body: some View {
        StageBubble(text: "Rất vui được gặp bạn!")
            .scaleEffect(hello ? 1 : 0.85, anchor: .bottomLeading)
            .opacity(hello ? 1 : 0)
            .frame(width: 354, alignment: .trailing)
            .offset(y: 22)
            .frame(width: WelcomeStage.size.width, height: WelcomeStage.profileHeight, alignment: .topLeading)
            .beat(0.55, pop, reduced: reduceMotion) { hello = true }
    }
}
