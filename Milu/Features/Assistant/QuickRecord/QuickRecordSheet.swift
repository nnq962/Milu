import SwiftUI

/// "Thêm bằng AI" from the +: a small sheet that listens at once, and records without the chat
/// (user design 2026-11-17). While one speaks only the wave shows; a pause of two seconds sends
/// the recording (`DictationAutoStop`, as in the chat) and the server's words come into the card
/// (user choice 2026-11-18, over the phone's own words shown as they were said); the answer
/// comes in the same sheet: the receipt card
/// to check and "Lưu", a question back with answers to tap, or, plainly, what Milu cannot record
/// yet with the form to do it by hand. Saved, it says so and closes by itself.
///
/// What is said or typed goes in one card, as a chat's field (`composer`, the redesign of
/// 2026-11-18): the hint or the field, and under it in the card the mic or the keyboard, the
/// wave, the one main action; sent, the card closes to the words and "Milu đang soạn" under them,
/// as tall as they are.
///
/// It gives the model the record tool alone, so it never takes a lượt and never answers a
/// question from no figures: a question is sent to the chat instead. Nothing here is kept in the
/// chat history (user choice 2026-11-17); what is saved is in Giao dịch as any transaction.
struct QuickRecordSheet: View {
    /// What to open once the sheet has gone: a form, or the chat with the sentence.
    let onNext: (QuickRecordNext) -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    /// The sheet it is in (`BottomPanel`): its own close, and the screen at full rate for a step.
    @Environment(\.panelControl) private var panelControl
    @State private var dictation = SpeechDictation()
    @State private var phase = Phase.listening
    /// The user's last words, over the answer.
    @State private var said = ""
    @State private var typed = ""
    /// Why the mic is not used, over the field to type in.
    @State private var note: String?
    /// This sheet's exchange so far, for an answer to a question back; never saved.
    @State private var history: [ChatMessage] = []
    @State private var answering: Task<Void, Never>?
    @State private var closing: Task<Void, Never>?
    @State private var editingRow: AssistantView.EditingRow?
    @FocusState private var isTyping: Bool
    /// The voice on its way to words, from ■ or a pause until the server's come: the card has
    /// none yet, and says "Đang chuyển thành chữ".
    @State private var transcribing = false
    /// Milu's question being answered, kept over the card (user request 2026-11-18: tapping 🎤
    /// to answer, the question went, and its items with it).
    @State private var asked: String?
    /// The card being changed by words (user request 2026-11-19: once it showed, a wrong amount
    /// meant its form or the whole sentence again): it stays over the field while one says what to
    /// change, and comes back as it was should Milu not change it.
    @State private var fixing: Fixing?
    /// Under the card's bar, why the words did not change it.
    @State private var fixNote: String?
    /// The words `fixNote` answers, quoted over it.
    @State private var fixWords: String?
    /// The words said and the question move from one step to the next rather than blinking.
    @Namespace private var flow
    /// The one curve of a step from one state to the next, the sheet's height with it: no
    /// bounce, as iOS's own sheet moves.
    static let step = Animation.smooth(duration: 0.4)

    /// The card as it was when one began to change it, and the exchange that made it.
    struct Fixing {
        let draft: TransactionDraft
        let note: String?
        /// The sentence over it.
        let said: String
        let history: [ChatMessage]
    }

    enum Phase: Equatable {
        case listening
        case typing
        case thinking
        case result(QuickRecordResult)
        case saved(count: Int)
        case failed(String)
        case heardNothing
    }

    /// The native sheet's height (`fitSheet`): its one detent, and the one it slides from.
    @State private var sheetHeight: CGFloat?
    @State private var slidingFrom: CGFloat?
    /// A slide waits for this step's layouts (`fitSheet`); when the last one ends.
    @State private var isFitting = false
    @State private var slideEnds: CFTimeInterval = 0
    /// What is over the field, and the navigation bar over it.
    @State private var upperHeight: CGFloat = 0
    @State private var barHeight: CGFloat?
    /// The small field's box while one types: the words' height, reached on a curve.
    @State private var fieldBox: CGFloat = ControlHeight.small
    /// Milu's last answer that is not a card, with the words it answers: over the field until
    /// the next answer takes its place, through the next sentence said or typed (`upper`).
    @State private var last: Held?
    /// The sheet up and laid out, a moment after it appears: until then its height is taken
    /// as found, and nothing is held (`fitSheet`, `inner`).
    @State private var settled = false
    /// The keyboard, and the room iOS gives the content (`innerHeight`).
    @State private var keyboard = Keys.down
    @State private var given: CGFloat = 0
    /// What is over the field is too long for the screen, and scrolls (`upperArea`).
    @State private var upperScrolls = false
    /// The field held in place while the sheet slides (`hold`): by how much, since when.
    @State private var keyBegan: CFTimeInterval = 0
    @State private var keyShift: CGFloat = 0
    @State private var keyTick = 0

    struct Held {
        let result: Phase
        let said: String
    }

    var body: some View {
        Group {
            if panelControl != nil {
                // The app's own sheet (`BottomPanel`, DEBUG `MILU_QUICK_PANEL`): its height is the
                // content's, every step moving it in the same frame as what is in it.
                BottomPanel(title: "Thêm bằng AI", anchorsBottom: fixing != nil) {
                    VStack(alignment: .leading, spacing: Spacing.l) {
                        content
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frameProbe("step", value: stepNumber)
                }
            } else {
                nativeSheet
            }
        }
        .animation(Motion.gentle(Self.step), value: phase)
        // The server's words in: they fade into the card, "Milu đang soạn" under them, the card
        // and the sheet opening together as a long sentence comes.
        .animation(Motion.gentle(Self.step), value: transcribing)
        // Each step at the screen's full rate, fades too (`BottomPanel.moving`).
        .onChange(of: stepNumber) { panelControl?.moving() }
        // Milu's answer kept for `upper` until the next one; the field's box back to one line
        // once one no longer types, on the curve it opened on.
        .onChange(of: phase) { old, new in
            Self.trace("phase \(String(describing: old).prefix(24)) -> \(String(describing: new).prefix(24)) words \(headerWords ?? "-") upper \(upperHeight)")
            switch new {
            case .result(.card), .saved: last = nil
            case .result, .failed: last = Held(result: new, said: said)
            default: break
            }
            if new != .typing, fieldBox != Self.fieldButton { fieldBox = Self.fieldButton }
        }
        .onAppear {
            listen()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(800))
                settled = true
            }
        }
        #if DEBUG
        .task { await runDemo() }
        #endif
        .onDisappear {
            dictation.stop()
            answering?.cancel()
            closing?.cancel()
        }
        // Said and paused, or out of time: sent; nothing said: the mic goes off and says so.
        .onChange(of: dictation.autoEnd) { _, end in
            guard let end, dictation.isRecording else { return }
            switch end {
            case .paused, .timeUp: finishListening()
            case .nothingSaid:
                dictation.stop()
                phase = .heardNothing
            }
        }
        // The mic cannot be had (no permission, a call): typed instead, said why.
        .onChange(of: dictation.failure) { _, failure in
            guard let failure else { return }
            note = AssistantView.dictationMessage(for: failure)
            if let heard = dictation.takeHeardWhenStopped() { typed = heard }
            dictation.failure = nil
            startTyping()
        }
        // The field tapped when nothing was heard: typing, with ↑ to send.
        .onChange(of: isTyping) { _, typing in
            if typing, phase == .heardNothing { phase = .typing }
            // The keyboard put away with nothing typed to change the card: the card as it was.
            if !typing, phase == .typing, fixing != nil, panelControl == nil,
               typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                keepCard()
            }
        }
        .sheet(item: $editingRow) { editing in
            DraftRowEditor(row: editing.row) { changed in
                changeCard { $0.replacingRow(changed) }
            } onRemove: {
                changeCard { $0.removingRow(editing.row.id) }
            }
        }
    }

    /// Listening, typing, nothing heard, the voice turning into words and Milu composing: one view
    /// (`input`), its one card closing around the words from ■ to the answer (user request
    /// 2026-11-18: the step from the voice to Milu at work had no motion, it jumped).
    ///
    /// The card over all of it while one changes it: the same view from the bar under it to
    /// Milu's new card, so it changes in place rather than going and coming again.
    @ViewBuilder
    private var content: some View {
        if let card = shownCard {
            saidLine(card.said)
            cardBlock(card)
            underCard
        } else {
            switch phase {
            case .listening, .typing, .heardNothing, .thinking: input.transition(leaves)
            case .result(let result): resultView(result)
            case .saved(let count): savedView(count).transition(leaves)
            case .failed(let message): failedView(message).transition(leaves)
            }
        }
    }

    /// Under a card, what to change in it: the composer of the first sentence, the same one view
    /// from its rest (⌨ · 🎤) through listening and typing to Milu at work, so the mic and the
    /// keyboard swap inside it at one height (user request 2026-11-19: "một vùng nhập sao cho thay
    /// đổi giữa mic và bàn phím không cần thay đổi height", as the first one; a one-line bar
    /// under the card opened into it, taller, and the card lost its buttons as it did). A
    /// question back while one changes it, under the card instead.
    @ViewBuilder
    private var underCard: some View {
        if case .result(.asking(let question, let choices)) = phase {
            asking(question, choices: choices)
        } else {
            // Why the last words changed nothing: Milu's answer, in its words between the card
            // and the field, as its question back is.
            fixNoteBlock
            input
                .transition(follows)
        }
    }

    /// Why the last words changed nothing, under the card. The words it answers quoted over it,
    /// small, as the card's sentence is over the card: what was said had gone, and the answer read
    /// as Milu's own idea.
    @ViewBuilder
    private var fixNoteBlock: some View {
        if restsUnderCard, let fixNote {
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let fixWords {
                    Text("“\(fixWords)”")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                words(fixNote)
            }
            .transition(rises)
        }
    }

    // MARK: - Sheet của iOS

    /// iOS's own sheet as tall as what it shows (user design 2026-11-19): a small field at its
    /// foot, the chat's, and over it one exchange, always laid out the same way: the words said
    /// (or what to say) at the top, Milu's answer under them. One path draws it in every step
    /// (`upper`), so nothing in it is taken away and put back as a step changes (user report
    /// 2026-11-19: "button các thứ nhấp nháy", an answer drawn by one branch while Milu waited
    /// and by another once one typed under it).
    ///
    /// The sheet's height follows what is over the field and never the field: a line more typed
    /// grows the field up into what scrolls over it, as in the chat. It changes only when Milu
    /// answers or a record is saved (`fitSheet`), and the field stays where it is on the screen
    /// while it does (`fieldRow`).
    private var nativeSheet: some View {
        NavigationStack {
            // What iOS gives the sheet's content: the detent's height under the bar, less the
            // keyboard while it is up. It comes and goes on iOS's clocks, and nothing in the
            // sheet is laid out by it: the content is as tall as the sheet's own figures say
            // (`innerHeight`) and hangs from the top of this room.
            Color.clear
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    Self.trace("given \(height) keys \(keyboard) inner \(innerHeight)")
                    holding { given = height }
                }
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { top in
                    guard top > 0, keyboard == .down, top != barHeight else { return }
                    holding { barHeight = top }
                    fitSheet()
                }
                .overlay(alignment: .top) { inner }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    if keyboard == .down { holding { keyboard = .rising } }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                    if keyboard == .rising { holding { keyboard = .up(min(innerBase, given)) } }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    holding { keyboard = .down }
                }
                .navigationTitle("Thêm bằng AI")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
                }
                .frameProbe("step", value: stepNumber)
        }
        .presentationDetents(sheetDetents,
                             selection: Binding(get: { .height(sheetHeight ?? Self.firstHeight) }, set: { _ in }))
        .presentationDragIndicator(.hidden)
        .presentationBackground(Palette.surface)
        .environment(\.isInSheet, true)
        .environment(\.isInHeaderCard, false)
    }

    /// The sheet's content: what scrolls over the field, and the field at its foot. As tall as
    /// the sheet's own figures say and no other way, so the keyboard is iOS's business alone,
    /// as for any sheet: iOS lifts the sheet over it, and what is in the sheet is laid out as
    /// it was, riding with the sheet's top.
    ///
    /// (Tried and dropped, 2026-11-19. Laid out by the room iOS gives, the field at the room's
    /// foot: as the keyboard went, that room was for some frames the short sheet's less a
    /// keyboard no longer under it, and the field stood at the bar. The keyboard ignored and
    /// the field put over it by hand: iOS then laid the content out higher than the bar by an
    /// amount of its own, which on an iPhone hid the first words under the title, user report
    /// the same day.)
    private var inner: some View {
        VStack(spacing: 0) {
            upperArea
            if showsField {
                fieldRow
                    .zIndex(1)
                    .transition(.opacity.animation(Motion.gentle(.easeOut(duration: 0.2))))
            }
        }
        .frame(height: innerHeight, alignment: .top)
        // Its height is the sheet's own figure: the keyboard is none of its business, nor of
        // anything in it. Told of the keyboard, what scrolls over the field scrolled its words
        // away as the keyboard came and brought them back once it was up, the sheet with no
        // words in it for eight frames (video at 60 a second, 2026-11-19).
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // No motion in the sheet comes from outside it: every one is given its own curve
        // under this (`upper`, `miniField`), and what iOS does to the room is taken at once.
        .transaction { $0.animation = nil }
    }

    /// What is over the field, in the room the field leaves it.
    ///
    /// Laid out plainly, not in a scroll view, whenever it fits the sheet with no keyboard up,
    /// which is nearly always: a scroll view takes the keyboard for its own business whatever
    /// SwiftUI is told. As the keyboard came it scrolled its words out of sight and brought
    /// them back once the keyboard was up, the sheet with no words in it for eight frames
    /// (video at 60 a second, 2026-11-19). Short of room (a card over the keyboard, lines typed
    /// in the field) it is lifted by what is missing, on the sheet's spring, its foot over the
    /// field and its top cut under the bar, as the chat's messages go up under a growing field.
    /// Only a card too long for the screen scrolls.
    @ViewBuilder
    private var upperArea: some View {
        if upperScrolls {
            ScrollViewReader { reader in
                ScrollView {
                    upperContent
                    Color.clear
                        .frame(height: 0)
                        .id(Self.upperFoot)
                }
                // Its foot, the buttons, brought over the field as the keyboard cuts its room.
                .onChange(of: isCut) { _, cut in
                    guard cut else { return }
                    withAnimation(Motion.gentle(.spring(Self.sheetSpring))) {
                        reader.scrollTo(Self.upperFoot, anchor: .bottom)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden, axes: .vertical)
            }
        } else {
            // Whatever room is left, down to none: as tall as its content it could not give
            // way, and pushed the field out under the sheet (video, Simulator 2026-11-19).
            Color.clear
                .overlay(alignment: .top) {
                    upperContent
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(y: -upperLift)
                        .animation(Motion.gentle(.spring(Self.sheetSpring)), value: upperLift)
                }
                .clipped()
        }
    }

    private var upperContent: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            upper
        }
        .padding(.horizontal, Spacing.page)
        .padding(.top, Spacing.s)
        .padding(.bottom, showsField ? 0 : Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .keyboardDismissArea()
        .animation(Motion.gentle(Self.step), value: phase)
        .animation(Motion.gentle(Self.step), value: transcribing)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            upperHeight = height
            fitSheet()
            judgeScroll()
        }
    }

    /// The room over the field: the content's height less the field's, lines typed and all.
    /// With no keyboard up, of the height the sheet is about to take as well as the one it has:
    /// reckoned from the one it has alone, a card just in was lifted out under the bar for the
    /// frames before the sheet took its height, then let down again (video 2026-11-19).
    private var upperRoom: CGFloat {
        var height = innerHeight
        if keyboard == .down, let sheetHeight {
            height = max(height, sheetTarget(from: sheetHeight) - (barHeight ?? Self.firstBar))
        }
        guard showsField else { return height }
        return max(height - Self.fieldRoom - (fieldBox - Self.fieldButton), 0)
    }

    /// By how much what is over the field is longer than its room.
    private var upperLift: CGFloat { max(upperHeight - upperRoom, 0) }

    /// Whether it must scroll: longer than the tallest a sheet can be on this screen, by the
    /// screen's own figures. (Judged by the room iOS gives, which trails the sheet's height by a
    /// layout, it was a scroll view for a frame as each card came in, and everything in it was
    /// made anew: the words came in a second time, video 2026-11-19.)
    private func judgeScroll() {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let window else { return }
        let most = window.bounds.height - window.safeAreaInsets.top - window.safeAreaInsets.bottom
            - (barHeight ?? Self.firstBar) - Spacing.l
        let scrolls = upperHeight + (showsField ? Self.fieldRoom : 0) > most
        if scrolls != upperScrolls { upperScrolls = scrolls }
    }

    /// The keyboard, for the content's height alone (`innerHeight`).
    private enum Keys: Equatable {
        case down
        /// On its way up: the room iOS gives is the one to fit in, as it comes.
        case rising
        /// Up: the height the content had once the keyboard was there. The room iOS gives is
        /// not read again until the next one: as the keyboard goes, iOS takes the sheet back
        /// to its short frame at once and goes on taking the keyboard off it for some frames.
        case up(CGFloat)
    }

    /// The content's height by the sheet's own figures: the sheet's less its bar.
    private var innerBase: CGFloat {
        max((sheetHeight ?? Self.firstHeight) - (barHeight ?? Self.firstBar), 0)
    }

    /// The content's height: its own, cut to the room left over the keyboard when it does not
    /// fit there (a long card being changed, the sheet stopped at the screen's top).
    private var innerHeight: CGFloat {
        switch keyboard {
        case .down: innerBase
        case .rising: given > 0 ? min(innerBase, given) : innerBase
        case .up(let room): min(innerBase, room)
        }
    }

    /// Cut for the keyboard (`innerHeight`).
    private var isCut: Bool { innerHeight < innerBase - 1 }

    /// The field with its room. While the sheet slides to a new height it is held where it
    /// was on the screen (`hold`).
    private var fieldRow: some View {
        miniField
            .padding(.horizontal, Spacing.page)
            .padding(.top, Self.fieldGap)
            .padding(.bottom, Self.fieldFoot)
            .background(Palette.surface)
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: keyTick) { row, shift in
                row.offset(y: shift)
            } keyframes: { _ in
                KeyframeTrack {
                    MoveKeyframe(keyShift)
                    SpringKeyframe(0, duration: 0.8, spring: Self.sheetSpring)
                }
            }
    }

    private static var upperFoot: String { "QuickRecord.upperFoot" }

    /// Whatever changes the content's height (the sheet to another height, a long card cut for
    /// the keyboard) goes through here: the field's foot is the content's, and the field is
    /// held (`hold`) in the very update that moves it. Held an update later, on the height
    /// seen to have changed, it was a frame out of place first (video at 60 a second,
    /// 2026-11-19, a card coming in).
    private func holding(_ change: () -> Void) {
        let before = innerHeight
        change()
        let after = innerHeight
        if settled, before != after {
            Self.trace("inner \(after) from \(before) keys \(keyboard)")
            hold(by: before - after)
        }
    }

    /// iOS lays the content out for the sheet's new height at once and slides the sheet's top
    /// to it after: a field at the content's foot fell out under a sheet still short, or stood
    /// in the middle of one still tall (video, Simulator 2026-11-19). It is moved back by what
    /// its place changed, on top of what is still held of a move before, and let go on the
    /// sheet's own spring from the same frame: on the screen it does not move at all. What is
    /// over it hangs from the sheet's top and rides with it.
    private func hold(by change: CGFloat) {
        guard abs(change) > 0.5 else { return }
        let elapsed = CACurrentMediaTime() - keyBegan
        let left = elapsed < 0.7 ? keyShift * (1 - Self.sheetSpring.value(target: 1.0, time: elapsed)) : 0
        keyShift = left + change
        keyBegan = CACurrentMediaTime()
        keyTick += 1
    }

    private static func trace(_ words: @autoclosure () -> String) {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["MILU_DEMO"] != nil else { return }
        let line = String(format: "%.3f ", CACurrentMediaTime()) + words() + "\n"
        let url = URL(fileURLWithPath: "/tmp/milu-qr.log")
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? Data(line.utf8).write(to: url)
        }
        #endif
    }

    /// iOS's spring for a sheet going to another detent, measured on its top edge frame by frame
    /// (video, Simulator 2026-11-19): no bounce, 0.33 s.
    private static var sheetSpring: Spring { Spring(duration: 0.33, bounce: 0) }

    /// Before anything is measured: the bar, and with it the opening words and the field.
    private static var firstBar: CGFloat { 70 }
    private static var firstHeight: CGFloat { 212 }
    private static var fieldGap: CGFloat { Spacing.l }
    private static var fieldFoot: CGFloat { Spacing.l }
    /// The field at one line, with its room over and under it: what the sheet keeps for it,
    /// however many lines are typed.
    private static var fieldRoom: CGFloat { fieldGap + fieldButton + 2 * fieldInset + fieldFoot }

    /// The sheet's one detent; its last one beside it for the moment it slides from that one,
    /// as iOS slides a sheet only to a detent it has (`fitSheet`).
    private var sheetDetents: Set<PresentationDetent> {
        let now = PresentationDetent.height(sheetHeight ?? Self.firstHeight)
        if let slidingFrom { return [.height(slidingFrom), now] }
        return [now]
    }

    /// While one speaks or types, and while Milu composes, the sheet keeps its height: what is
    /// over the field then changes little, and a sheet that shrank as a sentence went and grew
    /// again as its answer came moved twice for one step (video, Simulator 2026-11-19). It only
    /// grows then, for words longer than their room.
    private var holdsHeight: Bool {
        guard settled else { return false }
        switch phase {
        case .listening, .typing, .thinking: return true
        default: return false
        }
    }

    /// The bar, what is over the field and the field at one line. While the sheet comes up, its
    /// height is taken as it is found, at once, as any sheet of the app that fits its content
    /// (`FittedDetent`): the first layouts are not at the sheet's width yet. After that it is
    /// slid to, the layouts of one step (a card comes to its height in two or three, a few
    /// milliseconds apart) as one slide to the last of them.
    private func fitSheet() {
        guard barHeight != nil, upperHeight > 0 else { return }
        guard let shown = sheetHeight, settled else {
            let target = sheetTarget(from: 0)
            if target != sheetHeight { sheetHeight = target }
            judgeScroll()
            return
        }
        guard abs(sheetTarget(from: shown) - shown) >= 1, !isFitting else { return }
        isFitting = true
        // The detent the sheet is at, always: with the one of a slide before still there in
        // its place (a card comes to its height twice, a tenth of a second apart), the sheet
        // had no detent of its own to slide from, and took the second height in one frame,
        // 146 points at once (measured frame by frame, 2026-11-19).
        slidingFrom = shown
        Task { @MainActor in
            // The detent it slides from in place before the new one is picked, and the layouts
            // of this step done.
            try? await Task.sleep(for: .milliseconds(30))
            isFitting = false
            guard let from = sheetHeight else { return }
            let target = sheetTarget(from: from)
            guard abs(target - from) >= 1 else {
                if slideEnds <= CACurrentMediaTime() { slidingFrom = nil }
                return
            }
            slideEnds = CACurrentMediaTime() + 0.7
            // The content's height goes with it, and the field is held.
            holding { sheetHeight = target }
            let ends = slideEnds
            try? await Task.sleep(for: .milliseconds(700))
            guard slideEnds == ends else { return }
            slidingFrom = nil
        }
    }

    /// The height asked for now; no less than the one it has while it holds (`holdsHeight`).
    private func sheetTarget(from current: CGFloat) -> CGFloat {
        let target = ((barHeight ?? Self.firstBar) + upperHeight + (showsField ? Self.fieldRoom : 0)).rounded()
        return holdsHeight ? max(target, current) : target
    }

    /// Over the field: the words at the top, Milu's answer under them; "Đã lưu" alone.
    @ViewBuilder
    private var upper: some View {
        if case .saved(let count) = phase {
            savedView(count)
                .transition(leaves)
        } else {
            header
            if let card = shownCard {
                nativeCard(card)
                fixNoteBlock
            }
            if let last {
                // Milu at work on the next sentence: its last answer stays, dimmed, until the
                // new one takes its place, rather than leaving a hole the sheet closes and opens.
                answerBody(last)
                    .opacity(phase == .thinking ? 0.35 : 1)
                    .disabled(phase == .thinking)
            }
        }
    }

    /// The words at the top: those said or typed once they go to Milu, coming in glyph by glyph
    /// in the place of what to say (user request 2026-11-19); the same words, the same size and
    /// place, from Milu at work to its answer, so they never give way to a smaller copy of
    /// themselves (video, Simulator 2026-11-19: two sizes of one sentence faded across).
    private var header: some View {
        let words = headerWords
        // Before any answer, room for two lines from the start: a short sentence moves nothing.
        let keepsRoom = shownCard == nil && last == nil
        return ZStack(alignment: .topLeading) {
            if keepsRoom {
                greeting(heardNothing: false)
                    .hidden()
                    .accessibilityHidden(true)
            }
            if let words {
                RevealingWords(text: words)
                    .textRole(.body)
                    .foregroundStyle(Palette.label)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(words)
                    .transition(.asymmetric(insertion: .identity,
                                            removal: .opacity.animation(Motion.gentle(.easeOut(duration: 0.12)))))
            } else {
                greeting(heardNothing: phase == .heardNothing)
                    .id(phase == .heardNothing)
                    .transition(arrives)
            }
        }
    }

    /// The words the header shows; none while it says what to say, or that nothing was heard.
    private var headerWords: String? {
        if phase == .heardNothing { return nil }
        // A card keeps its own sentence over it while words change it.
        if let card = shownCard { return card.said.isEmpty ? nil : card.said }
        if phase == .thinking, !said.isEmpty { return said }
        if let last, !last.said.isEmpty { return last.said }
        return nil
    }

    private func greeting(heardNothing: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(heardNothing ? Copy.heardNothing : Copy.greeting)
                .textRole(.body)
                .foregroundStyle(Palette.label)
            if !heardNothing {
                Text(Copy.example)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Milu's card, its buttons and rows live while one says or types a change (a tap on them
    /// ends the change, the card as it was), still only while Milu works on it. One height
    /// throughout: its line "Bấm vào khoản để sửa" stays (it went with `opensRows`, and the
    /// sheet moved 22 points as a change was sent, video 2026-11-19).
    @ViewBuilder
    private func nativeCard(_ card: ShownCard) -> some View {
        let locked = card.isFixing && phase == .thinking
        if let note = card.note {
            words(note)
                .transition(rises)
        }
        DraftCard(draft: card.draft, onRow: { id in
            guard !locked, card.draft.isPending, let row = card.draft.row(id) else { return }
            if fixing != nil { keepCard() }
            editingRow = AssistantView.EditingRow(row: row)
        }, actions: AnyView(HStack(spacing: Spacing.s) {
            MiluButton("Huỷ", role: .secondary, fullWidth: true) { close() }
            MiluButton(card.draft.liveRows.count > 1 ? "Lưu cả \(card.draft.liveRows.count)" : "Lưu",
                       role: .primary, fullWidth: true) {
                if fixing != nil { keepCard() }
                save(card.draft)
            }
        }
        .disabled(locked)), opensRows: true)
        .transition(rises)
    }

    /// Milu's answer that is not a card: its question and the answers to tap, or what it cannot
    /// record and where to do it.
    @ViewBuilder
    private func answerBody(_ answer: Held) -> some View {
        switch answer.result {
        case .result(.asking(let question, let choices)):
            words(question)
                .transition(rises)
            if !choices.isEmpty {
                FlowLayout(spacing: Spacing.s) {
                    ForEach(choices, id: \.self) { choice in
                        TagChip(title: choice, isProminent: false) { send(choice) }
                            .fixedSize()
                    }
                }
                .transition(follows)
            }
        case .result(.refused(let message, let form)):
            words(message)
                .transition(rises)
            if let form {
                MiluButton(form.title, role: .primary, fullWidth: true) { open(.form(form)) }
                    .transition(follows)
            }
        case .result(.notRecord):
            words(Copy.notRecord)
                .transition(rises)
            MiluButton("Mở Hỏi Milu", role: .primary, fullWidth: true) {
                onNext(.chat(answer.said))
                close()
            }
            .transition(follows)
        case .failed(let message):
            words(message)
                .transition(rises)
            MiluButton("Thử lại", role: .primary, fullWidth: true) { send(answer.said) }
                .transition(follows)
        default:
            EmptyView()
        }
    }

    /// The field shows: in every step but "Đã lưu".
    private var showsField: Bool {
        if case .saved = phase { false } else { true }
    }

    // MARK: - Ô chat nhỏ

    private static var fieldButton: CGFloat { ControlHeight.small }
    private static var fieldInset: CGFloat { Spacing.s }
    private static var fieldRadius: CGFloat { fieldButton / 2 + fieldInset }

    /// The chat's field, small (user design 2026-11-19): one line, its button the chat's size.
    /// Nothing in it moves from one step to the next: the same button at its end, its glyph
    /// changing in place, and in its middle the hint, the words typed, the wave or "Milu đang
    /// soạn", one fading out before the next fades in. A tap on it types.
    private var miniField: some View {
        let listens = phase == .listening
        let waiting = phase == .thinking
        let shape = RoundedRectangle(cornerRadius: Self.fieldRadius, style: .continuous)
        return fieldMiddle
            .frame(maxWidth: .infinity, alignment: .leading)
            // Room for the button, which is laid on the field's foot rather than beside its
            // words: beside them it stood half-way up a field of two lines (video 2026-11-19),
            // where the chat's stays on the last line.
            .padding(.trailing, Self.fieldButton + Spacing.s)
            .padding(Self.fieldInset)
            .overlay(alignment: .bottomTrailing) {
                fieldAction
                    .padding(Self.fieldInset)
            }
        // Milu's sky while it listens or composes, as the chat's field lights up.
            .background(listens || waiting ? Palette.accentSoft : Palette.fill, in: shape)
            .overlay {
                shape
                    .strokeBorder(Palette.primary, lineWidth: Self.border(displayScale))
                    .opacity(waiting ? 1 : 0)
            }
            .contentShape(shape)
            .onTapGesture(perform: tapField)
            .animation(Motion.gentle(Self.step), value: phase)
            .animation(Motion.gentle(.easeOut(duration: 0.25)), value: fieldBox)
            // What changes in the field has its curve; where the field is does not, it is the
            // sheet's to move (`hold`). On the step's curve too, the field's frame and the
            // button laid on it went to a new place each at its own pace, the disc out of its
            // field for a few frames (video, Simulator 2026-11-19).
            .geometryGroup()
    }

    /// The field's middle: what it holds in this step. As tall as its box (`fieldBox`), the
    /// words on its foot: a line more is laid out at once and the box opens over it on its
    /// curve, as the chat's field (`ChatViewController`), so the line being typed never moves.
    private var fieldMiddle: some View {
        let typing = phase == .typing
        return ZStack(alignment: .bottomLeading) {
            switch phase {
            case .listening:
                HStack(spacing: 0) {
                    ListeningCountdown(startedAt: dictation.startedAt)
                    VoiceWaveform(dictation: dictation)
                }
                .frame(height: Self.fieldButton)
                .transition(arrives)
            case .thinking:
                TranscribingStatus(text: Copy.composing, spoken: Copy.composing)
                    .frame(height: Self.fieldButton)
                    .transition(arrives)
            default:
                ZStack(alignment: .bottomLeading) {
                    Text(fieldHint)
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryLabel.opacity(0.7))
                        .lineLimit(1)
                        .frame(height: Self.fieldButton)
                        .opacity(typing && !typed.isEmpty ? 0 : 1)
                        .accessibilityHidden(typing)
                    if typing {
                        miniTextField
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                                openField(to: height)
                            }
                    }
                }
                .transition(arrives)
            }
        }
        .frame(height: fieldBox, alignment: .bottomLeading)
        .clipped()
        .padding(.leading, Spacing.s)
    }

    /// The box to the words' new height, on the chat's curve for its field.
    private func openField(to height: CGFloat) {
        let box = max(height, Self.fieldButton)
        if box != fieldBox { fieldBox = box }
    }

    /// Typed words, to four lines, then they scroll; as the chat's field, sent as typed. One
    /// line as tall as the hint's.
    private var miniTextField: some View {
        TextField("", text: $typed, axis: .vertical)
            .textRole(.body)
            .lineLimit(1...4)
            .autocorrectionDisabled()
            .writingToolsDisabledIfAvailable()
            .focused($isTyping)
            .submitLabel(.send)
            .onSubmit { send(typed) }
            .frame(minHeight: Self.fieldButton)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(asked != nil ? "Câu trả lời" : fixing != nil ? "Điều cần sửa" : "Khoản muốn ghi")
    }

    /// What the field says while there is nothing in it: by what is over it, not by the step,
    /// so it does not change as one begins to type.
    private var fieldHint: String {
        if phase == .heardNothing { return Copy.sayAgain }
        if asked != nil { return Copy.answerHint }
        if shownCard != nil { return Copy.fixShort }
        if last != nil { return Copy.another }
        return Copy.fieldHint
    }

    /// At the field's end, one blue disc in every step: ■ while one speaks, ↑ once something is
    /// typed, the mic otherwise, one glyph shrinking out as the next grows in on the spot (the
    /// chat's own, `AssistantView.actionButton`; iOS's symbol replace ran one after the other).
    /// Dim while Milu composes.
    private var fieldAction: some View {
        let listens = phase == .listening
        let waiting = phase == .thinking
        let sends = phase == .typing && !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let glyph = listens ? 1 : sends ? 2 : 0
        return Button {
            if listens {
                finishListening()
            } else if sends {
                send(typed)
            } else {
                speak()
            }
        } label: {
            ZStack {
                Circle().fill(Palette.primary)
                actionGlyph("mic.fill", shown: glyph == 0)
                actionGlyph("stop.fill", shown: glyph == 1)
                actionGlyph("arrow.up", shown: glyph == 2)
            }
            .frame(width: Self.fieldButton, height: Self.fieldButton)
            .opacity(waiting ? 0.4 : 1)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(waiting)
        .animation(Motion.gentle(.spring(duration: 0.3, bounce: 0.25)), value: glyph)
        .animation(Motion.gentle(.easeOut(duration: 0.2)), value: waiting)
        .accessibilityLabel(listens ? "Xong, gửi cho Milu" : sends ? "Gửi cho Milu" : "Nói với Milu")
    }

    private func actionGlyph(_ symbol: String, shown: Bool) -> some View {
        Image(systemName: symbol)
            .font(.system(size: IconSize.inline + 2, weight: .semibold))
            .foregroundStyle(Palette.onPrimary)
            .scaleEffect(shown ? 1 : 0.4)
            .opacity(shown ? 1 : 0)
    }

    /// The mic: to change the card under it, to answer, or a new sentence from the start.
    private func speak() {
        if restsUnderCard {
            fix(typing: false)
        } else if asked == nil, fixing == nil {
            startOver()
        } else {
            listen()
        }
    }

    /// A tap on the field: the keyboard, for what the step asks.
    private func tapField() {
        switch phase {
        case .typing:
            isTyping = true
        case .thinking:
            break
        case .listening:
            dictation.stop()
            startTyping()
        case .heardNothing:
            startTyping()
        case .result(.card):
            fix(typing: true)
        case .result(.asking):
            startTyping()
        case .result, .failed, .saved:
            startOver(typing: true)
        }
    }

    /// The card waiting, nothing being said or typed to it yet: the composer at rest under it.
    private var restsUnderCard: Bool {
        if case .result(.card) = phase { true } else { false }
    }

    /// A step going: gone quickly, before the next one comes in over it (Simulator, 2026-11-18:
    /// faded at the pace of the sheet, the old words lay over the new card for a moment).
    private var leaves: AnyTransition {
        .asymmetric(insertion: .opacity, removal: .opacity.animation(Motion.gentle(.easeOut(duration: 0.12))))
    }

    /// What comes in on the very spot another thing is leaving (the card's words and lines): a
    /// beat later, once that has gone, so the two are never read one through the other (Simulator,
    /// 2026-11-18: the hint showed through "Đang chuyển thành chữ", and that through the words).
    private var arrives: AnyTransition {
        .asymmetric(insertion: .opacity.animation(Motion.gentle(.easeOut(duration: 0.25).delay(0.12))),
                    removal: .opacity.animation(Motion.gentle(.easeOut(duration: 0.12))))
    }

    // MARK: - Khung soạn

    /// Listening, typing, nothing heard and the wait for the answer: one card, as a chat's field
    /// (user request 2026-11-18, the redesign: the words at the top, under them a lit field saying
    /// Milu was at work, under that two dimmed buttons read as three things apart, and "Đang
    /// chuyển thành chữ" under words already there made no sense).
    ///
    /// The card is as tall as what is in it (user request 2026-11-18: at three lines whatever the
    /// words, a short sentence sat in a wide stretch of blue):
    /// - To speak or type: the hint, or the field in its place, and a row of 44: ⌨ or the mic, the
    ///   wave, the one main action; under the card, a small line. The same height from the mic to
    ///   the keyboard, so the keyboard alone lifts the sheet (user reports 2026-11-17 and
    ///   2026-11-18: a sheet that changed height as the keyboard rose looked closed and opened
    ///   again, or jumped).
    /// - Milu at work: the words sent and a line under them, no more; a long sentence opens the
    ///   card as it comes, the sheet with it (`BottomPanel`).
    private var input: some View { inputStack(showsQuestion: true) }

    /// `input`, the question being answered over it or not (the native sheet has it in what
    /// scrolls, over the composer at its foot).
    private func inputStack(showsQuestion: Bool) -> some View {
        let waiting = phase == .thinking
        return VStack(alignment: .leading, spacing: Spacing.l) {
            if showsQuestion, let asked { question(asked) }
            VStack(alignment: .leading, spacing: Spacing.s) {
                composer
                // Milu at work: nothing more to tell, and no room kept for it.
                if !waiting {
                    tip
                        .transition(leaves)
                }
            }
        }
    }

    /// The waiting card's border: 1.5 points to the nearest whole pixels under (4 on a 3× screen,
    /// 3 on a 2×). At 1.5, 4.5 pixels, its straight sides were drawn 4 pixels sharp and its
    /// curves 4.5 to 4.8 soft, the corners thicker (iPhone photo 2026-11-19: "viền xanh đậm …
    /// dày hơn ở các đường bo cong").
    private static func border(_ scale: CGFloat) -> CGFloat {
        (1.5 * scale).rounded(.down) / scale
    }

    private var composer: some View {
        let waiting = phase == .thinking
        // Milu's sky while it listens or composes; the grey of any field while one types.
        let lit = phase == .listening || waiting
        let shape = RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous)
        return ZStack(alignment: .topLeading) {
            if waiting {
                waitingLines
                    .transition(arrives)
            } else {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    entry
                    controls
                }
                .transition(arrives)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(Spacing.m)
        .background(lit ? Palette.accentSoft : Palette.fill, in: shape)
        // Sent: the card closes around the words, Milu at work on them.
        .overlay {
            shape
                .strokeBorder(Palette.primary, lineWidth: Self.border(displayScale))
                .opacity(waiting ? 1 : 0)
        }
    }

    /// What Milu asks for, and the field in its place while one types: as tall as the hint, the
    /// same one for the mic and the keyboard, so only the cursor comes from one to the other. A
    /// little in from the buttons' edge, over their glyphs rather than their rims.
    ///
    /// No words here while one speaks: only those that go to Milu are ever shown, the server's,
    /// once ■ or a pause has sent the recording to it (user choice 2026-11-18: the phone's own
    /// words, shown as they were said, read as if the server were not used, and changed once it
    /// answered: "35.000" became "ba mươi lăm nghìn"). The phone's recognizer still listens,
    /// unseen: for the pause that sends, and for its words should the server not answer.
    private var entry: some View {
        let typing = phase == .typing
        // The field is the user's: what Milu answers is said over it (`underCard`), never in it
        // (user report 2026-11-19: "AI response vào đúng khu vực chat? Chỗ này là không được").
        let hint = phase == .heardNothing ? Copy.heardNothing
            : asked != nil ? Copy.answerHint
            : fixing != nil || restsUnderCard ? Copy.fixHint : Copy.hint
        return ZStack(alignment: .topLeading) {
            // Two lines whatever the hint, the field's own two: a shorter hint (an answer, a
            // change) gave a field that grew a line as one typed (user report 2026-11-19).
            Text(verbatim: "A\nA")
                .textRole(.body)
                .hidden()
                .accessibilityHidden(true)
            Text(hint)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
                // The hint of one state over another's, faded across.
                .contentTransition(.opacity)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(typing && !typed.isEmpty ? 0 : 1)
                .accessibilityLabel(phase == .listening ? "Milu đang nghe" : hint)
                .accessibilityHidden(typing)
            if typing {
                field
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.xs)
        // The whole of it takes a tap to type, the mic off with nothing heard too.
        .contentShape(Rectangle())
        .onTapGesture {
            switch phase {
            case .typing: isTyping = true
            case .heardNothing: startTyping()
            case .result(.card): fix(typing: true)
            default: break
            }
        }
    }

    /// Milu at work: the words it was sent, and under them what it is doing with them. Never
    /// less than a line of words and that line, so a short sentence comes into room already
    /// there and moves nothing; a longer one opens the card, to five lines at most.
    ///
    /// The recording still with the server, there are no words yet: "Đang chuyển thành chữ"
    /// alone, in the middle; it steps down as they come, and says "Milu đang soạn".
    private var waitingLines: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(verbatim: "A")
                Text(verbatim: "A")
            }
            .textRole(.body)
            .hidden()
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.s) {
                if !said.isEmpty {
                    Text(said)
                        .textRole(.body)
                        .foregroundStyle(Palette.label)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Answered, the words become the quote over Milu's answer; words to
                        // change a card do not, the card's own sentence staying over it.
                        .matchedGeometryEffect(id: fixing == nil ? "said" : "fix", in: flow,
                                               properties: .position, anchor: .topLeading)
                        .transition(arrives)
                }
                HStack(spacing: Spacing.s) {
                    Image(IconCatalog.emojiName("✨"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: IconSize.control, height: IconSize.control)
                        .accessibilityHidden(true)
                    TranscribingStatus(text: transcribing ? Copy.transcribing : Copy.composing,
                                       spoken: transcribing ? "Milu đang chuyển giọng nói thành chữ" : Copy.composing,
                                       swap: arrives)
                }
            }
        }
        .padding(Spacing.xs)
    }

    /// The question being answered, small, over the card.
    private func question(_ text: String) -> some View {
        Text(MessageRow.formatted(text))
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryLabel)
            .lineLimit(6)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .matchedGeometryEffect(id: "question", in: flow, properties: .position, anchor: .topLeading)
            .accessibilityLabel("Milu hỏi: " + String(MessageRow.formatted(text).characters))
    }

    /// Two lines at most, the hint's own, then it scrolls inside: it never grows nor shrinks the
    /// sheet as lines are typed or wiped (user report 2026-11-18). No placeholder of its own: the
    /// hint under it is the one the mic has.
    private var field: some View {
        TextField("", text: $typed, axis: .vertical)
            .textRole(.body)
            .lineLimit(2)
            // Sent as typed, as the chat's field (user request 2026-11-10): "phe" became "how"
            // (Simulator, 2026-11-17).
            .autocorrectionDisabled()
            .writingToolsDisabledIfAvailable()
            .focused($isTyping)
            .submitLabel(.send)
            .onSubmit { send(typed) }
            .accessibilityLabel(asked != nil ? "Câu trả lời" : fixing != nil ? "Điều cần sửa" : "Khoản muốn ghi")
    }

    /// The card's last row. The same two buttons in every state, of one size (user report
    /// 2026-11-18: ⌨ was small beside ■), their glyphs and actions changing in place: listening,
    /// ⌨ and ■ (done, send) with the wave between them; typing, the mic and ↑; nothing heard, ⌨
    /// and the mic again. While Milu composes there is nothing to press, and no row
    /// (`waitingLines`), rather than buttons left there dimmed.
    private var controls: some View {
        let listens = phase == .listening
        let typing = phase == .typing
        // At rest under a card: ⌨ and the mic, as when nothing was heard.
        let resting = restsUnderCard
        let empty = typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(spacing: Spacing.m) {
            roundButton(typing ? "mic" : "keyboard",
                        label: typing ? "Nói thay vì gõ" : resting ? "Gõ điều cần sửa" : "Gõ thay vì nói") {
                if resting {
                    fix(typing: true)
                } else if typing {
                    listen()
                } else {
                    if listens { dictation.stop() }
                    startTyping()
                }
            }
            ZStack {
                if listens {
                    VoiceWaveform(dictation: dictation)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            mainButton(typing ? "arrow.up" : listens ? "stop.fill" : "mic.fill",
                       label: typing ? "Gửi cho Milu" : listens ? "Xong, gửi cho Milu" : resting ? "Nói điều cần sửa" : "Nói lại") {
                if typing {
                    send(typed)
                } else if listens {
                    finishListening()
                } else if resting {
                    fix(typing: false)
                } else if asked == nil, fixing == nil {
                    startOver()
                } else {
                    listen()
                }
            }
            .opacity(typing && empty ? 0.4 : 1)
            .animation(Motion.gentle(.easeOut(duration: 0.15)), value: empty)
        }
        .frame(height: ControlHeight.regular)
    }

    /// Under the card, one small line: listening, that a pause sends, then the last seconds
    /// counted; typing, a tip, or why the mic is off. Its room is kept when there is nothing to
    /// say, so the sheet is one height from the mic to the keyboard.
    ///
    /// While a card is being changed, "Giữ như cũ" at its end, rather than on a line of its own
    /// (user report 2026-11-19: a row of 44 under the tip, 46pt from it, 63 while typing over an
    /// empty tip, and the sheet's own margin under that).
    private var tip: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
            ZStack(alignment: .topLeading) {
                switch phase {
                case .listening:
                    ListeningTip(startedAt: dictation.startedAt,
                                 text: fixing == nil ? Copy.autoSendTip : Copy.autoSendTipShort)
                        .transition(.opacity)
                case .typing:
                    Text(note ?? (asked == nil && fixing == nil ? Copy.typeTip : " "))
                        .transition(.opacity)
                default:
                    Text(verbatim: " ")
                        .accessibilityHidden(true)
                }
            }
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryLabel)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Under a card, its room kept from the rest on: the line is one height whether it is
            // there or not.
            if shownCard != nil {
                keepButton
                    .opacity(fixing != nil ? 1 : 0)
                    .disabled(fixing == nil)
                    .accessibilityHidden(fixing == nil)
            }
        }
        // Under the card's words.
        .padding(.horizontal, Spacing.l)
    }

    /// The sheet's words, together (user report 2026-11-18: "Gõ khoản bạn muốn ghi, mấy khoản
    /// cũng được" read unprofessional): short, plain, the same voice throughout.
    enum Copy {
        /// An invitation to speak as one talks, not an instruction (user request 2026-11-18: over
        /// "Nói khoản chi hoặc thu, ví dụ: …"); the same for the keyboard, so nothing changes in
        /// the card from one to the other.
        /// The example held together (non-breaking spaces), so it goes to the next line whole
        /// rather than "“Cà" ending the first (Simulator, 2026-11-18).
        static let hint = "Hôm nay bạn tiêu gì rồi? Kể Milu nghe, " + Self.together("ví dụ:") + " "
            + Self.together("“Cà phê 35k, gửi xe 5k”")
        static let answerHint = "Câu trả lời của bạn"
        /// The small field's words (`miniField`): one line each, nothing else in the field.
        static let greeting = "Hôm nay bạn tiêu gì rồi?"
        static let example = "Ví dụ: " + Self.together("“Cà phê 35k, gửi xe 5k”")
        static let fieldHint = "Nói hoặc gõ khoản chi"
        static let fixShort = "Muốn sửa gì?"
        static let sayAgain = "Nói lại hoặc gõ"
        static let another = "Nói khoản khác"
        static let heardNothing = "Milu chưa nghe thấy giọng nói. Bạn hãy nói lại hoặc nhập bằng bàn phím."
        /// The pause that sends is otherwise a surprise.
        static let autoSendTip = "Milu tự gửi khi bạn ngừng nói \(Int(DictationAutoStop.pauseAfterWords)) giây."
        /// The same, shorter, beside "Giữ như cũ" on its line while a card is changed: the longer
        /// one went to two lines there (Simulator 2026-11-19).
        static let autoSendTipShort = "Tự gửi khi ngừng nói \(Int(DictationAutoStop.pauseAfterWords)) giây."

        /// Words that go to the next line together: "ví dụ:" broke as "ví / dụ:" on a sheet a
        /// point narrower (Simulator 2026-11-19).
        private static func together(_ words: String) -> String {
            words.replacingOccurrences(of: " ", with: "\u{00A0}")
        }
        static let typeTip = "Có thể nhập nhiều khoản, cách nhau bằng dấu phẩy."
        static let transcribing = "Đang chuyển thành chữ"
        static let composing = "Milu đang soạn"
        static let answerBar = "Nói hoặc gõ câu trả lời"
        /// Two lines, as the first one, the example on the second.
        static let fixHint = "Bạn muốn sửa gì? Nói với Milu, " + Self.together("ví dụ:") + " "
            + Self.together("“Gửi xe 10k thôi”")
        static let keep = "Giữ như cũ"
        static let notRecord = "Câu này không phải một khoản chi hay thu. Để trò chuyện hoặc hỏi về số liệu, bạn hãy dùng Hỏi Milu."
        static let failed = "Milu chưa phản hồi được. Bạn hãy thử lại."
    }

    // MARK: - Câu trả lời

    /// Milu's answer coming in: it rises a little as it fades in, after the sheet has started
    /// to take its height; going, it only fades.
    private var rises: AnyTransition {
        .asymmetric(insertion: .opacity.combined(with: .offset(y: 14))
                        .animation(Motion.gentle(.smooth(duration: 0.4).delay(0.1))),
                    removal: .opacity.animation(Motion.gentle(.easeOut(duration: 0.12))))
    }

    /// What comes under it, a beat later: the suggestions, the buttons.
    private var follows: AnyTransition {
        .asymmetric(insertion: .opacity.animation(Motion.gentle(.easeOut(duration: 0.3).delay(0.22))),
                    removal: .opacity.animation(Motion.gentle(.easeOut(duration: 0.12))))
    }

    /// The card on show: Milu's answer, or the one being changed by words.
    private struct ShownCard {
        let draft: TransactionDraft
        let note: String?
        let said: String
        /// Being changed: no buttons and no rows to open until Milu answers.
        let isFixing: Bool
    }

    private var shownCard: ShownCard? {
        if let fixing {
            return ShownCard(draft: fixing.draft, note: fixing.note, said: fixing.said, isFixing: true)
        }
        if case .result(.card(let draft, let note)) = phase {
            return ShownCard(draft: draft, note: note, said: said, isFixing: false)
        }
        return nil
    }

    @ViewBuilder
    private func cardBlock(_ card: ShownCard) -> some View {
        if let note = card.note { words(note).transition(rises) }
        // Huỷ and Lưu inside the card, under its tear (user feedback 2026-11-17); greyed while it
        // is being changed, its words to be had first, rather than gone: the card one height
        // throughout (user request 2026-11-19, no height changing between the mic and the keys).
        DraftCard(draft: card.draft, onRow: { id in
            guard !card.isFixing, card.draft.isPending, let row = card.draft.row(id) else { return }
            editingRow = AssistantView.EditingRow(row: row)
        }, actions: AnyView(HStack(spacing: Spacing.s) {
            MiluButton("Huỷ", role: .secondary, fullWidth: true) { close() }
            MiluButton(card.draft.liveRows.count > 1 ? "Lưu cả \(card.draft.liveRows.count)" : "Lưu",
                       role: .primary, fullWidth: true) { save(card.draft) }
        }
        .disabled(card.isFixing)), opensRows: !card.isFixing)
        .transition(rises)
    }

    @ViewBuilder
    private func resultView(_ result: QuickRecordResult) -> some View {
        // The card's sentence is over the card (`content`); a question while one changes it has
        // the card over it.
        if fixing == nil, !isCard(result) { saidLine(said) }
        switch result {
        // Under the card, with it (`underCard`).
        case .card:
            EmptyView()
        case .asking(let question, let choices):
            asking(question, choices: choices)
        case .refused(let message, let form):
            words(message)
                .transition(rises)
            if let form {
                MiluButton(form.title, role: .primary, fullWidth: true) { open(.form(form)) }
                    .transition(follows)
            }
            againButton("Nói khoản khác")
                .transition(follows)
        case .notRecord:
            words(Copy.notRecord)
                .transition(rises)
            MiluButton("Mở Hỏi Milu", role: .primary, fullWidth: true) { open(.chat(said)) }
                .transition(follows)
            againButton("Nói lại")
                .transition(follows)
        }
    }

    /// Milu's question back, answers to tap, and a bar to answer in one's own words; "Giữ như cũ"
    /// under it while a card is being changed.
    @ViewBuilder
    private func asking(_ question: String, choices: [String]) -> some View {
        words(question)
            .matchedGeometryEffect(id: "question", in: flow, properties: .position, anchor: .topLeading)
            .transition(rises)
        if !choices.isEmpty {
            FlowLayout(spacing: Spacing.s) {
                ForEach(choices, id: \.self) { choice in
                    TagChip(title: choice, isProminent: false) { send(choice) }
                        .fixedSize()
                }
            }
            .transition(follows)
        }
        VStack(alignment: .trailing, spacing: Spacing.s) {
            bar(Copy.answerBar, keyboard: "Gõ câu trả lời", mic: "Nói câu trả lời",
                onKeyboard: { startTyping() }, onMic: { listen() })
            // Under the bar, at its end, as under the field it opens into.
            if fixing != nil {
                keepButton
                    .padding(.horizontal, Spacing.l)
            }
        }
        .transition(follows)
    }

    private func savedView(_ count: Int) -> some View {
        VStack(spacing: Spacing.m) {
            SavedMark()
            Text(count > 1 ? "Đã lưu \(count) khoản" : "Đã lưu")
                .textRole(.title)
                .transition(rises)
            againButton("Ghi tiếp")
                .transition(follows)
        }
        .frame(maxWidth: .infinity)
    }

    private func failedView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            saidLine(said)
            words(message)
            HStack(spacing: Spacing.s) {
                MiluButton("Nói lại", role: .secondary, fullWidth: true) { startOver() }
                MiluButton("Thử lại", role: .primary, fullWidth: true) { send(said) }
            }
        }
    }

    // MARK: - Phần nhỏ

    /// What the user said, small, over the answer: the words of the step before, moved up and
    /// made small.
    @ViewBuilder
    private func saidLine(_ said: String) -> some View {
        if !said.isEmpty {
            Text("“\(said)”")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .lineLimit(3)
                .matchedGeometryEffect(id: "said", in: flow, properties: .position, anchor: .topLeading)
                .transition(leaves)
        }
    }

    /// Milu's words, **bold** and "• " lines kept, as the chat sets them.
    private func words(_ text: String) -> some View {
        Text(MessageRow.formatted(text))
            .textRole(.body)
            .foregroundStyle(Palette.label)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Starts over: what was said and answered goes, the mic listens again.
    private func againButton(_ title: String) -> some View {
        Button {
            startOver()
        } label: {
            Label(title, systemImage: "mic")
                .textRole(.button)
                .foregroundStyle(Palette.primary)
                .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Under a question back, to answer it in one's own words, and under a card, to change it:
    /// the card's last row alone, the same two buttons where the card will have them, so it opens
    /// into the card rather than being two discs at the sheet's two ends. What is said goes on
    /// with the exchange.
    private func bar(_ text: String, keyboard: String, mic: String,
                     onKeyboard: @escaping () -> Void, onMic: @escaping () -> Void) -> some View {
        HStack(spacing: Spacing.m) {
            roundButton("keyboard", label: keyboard, action: onKeyboard)
            Text(text)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
            mainButton("mic.fill", label: mic, action: onMic)
        }
        .padding(Spacing.m)
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous))
        // The words between the buttons open the keyboard, as a field would.
        .contentShape(Rectangle())
        .onTapGesture(perform: onKeyboard)
    }

    /// While a card is being changed: back to it as it was, and to its buttons. As small as the
    /// line it is on, its tap 44 high all the same: the room around it is touched, not laid out.
    private var keepButton: some View {
        Button {
            keepCard()
        } label: {
            Label(Copy.keep, systemImage: "arrow.uturn.backward")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.primary)
                .fixedSize()
                .padding(.vertical, Spacing.m)
                .padding(.horizontal, Spacing.s)
                .contentShape(Rectangle())
                .padding(.vertical, -Spacing.m)
                .padding(.horizontal, -Spacing.s)
        }
        .buttonStyle(.plain)
    }

    private func isCard(_ result: QuickRecordResult) -> Bool {
        if case .card = result { true } else { false }
    }

    /// ⌨ and the mic: a glyph on a disc of the sheet's white, on the card; the main button's
    /// size (user report 2026-11-18: at 44 beside its 56, the two did not match).
    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: IconSize.control))
                .foregroundStyle(Palette.label)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: ControlHeight.regular, height: ControlHeight.regular)
                .background(Palette.surface, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// ■, ↑, the mic: the card's one main action, on the primary disc.
    private func mainButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: IconSize.control, weight: .semibold))
                .foregroundStyle(Palette.onPrimary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: ControlHeight.regular, height: ControlHeight.regular)
                .background(Palette.primary, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// Each step a number, for `frameProbe` to see the frames of the step's animation.
    private var stepNumber: Double {
        let index: Double = switch phase {
        case .listening: 0
        case .typing: 1
        case .thinking: 2
        case .result: 3
        case .saved: 4
        case .failed: 5
        case .heardNothing: 6
        }
        return index + (transcribing ? 0.5 : 0) + (fixing != nil ? 10 : 0)
    }

    #if DEBUG
    /// Run with `MILU_DEMO` (and two sentences in `MILU_FAKE_VOICE`), the sheet goes through its
    /// steps by itself, for `FrameLog` to measure on an iPhone with no hand on it: the sentence,
    /// its card, a change said under it, the keyboard up and down, then closed.
    private func runDemo() async {
        guard ProcessInfo.processInfo.environment["MILU_DEMO"] != nil else { return }
        func pause(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
        func cardShown() async -> Bool {
            for _ in 0..<160 {
                if case .result(.card(let draft, _)) = phase, draft.isPending, fixing == nil { return true }
                await pause(0.25)
            }
            return false
        }
        // MILU_DEMO=type: the field tapped as soon as the sheet is up, a sentence typed, its
        // card, a change typed under the card, then closed.
        if ProcessInfo.processInfo.environment["MILU_DEMO"] == "type" {
            func type(_ words: String) async {
                for character in words {
                    typed.append(character)
                    await pause(0.03)
                }
            }
            await pause(2.5)
            tapField()
            await pause(3)
            await type("Cà phê 35k, gửi xe 5k")
            await pause(1)
            send(typed)
            guard await cardShown() else { return }
            await pause(2)
            tapField()
            await pause(2.5)
            await type("gửi xe 10k thôi")
            await pause(1)
            send(typed)
            await pause(0.5)
            guard await cardShown() else { return }
            await pause(2)
            close()
            return
        }
        // MILU_DEMO=wrong: a sentence Milu cannot record (the fake voice's first), then a long
        // one typed under its answer, its card, a change typed under the card, then closed.
        if ProcessInfo.processInfo.environment["MILU_DEMO"] == "wrong" {
            func type(_ words: String) async {
                for character in words {
                    typed.append(character)
                    await pause(0.03)
                }
            }
            for _ in 0..<160 {
                if case .result(let result) = phase, !isCard(result) { break }
                await pause(0.25)
            }
            await pause(1.5)
            tapField()
            // Long enough to turn the Simulator's on-screen keyboard on by hand.
            await pause(7)
            await type("Cà phê 35k, gửi xe 5k, ăn trưa 50k với bạn ở quán gần công ty hôm nay")
            await pause(1)
            if ProcessInfo.processInfo.environment["MILU_DEMO_KEYS"] != nil {
                isTyping = false
                await pause(1.5)
            }
            send(typed)
            guard await cardShown() else { return }
            await pause(1.5)
            tapField()
            await pause(1.2)
            await type("gửi xe 10k thôi")
            await pause(0.6)
            send(typed)
            await pause(0.5)
            guard await cardShown() else { return }
            await pause(1.5)
            close()
            return
        }
        guard await cardShown() else { return }
        await pause(1.5)
        fix(typing: false)
        await pause(0.5)
        guard await cardShown() else { return }
        await pause(1.5)
        fix(typing: true)
        await pause(1.5)
        keepCard()
        await pause(1.5)
        close()
    }
    #endif

    // MARK: - Hành động

    /// The mic on, the words heard showing; what was asked back stays, for an answer to it.
    private func listen() {
        transcribing = false
        isTyping = false
        note = nil
        typed = ""
        phase = .listening
        var seen = Set<String>()
        dictation.hotwords = (store.accounts.map(\.name) + Institution.all.map(\.shortName)).filter { seen.insert($0).inserted }
        Task { await dictation.start() }
    }

    /// From the start: nothing said, nothing asked; the mic on, or the keyboard.
    private func startOver(typing: Bool = false) {
        closing?.cancel()
        answering?.cancel()
        history = []
        said = ""
        asked = nil
        fixing = nil
        fixNote = nil
        fixWords = nil
        if typing { startTyping() } else { listen() }
    }

    /// The bar under the card: what to change in it, said or typed, the card staying over it.
    private func fix(typing: Bool) {
        guard case .result(.card(let draft, let note)) = phase, draft.isPending else { return }
        fixing = Fixing(draft: draft, note: note, said: said, history: history)
        fixNote = nil
        fixWords = nil
        asked = nil
        if typing { startTyping() } else { listen() }
    }

    /// "Giữ như cũ", or words that changed nothing: the card as it was, its buttons back, and
    /// the exchange as it was too, so Milu is not left with the words that came to nothing.
    private func keepCard() {
        guard let fixing else { return }
        answering?.cancel()
        if dictation.isRecording { dictation.stop() }
        transcribing = false
        isTyping = false
        typed = ""
        note = nil
        history = fixing.history
        said = fixing.said
        asked = nil
        self.fixing = nil
        phase = .result(.card(fixing.draft, note: fixing.note))
    }

    /// The field, and the keyboard with it, the sheet taking its new height as the keyboard
    /// rises (user report 2026-11-19: iOS's sheet first, then the keyboard 0.4 s after, read as a
    /// stop). The focus a moment later, once the field is there.
    private func startTyping() {
        phase = .typing
        Task { @MainActor in isTyping = true }
    }

    /// Slides the sheet away (`BottomPanel`); iOS's dismiss outside one.
    private func close() {
        if let panelControl { panelControl.close() } else { dismiss() }
    }

    /// ■, or a pause: the words turned into text (the server's when it has them), then sent.
    private func finishListening() {
        guard dictation.isRecording else { return }
        // No words in the card until the server's (the phone's, should it not answer).
        said = ""
        transcribing = true
        phase = .thinking
        Task {
            guard let heard = await dictation.finish() else {
                transcribing = false
                return
            }
            dictation.endTranscribing()
            transcribing = false
            let words = heard.trimmingCharacters(in: .whitespacesAndNewlines)
            if words.isEmpty {
                phase = .heardNothing
            } else {
                send(words)
            }
        }
    }

    /// The sentence to Milu, with the record tool alone (`RemoteAssistant.onlyTools`), or to the
    /// keyword assistant when no server is set.
    private func send(_ text: String) {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty else { return }
        // "ok", "lưu đi" under the card: saved, as its button does, with no question to Milu;
        // "thôi", "huỷ": the card kept as it was, the sheet still open (Huỷ on the card closes
        // it). Not as the answer to a question: "đúng rồi" there answers it.
        if let fixing, asked == nil, let answer = DraftShortcut.match(words) {
            keepCard()
            if answer == .save { save(fixing.draft) }
            return
        }
        isTyping = false
        said = words
        typed = ""
        fixNote = nil
        fixWords = nil
        phase = .thinking
        Haptics.selection()
        let before = history
        let fixed = fixing
        let store = store
        answering?.cancel()
        answering = Task {
            let reply: AssistantReply
            do {
                if let api = MiluAPI.shared {
                    reply = try await RemoteAssistant(api: api, store: store, onlyTools: [RecordTransaction().name])
                        .reply(to: words, history: before) { _ in }
                } else {
                    try await Task.sleep(for: .seconds(0.6))
                    reply = MockAssistant(store: store).record(words)
                }
            } catch is CancellationError {
                return
            } catch {
                if Task.isCancelled { return }
                let message = (error as? LocalizedError)?.errorDescription ?? Copy.failed
                // Changing a card, it is still there to save: back to it, why under it.
                if fixed != nil { return keep(saying: message, to: words) }
                phase = .failed(message)
                return
            }
            if Task.isCancelled { return }
            let result = QuickRecordResult.of(reply, said: words)
            var before = before
            if let fixed {
                switch QuickRecordFix.of(result, refused: reply.refused, before: fixed.draft) {
                case .unchanged(let why): return keep(saying: why, to: words)
                case .asked: break
                case .changed:
                    // The card it was waits no more, for Milu as for the sheet.
                    before = QuickRecordFix.replacing(fixed.draft.id, in: before)
                    fixing = nil
                    // Changed, its sentence stays over it; a new one entirely, the new words.
                    if case .card(let draft, _) = result, draft.replacing != nil { said = fixed.said }
                }
            }
            let card: ChatMessage.Card? = if case .card(let draft, _) = result { .draft(draft) } else { nil }
            history = before + [ChatMessage(role: .user, text: words),
                                ChatMessage(role: .assistant, text: reply.text, card: card)]
            Haptics.selection()
            // Asked back, the question stays over the answer to it; anything else ends it.
            if case .asking(let question, _) = result { asked = question } else { asked = nil }
            phase = .result(result)
            AccessibilityNotification.Announcement(Self.spoken(result, fixed: fixed != nil)).post()
        }
    }

    /// The card back as it was, the words that came to nothing said under it.
    private func keep(saying why: String, to words: String) {
        keepCard()
        fixNote = why
        fixWords = words
        Haptics.warning()
        AccessibilityNotification.Announcement(why).post()
    }

    /// "Lưu": all of it, or none with why on the card (`DraftSaver`); saved, the sheet says so
    /// and closes by itself a moment later, unless "Ghi tiếp".
    private func save(_ draft: TransactionDraft) {
        let saved = DraftSaver.save(draft, in: store)
        guard saved.state == .saved else {
            Haptics.warning()
            setCard(saved)
            return
        }
        Haptics.milestone()
        let count = saved.liveRows.count
        phase = .saved(count: count)
        AccessibilityNotification.Announcement(count > 1 ? "Đã lưu \(count) khoản" : "Đã lưu").post()
        closing = Task {
            try? await Task.sleep(for: .seconds(1.2))
            if !Task.isCancelled, case .saved = phase { close() }
        }
    }

    /// The form or the chat, once the sheet has gone.
    private func open(_ next: QuickRecordNext) {
        onNext(next)
        close()
    }

    /// The card as it now is, and so for Milu too: words to change it go from this one, not
    /// the one it first made.
    private func setCard(_ draft: TransactionDraft) {
        guard case .result(.card(_, let note)) = phase else { return }
        phase = .result(.card(draft, note: note))
        history = QuickRecordFix.updating(draft, in: history)
    }

    /// A row of the card changed in its form, or taken off it.
    private func changeCard(_ change: (TransactionDraft) -> TransactionDraft) {
        guard case .result(.card(let draft, _)) = phase, draft.isPending else { return }
        setCard(change(draft))
    }

    /// What VoiceOver says as the answer comes.
    private static func spoken(_ result: QuickRecordResult, fixed: Bool) -> String {
        switch result {
        case .card where fixed: "Milu đã sửa thẻ, bạn kiểm tra rồi bấm Lưu"
        case .card(let draft, _):
            draft.liveRows.count > 1 ? "Milu soạn \(draft.liveRows.count) khoản, bạn kiểm tra rồi bấm Lưu" : "Milu soạn xong, bạn kiểm tra rồi bấm Lưu"
        case .asking(let question, _): SpokenText.of(String(MessageRow.formatted(question).characters))
        case .refused(let message, _): SpokenText.of(String(MessageRow.formatted(message).characters))
        case .notRecord: Copy.notRecord
        }
    }
}

/// Under the card while it listens: that a pause sends what was said, then, over the last
/// seconds of listening, how many are left (`ListeningCountdown`, as the chat's field counts
/// them before its wave). Said once by VoiceOver as the count comes.
private struct ListeningTip: View {
    let startedAt: Date
    let text: String

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.25)) { timeline in
            if let left = ListeningCountdown.left(at: timeline.date, since: startedAt) {
                Text("Còn \(left) giây")
                    .monospacedDigit()
                    .onAppear {
                        AccessibilityNotification.Announcement("Còn \(left) giây").post()
                    }
            } else {
                Text(text)
            }
        }
    }
}

/// "Đã lưu": the ✓ comes in with a small bounce, as the card goes (user request 2026-11-18: it
/// sat there, still, the card fading under it). Still with Reduce Motion.
private struct SavedMark: View {
    @State private var shown = false

    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: IconSize.control, weight: .semibold))
            .foregroundStyle(Palette.income)
            .symbolEffect(.bounce, value: shown)
            .frame(width: 52, height: 52)
            .background(Palette.incomeSoft, in: Circle())
            .scaleEffect(shown ? 1 : 0.4)
            .opacity(shown ? 1 : 0)
            .accessibilityHidden(true)
            .animation(Motion.gentle(.spring(duration: 0.45, bounce: 0.45)), value: shown)
            .onAppear { shown = true }
    }
}

/// Words coming in one after another, each from a blur into its place (user request
/// 2026-11-19: the words said or typed in the greeting's place, over a chat bubble). Before iOS
/// 18 they fade in whole; under Reduce Motion, there at once.
private struct RevealingWords: View {
    let text: String
    @State private var progress: Double = 0

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                Text(text).textRenderer(GlyphReveal(progress: progress))
            } else {
                Text(text).opacity(progress)
            }
        }
        .accessibilityLabel(text)
        // Its own curve, on the words themselves: the sheet stills what comes from outside.
        .animation(Motion.gentle(.easeOut(duration: Self.duration(for: text))), value: progress)
        .onAppear { progress = 1 }
    }

    /// Longer for more words, never long: the card is on its way.
    private static func duration(for text: String) -> Double {
        min(0.45 + Double(text.count) * 0.012, 1.1)
    }
}

/// Each glyph from transparent, a little blurred and low, to its place, one after another
/// along the lines.
@available(iOS 18.0, *)
private struct GlyphReveal: TextRenderer {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// The share of the time over which the glyphs start; each takes the rest to come in.
    private static var spread: Double { 0.6 }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.flatMap { $0 }.flatMap { $0 }
        let count = Double(max(slices.count, 1))
        for (index, slice) in slices.enumerated() {
            let start = Double(index) / count * Self.spread
            let shown = min(max((progress - start) / (1 - Self.spread), 0), 1)
            var glyph = context
            glyph.opacity = shown
            if shown < 1 {
                glyph.addFilter(.blur(radius: (1 - shown) * 3))
                glyph.translateBy(x: 0, y: (1 - shown) * 4)
            }
            glyph.draw(slice)
        }
    }
}

/// While what scrolls over the field shrinks (a line more typed), its foot kept in view: the
/// card's buttons stay by the field, its top going under the bar, as the chat's messages do.
private struct KeepsFootInView: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.defaultScrollAnchor(.bottom, for: .sizeChanges)
        } else {
            content
        }
    }
}
