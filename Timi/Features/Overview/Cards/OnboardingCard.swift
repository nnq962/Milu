import SwiftUI

/// "Làm quen với Timi": the four first steps as cards in a row the finger swipes through (user
/// request 2026-11-08). Each card is one short row: the step's Fluent Flat picture, its name over
/// "+5 lượt AI", and a small button that does it; a done card keeps its place with "Đã nhận 5
/// lượt AI" and a green tick, so the row reads as a checklist of turns earned. The next card
/// peeks at the right edge so the row says it scrolls; dots under it say where the finger is.
/// The heading sits on the page over the row with "1/4" beside it. The row opens on the first
/// step not done, moves on by itself as one is done, and the section goes away once all four are.
struct OnboardingCard: View {
    enum Step: String, CaseIterable, Hashable {
        case account, transaction, loan, askAI

        /// The name its +5 is paid under (`AIQuota.claim`).
        var key: String { rawValue }

        var title: String {
            switch self {
            case .account: "Thêm tài khoản của bạn"
            case .transaction: "Ghi một khoản thu chi"
            case .loan: "Ghi một khoản cho vay"
            case .askAI: "Hỏi Milu một câu"
            }
        }

        var detail: String {
            switch self {
            case .account: "Ngân hàng, ví hay tiền mặt: Timi cộng lại thành tài sản của bạn."
            case .transaction: "Một ly cà phê cũng được, để Timi bắt đầu hiểu bạn."
            case .loan: "Ai đang nợ bạn? Timi nhắc giúp khi tới hạn."
            case .askAI: "Thử hỏi \"Tháng này tôi tiêu gì nhiều nhất?\""
            }
        }

        var action: String {
            switch self {
            case .account: "Thêm"
            case .transaction: "Ghi"
            case .loan: "Ghi"
            case .askAI: "Hỏi"
            }
        }

        /// The Fluent Emoji Flat picture (`MiluEmoji2D`, 2026-11-05).
        var picture: String {
            switch self {
            case .account: IconCatalog.emojiName("🏦")
            case .transaction: IconCatalog.emojiName("📝")
            case .loan: IconCatalog.emojiName("🤝")
            case .askAI: IconCatalog.emojiName("✨")
            }
        }
    }

    /// Does a step: opens what it asks for.
    let onStep: (Step) -> Void

    @Environment(AIQuota.self) private var quota
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The card in view; the dots follow it.
    @State private var current: Step?
    /// Opened on the first step not done once; coming back to the page keeps the card the user
    /// left it on (review 2026-11-08: it jumped back every time).
    @State private var hasOpened = false
    /// The step's picture, a row's 32 grown a little for a card; it grows with the words beside
    /// it, no more than 1.6 times (`RowMetrics.capped`).
    @ScaledMetric(relativeTo: .body) private var scaledPicture: CGFloat = Self.picture
    private static let picture: CGFloat = 40
    private var pictureSize: CGFloat { RowMetrics.capped(scaledPicture, base: Self.picture) }
    /// The done tick, a row glyph's 22 grown no more than 1.6 times.
    @ScaledMetric(relativeTo: .body) private var scaledTick: CGFloat = IconSize.rowGlyph
    private var tickSize: CGFloat { RowMetrics.capped(scaledTick, base: IconSize.rowGlyph) }

    /// How much of the next card shows at the right edge, past the page margin: enough to say the
    /// row goes on.
    private static let peek: CGFloat = Spacing.xxl
    private static let dot: CGFloat = 6
    private static let currentDot: CGFloat = 18

    /// All four done: the page animates the section away on this.
    static func isFinished(_ quota: AIQuota) -> Bool {
        Step.allCases.allSatisfy { quota.hasClaimed($0.key) }
    }

    /// Done once the user did it and its +5 was paid (`OnboardingRewards`). Not from what the app
    /// holds: the sample data ticked three steps on first launch, and paid 15 turns, for nothing
    /// the user did (user choice 2026-11-08: only what they do themselves).
    private func isDone(_ step: Step) -> Bool { quota.hasClaimed(step.key) }

    private var firstUndone: Step? { Step.allCases.first { !isDone($0) } }

    /// The first step not done after `step`, going round to the start.
    private func nextUndone(after step: Step?) -> Step? {
        let all = Step.allCases
        let start = step.flatMap { all.firstIndex(of: $0) } ?? -1
        let order = all[(start + 1)...] + all[...max(start, 0)]
        return order.first { !isDone($0) }
    }

    var body: some View {
        let steps = Step.allCases
        let doneCount = steps.filter(isDone).count
        if doneCount < steps.count {
            OutsideHeaderSection(title: "Làm quen với Timi") {
                Text("\(doneCount)/\(steps.count)")
                    .textRole(.captionStrong)
                    .monospacedDigit()
                    .foregroundStyle(Palette.secondaryLabel)
                    .accessibilityLabel("Đã xong \(doneCount) trên \(steps.count) bước")
            } content: {
                // The dots hang in the gap under the cards, 8 below them, so the section keeps
                // the page's 28 to the next heading (review 2026-11-08: it was 46).
                row(steps)
                    .overlay(alignment: .bottom) {
                        dots(steps)
                            .offset(y: Spacing.s + Self.dot)
                    }
            }
            .transition(.opacity)
        }
    }

    /// The cards side by side, one page wide less the peek, each snapping to the page's edge.
    private func row(_ steps: [Step]) -> some View {
        let doneCount = steps.filter(isDone).count
        return ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.m) {
                    ForEach(steps, id: \.self) { step in
                        card(step)
                            .containerRelativeFrame(.horizontal) { width, _ in max(width - Self.peek, 0) }
                            .id(step)
                    }
                }
                // Every card as tall as the tallest, so the buttons stand on one line.
                .fixedSize(horizontal: false, vertical: true)
                .scrollTargetLayout()
                // Room after the last card, so it too can snap to the page's edge like the others
                // (review 2026-11-08: it stopped short, the one before showing on the left). Not
                // `contentMargins`, which narrowed every card by as much.
                .padding(.trailing, Self.peek)
            }
            .scrollTargetBehavior(.viewAligned)
            // Read at the row's middle, where the card in view always is.
            .scrollPosition(id: $current, anchor: .center)
            .scrollIndicators(.hidden)
            // The cards run on past the page margin to the screen's edge, so the next one peeks.
            .scrollClipDisabled()
            // Moved in code with the card's leading edge on the page's, where a swipe snaps it:
            // setting `current` would place it by the reading anchor (centre), 12 off (review
            // 2026-11-08). Opens on the first step not done; moves on as one is done.
            .onAppear {
                guard !hasOpened else { return }
                hasOpened = true
                if let first = firstUndone { proxy.scrollTo(first, anchor: .leading) }
            }
            // On to the next step not done after the card in view, round to the start, never
            // back past where the user is (review 2026-11-08: from card 4 it slid back to card 1
            // only after going round).
            // Only when the card in view is the one just done: a step done elsewhere (an expense
            // from the tab bar's +) left the user's card where it was (review 2026-11-08).
            .onChange(of: doneCount) {
                if let current, !isDone(current) { return }
                guard let next = nextUndone(after: current) else { return }
                withAnimation(reduceMotion ? nil : .smooth) { proxy.scrollTo(next, anchor: .leading) }
            }
        }
    }

    /// One row (user request 2026-11-08: shorter still): the picture, the name over what it pays,
    /// and a small button on the right. Done: "Đã nhận 5 lượt AI" in green where the reward was,
    /// a green tick where the button was, so the card says the turns came in. Why the step matters
    /// is read by VoiceOver; on screen the name says enough.
    private func card(_ step: Step) -> some View {
        let done = isDone(step)
        return AdaptiveStack(alignment: .center, spacing: Spacing.m, stackedSpacing: Spacing.s) {
            // The picture and words as one element for VoiceOver, the button its own.
            AdaptiveStack(alignment: .center, spacing: Spacing.m, stackedSpacing: Spacing.s) {
                Image(step.picture)
                    .resizable()
                    .scaledToFit()
                    .frame(width: pictureSize, height: pictureSize)
                    .saturation(done ? 0 : 1)
                    .opacity(done ? 0.5 : 1)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(step.title)
                        .textRole(.bodyStrong)
                        .foregroundStyle(done ? Palette.secondaryLabel : Palette.label)
                        .fixedSize(horizontal: false, vertical: true)
                    // The green tick on the right already says done; no second tick here.
                    Text(done ? "Đã nhận 5 lượt AI" : "+5 lượt AI")
                        .textRole(.captionStrong)
                        .foregroundStyle(done ? Palette.progressDone : Palette.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(done ? "\(step.title), đã xong, đã nhận 5 lượt AI"
                                     : "\(step.title). \(step.detail). Thưởng 5 lượt AI")
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: tickSize, height: tickSize)
                    .foregroundStyle(Palette.progressDone)
                    .accessibilityHidden(true)
            } else {
                // Read as the step's name (not "Thêm, Thêm tài khoản…"); Voice Control still
                // answers to the word on it.
                TimiButton(step.action, role: .primary, size: .compact) { onStep(step) }
                    .fixedSize()
                    .accessibilityLabel(step.title)
                    .accessibilityInputLabels([step.action, step.title])
            }
        }
        .padding(RowMetrics.horizontal)
        .frame(maxHeight: .infinity)
        .cardSurface()
    }

    /// Where the finger is: the card in view a longer dash, the steps done in their ink. Only a
    /// sign, not buttons: at 6 tall they were too small to tap (review 2026-11-08); VoiceOver
    /// reads the cards themselves.
    private func dots(_ steps: [Step]) -> some View {
        HStack(spacing: Spacing.xs + 2) {
            ForEach(steps, id: \.self) { step in
                let isCurrent = step == (current ?? firstUndone)
                Capsule()
                    .fill(isCurrent ? Palette.primary : isDone(step) ? Palette.progressDone.opacity(0.5) : Palette.progressTrack)
                    .frame(width: isCurrent ? Self.currentDot : Self.dot, height: Self.dot)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: current)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

/// Pays a first step's +5 the moment the user does it, wherever: a new account, income or expense,
/// or loan lent made by the user (`FinanceStore.lastCreated`, set only on those paths, so the
/// sample data, a restored account, a balance correction or a loan switched to lending pay
/// nothing), or a first question to Milu. Sits on the app's root, so a step done on another tab
/// counts while Tổng quan is not on screen.
struct OnboardingRewards: ViewModifier {
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false

    func body(content: Content) -> some View {
        content
            .onChange(of: store.lastCreated) { _, created in
                guard let created else { return }
                let step: OnboardingCard.Step = switch created.kind {
                case .account: .account
                case .transaction: .transaction
                case .lentLoan: .loan
                }
                quota.claim(step.key)
            }
            // Asking is the user's own doing even from before this rule, so it counts at launch too.
            .onChange(of: hasAskedAI, initial: true) { _, asked in
                if asked { quota.claim(OnboardingCard.Step.askAI.key) }
            }
    }
}
