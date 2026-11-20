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
    /// The page it runs in, put up by UIKit (`QuickRecordController.present`).
    @Environment(\.quickPageLink) private var quickPageLink
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
    /// The keyboard on the small field's words (`QuickWordsField`), or on the panel's
    /// (`panelFocus`).
    @State private var isTyping = false
    @FocusState private var panelFocus: Bool
    /// Sentences sent: each rises from the field into its bubble (`QuickRecordController.fly`).
    @State private var sends = 0
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

    /// Milu's last answer that is not a card, with the words it answers: over the field until
    /// the next answer takes its place, through the next sentence said or typed (`upper`).
    @State private var last: Held?

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
        // Milu's answer kept for `upper` until the next one.
        .onChange(of: phase) { old, new in
            Self.trace("phase \(String(describing: old).prefix(24)) -> \(String(describing: new).prefix(24))")
            switch new {
            case .result(.card), .saved: last = nil
            case .result, .failed: last = Held(result: new, said: said)
            default: break
            }
        }
        .onAppear { listen() }
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
                    SaidBubble(text: fixWords)
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
    /// The sheet's height follows what is over the field and never the field, one line tall
    /// in every step. It changes only when Milu
    /// answers or a record is saved (`fitSheet`), and the field stays where it is on the screen
    /// while it does (`fieldRow`).
    private var nativeSheet: some View {
        // Seen nowhere: the page (`QuickRecordController`) shows the step.
        QuickSheetBridge(
            state: sheetState,
            onDraftChange: { if typed != $0 { typed = $0 } },
            onSend: { send(typed) },
            onFocus: { if isTyping != $0 { isTyping = $0 } },
            onTapField: tapField
        )
        .frameProbe("step", value: stepNumber)
    }

    /// The page as this step has it (`QuickRecordController`).
    private var sheetState: QuickSheetState {
        let listens = phase == .listening
        let waits = phase == .thinking
        return QuickSheetState(
            upper: AnyView(nativeUpper),
            sent: sends,
            sentWords: said,
            keepsUpper: fixing != nil,
            draft: typed,
            placeholder: fieldHint,
            fieldLabel: asked != nil ? "Câu trả lời" : fixing != nil ? "Điều cần sửa" : "Khoản muốn ghi",
            focused: isTyping,
            canEdit: phase == .typing,
            isDictating: listens || waits,
            showsLeading: listens,
            isLit: waits,
            showsField: showsField,
            leading: AnyView(chatRoundButton("xmark", label: "Huỷ nhập giọng nói") { cancelListening() }),
            stop: AnyView(chatRoundButton("stop.fill", label: "Xong, chuyển thành chữ") { finishListening(sends: false) }),
            action: AnyView(chatAction),
            overlay: AnyView(fieldOverlay)
        )
    }

    /// Over the field (user design 2026-11-20, as a chat that keeps only its last exchange): what
    /// to say; the sentence sent, in its bubble, Milu's answer under it; a card alone, the words
    /// said to change it and Milu's word on them under it. A sentence sent takes the place of all
    /// that was there but a card being changed (`QuickRecordController.leaveUpper`).
    private var nativeUpper: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            if case .saved(let count) = phase {
                savedView(count)
                    .transition(leaves)
            } else if let card = shownCard {
                nativeCard(card)
                if let words = wordsUnderCard {
                    // A bubble of its own for each sentence: the last one's words changed in place
                    // to the new ones and stood there, fading, as the new one's flyer came (video
                    // 2026-11-20); now the last one fades and the new one waits for its flyer.
                    SaidBubble(text: words)
                        .id(words)
                        .transition(.opacity.animation(Motion.gentle(.easeOut(duration: 0.15))))
                }
                if showsFixNote, let fixNote {
                    words(fixNote)
                        .transition(answerArrives)
                }
            } else if let words = topWords {
                SaidBubble(text: words)
                    .id(sends)
                    .transition(.opacity.animation(Motion.gentle(.easeOut(duration: 0.15))))
                if let answer = shownAnswer {
                    answerBody(answer)
                }
            } else {
                greeting(heardNothing: phase == .heardNothing)
                    .id(phase == .heardNothing)
                    .transition(arrives)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.gentle(Self.step), value: phase)
    }

    /// Under the card: the words being sent to change it, then, if they changed nothing, those
    /// words with Milu's why under them.
    private var wordsUnderCard: String? {
        if fixing != nil, phase == .thinking, !transcribing, !said.isEmpty { return said }
        if showsFixNote { return fixWords }
        return nil
    }

    /// Milu's why under the card, with the words it answers: while the card rests, and while the
    /// next words are said or typed to it, until they go.
    private var showsFixNote: Bool {
        guard fixNote != nil else { return false }
        if restsUnderCard { return true }
        return fixing != nil && (phase == .listening || phase == .typing || phase == .heardNothing
                                 || (phase == .thinking && transcribing))
    }

    /// The sentence at the top with no card: the one sent; the last one answered while the next
    /// is said or typed, or while the voice turns into words; none when nothing was heard.
    private var topWords: String? {
        switch phase {
        case .heardNothing: return nil
        case .thinking where !transcribing: return said.isEmpty ? nil : said
        default:
            if let held, !held.said.isEmpty { return held.said }
            return nil
        }
    }

    /// In the field's words' place: the wave while one speaks, the voice turning into words, then
    /// Milu at work (the chat's `dictationStatus`).
    private var fieldOverlay: some View {
        let swap = AnyTransition.asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.2).delay(0.1)),
                                            removal: .opacity.animation(.easeOut(duration: 0.12)))
        return ZStack(alignment: .leading) {
            if phase == .listening {
                HStack(spacing: 0) {
                    ListeningCountdown(startedAt: dictation.startedAt)
                    VoiceWaveform(dictation: dictation)
                }
                .transition(swap)
            } else if phase == .thinking {
                TranscribingStatus(text: transcribing ? Copy.transcribing : Copy.composing,
                                   spoken: transcribing ? "Milu đang chuyển giọng nói thành chữ" : Copy.composing)
                    .padding(.leading, Spacing.s)
                    .transition(swap)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(Motion.gentle(.easeOut(duration: 0.2)), value: transcribing)
    }

    /// The chat's ✕ and ■ while listening: a glyph on a grey disc (`AssistantView.roundButton`).
    private func chatRoundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: IconSize.inline + 2, weight: .semibold))
                .foregroundStyle(Palette.label)
                .frame(width: Self.fieldButton, height: Self.fieldButton)
                .background(Palette.background, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// The chat's last button (`AssistantView.actionButton`): the mic; ↑ once there is something
    /// to send, or while one speaks; dim while Milu works.
    private var chatAction: some View {
        let listens = phase == .listening
        let waits = phase == .thinking
        let sends = listens || (phase == .typing && !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        return Button {
            if listens { finishListening() } else if sends { send(typed) } else { speak() }
        } label: {
            ZStack {
                Circle()
                    .fill(Palette.primary)
                    .scaleEffect(sends ? 1 : 0.4)
                    .opacity(sends ? 1 : 0)
                Image(systemName: "mic")
                    .font(.system(size: IconSize.control))
                    .foregroundStyle(Palette.secondaryLabel)
                    .scaleEffect(sends ? 0.4 : 1)
                    .opacity(sends ? 0 : 1)
                Image(systemName: "arrow.up")
                    .font(.system(size: IconSize.bar, weight: .semibold))
                    .foregroundStyle(Palette.onPrimary)
                    .scaleEffect(sends ? 1 : 0.4)
                    .opacity(sends ? 1 : 0)
            }
            .frame(width: Self.fieldButton, height: Self.fieldButton)
            .opacity(waits ? 0.4 : 1)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(waits)
        .animation(Motion.gentle(.spring(duration: 0.3, bounce: 0.25)), value: sends)
        .animation(Motion.gentle(.easeOut(duration: 0.2)), value: waits)
        .accessibilityLabel(listens ? "Xong, gửi cho Milu" : sends ? "Gửi cho Milu" : "Nói với Milu")
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

    /// Milu's answer over the field: the last one, kept while the next sentence is said or typed,
    /// gone once it is sent.
    private var shownAnswer: Held? {
        phase == .thinking && !transcribing ? nil : held
    }

    /// Milu's last answer that is not a card, with its words: the one just in as soon as the step
    /// is its, else the one kept (`last`). Read from `last` alone, the step's first frame drew the
    /// answer before, and its words, then the new ones: a second sentence sent after "Bạn đang làm
    /// gì thế", its bubble blinked (user report 2026-11-19).
    private var held: Held? {
        switch phase {
        case .result(.card), .saved: nil
        case .result, .failed: Held(result: phase, said: said)
        default: last
        }
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
                .transition(cardArrives)
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
        .transition(cardArrives)
    }

    /// Milu's answer that is not a card: its question and the answers to tap, or what it cannot
    /// record and where to do it.
    @ViewBuilder
    private func answerBody(_ answer: Held) -> some View {
        switch answer.result {
        case .result(.asking(let question, let choices)):
            words(question)
                .transition(answerArrives)
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
                .transition(answerArrives)
            if let form {
                MiluButton(form.title, role: .primary, fullWidth: true) { open(.form(form)) }
                    .transition(follows)
            }
        case .result(.notRecord):
            words(Copy.notRecord)
                .transition(answerArrives)
        case .failed(let message):
            words(message)
                .transition(answerArrives)
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

    /// What the field says while there is nothing in it: by what is over it, not by the step,
    /// so it does not change as one begins to type.
    private var fieldHint: String {
        if phase == .heardNothing { return Copy.sayAgain }
        if asked != nil { return Copy.answerHint }
        if shownCard != nil { return Copy.fixShort }
        if held != nil { return Copy.another }
        return Copy.fieldHint
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
            .focused($panelFocus)
            .onChange(of: panelFocus) { _, focus in if isTyping != focus { isTyping = focus } }
            .onChange(of: isTyping) { _, typing in if panelFocus != typing { panelFocus = typing } }
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

    /// Milu's card coming in where the sentence was, as that one fades: at once, rising a
    /// little, so the two cross rather than leaving the sheet empty a moment while it grows
    /// (user report 2026-11-20: the card's arrival "chưa mượt", video: the bubble faded, the
    /// sheet stood empty for a few frames, then the card came 14 points from under).
    private var cardArrives: AnyTransition {
        .asymmetric(insertion: .opacity.combined(with: .offset(y: 8))
                        .animation(Motion.gentle(.smooth(duration: 0.35))),
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
    /// Milu's words, the chat's own (`AnswerWords`): selectable, and shown one word after another
    /// as they come, as an answer in the chat (user request 2026-11-20: "đồng bộ" with the chat).
    private func words(_ text: String) -> some View {
        let formatted = MessageRow.formatted(text)
        return AnswerWords(text: formatted, reveals: true)
            .accessibilityLabel(SpokenText.of(String(formatted.characters)))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Milu's words coming in: their own word-by-word showing (`words`), no fade over it, as in
    /// the chat; going, a quick fade.
    private var answerArrives: AnyTransition {
        .asymmetric(insertion: .identity, removal: .opacity.animation(Motion.gentle(.easeOut(duration: 0.12))))
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
        func type(_ words: String) async {
            for character in words {
                typed.append(character)
                await pause(0.03)
            }
        }
        // MILU_DEMO=lines: the field tapped, a sentence long enough for five lines on one, then
        // erased, to watch the field grow and the button stay put.
        if ProcessInfo.processInfo.environment["MILU_DEMO"] == "lines" {
            await pause(2.5)
            tapField()
            await pause(2)
            // Marks over and under the words first: the line must not move (user report
            // 2026-11-20, "ạ" typed and the words jumped).
            await type("ạ ạ Ặ ỹ")
            await pause(1)
            await type(" Cà phê sữa đá 35k, gửi xe 5k, bánh mì 20k, trà sữa trân châu 45k, cơm trưa văn phòng 50k, đổ xăng 80k, ạ")
            await pause(1.5)
            while !typed.isEmpty {
                typed.removeLast()
                await pause(0.015)
            }
            return
        }
        // MILU_DEMO=gap: a card, then under it a sentence that is not a change, then another,
        // then a change (user report 2026-11-20: at the second sentence, an empty space).
        if ProcessInfo.processInfo.environment["MILU_DEMO"] == "gap" {
            func rests() async -> Bool {
                for _ in 0..<160 {
                    if case .result(.card) = phase, fixing == nil { return true }
                    await pause(0.25)
                }
                return false
            }
            await pause(2.5)
            tapField()
            await pause(2)
            await type("Ăn sáng hết 40k")
            await pause(0.8)
            send(typed)
            guard await rests() else { return }
            for words in ["Bạn đang làm gì thế", "Hôm nay trời đẹp ghê", "sửa thành 30k"] {
                await pause(2.5)
                tapField()
                await pause(1.2)
                await type(words)
                await pause(0.8)
                send(typed)
                await pause(0.5)
                guard await rests() else { return }
            }
            await pause(2.5)
            if case .result(.card(let draft, _)) = phase { save(draft) }
            return
        }
        if ProcessInfo.processInfo.environment["MILU_DEMO"] == "type" {
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
        // MILU_DEMO=offtopic: sentences that are not a record one after another, said, said again
        // and typed, to watch the bubble give way to the next and the voice's two steps.
        if ProcessInfo.processInfo.environment["MILU_DEMO"] == "offtopic" {
            func answered() async {
                for _ in 0..<160 {
                    if case .result = phase { return }
                    if case .failed = phase { return }
                    await pause(0.25)
                }
            }
            await answered()
            await pause(2)
            speak()
            await pause(0.5)
            await answered()
            await pause(2)
            tapField()
            await pause(1.5)
            await type("bạn tên là gì")
            await pause(0.8)
            send(typed)
            await answered()
            return
        }
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
        // The last words and Milu's why stay under the card until the next words go (user
        // design 2026-11-20: the last exchange gives way as the next sentence rises).
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
        if let panelControl {
            panelControl.close()
        } else if let page = quickPageLink?.page {
            page.close()
        } else {
            dismiss()
        }
    }

    /// ■, or a pause: the words turned into text (the server's when it has them), then sent.
    private func finishListening(sends: Bool = true) {
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
            } else if sends {
                send(words)
            } else {
                // ■: the words into the field, to change before they go, as in the chat.
                typed = words
                startTyping()
            }
        }
    }

    /// ✕ while listening: nothing heard is kept; the card as it was when one was changing it, else
    /// the field to type in.
    private func cancelListening() {
        dictation.stop()
        if fixing != nil {
            keepCard()
        } else {
            phase = .typing
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
        sends += 1
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

/// The words said or typed, in the chat's bubble (`UserBubble`): set as the field sets them, so
/// they break where they did as they were typed, and the same bubble the sentence rose in from the
/// field (`QuickRecordController.fly`). Hidden while that one is on its way, and saying where it
/// is for it to land on.
private struct SaidBubble: View {
    let text: String
    @Environment(\.quickSaidHidden) private var hidden
    @Environment(\.quickSaidFrame) private var report

    var body: some View {
        UserBubble(text: text)
            .opacity(hidden ? 0 : 1)
            // At once: on the step's curve it was still there, fading, as its flyer came.
            .animation(nil, value: hidden)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(QuickUpper.space)) } action: { frame in
                report?(frame)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

