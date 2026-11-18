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
    /// The words said and the question move from one step to the next rather than blinking.
    @Namespace private var flow

    enum Phase: Equatable {
        case listening
        case typing
        case thinking
        case result(QuickRecordResult)
        case saved(count: Int)
        case failed(String)
        case heardNothing
    }

    var body: some View {
        // Milu at work, the card animates its own lines as the words come: the sheet slides with
        // a line more, where otherwise it takes so small a change at once.
        SheetScaffold(title: "Thêm bằng AI", fitsContent: true, fitStep: phase == .thinking ? 4 : 44) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(Motion.gentle(.snappy), value: phase)
            // The server's words in: they fade into the card, "Milu đang soạn" under them. A long
            // sentence opens the card while the sheet rises, and the line under the words should
            // stay where it is on the screen: the card a little slower than the sheet (0.35 s),
            // which starts a frame after it (measured on the Simulator, 2026-11-18, the card's
            // foot through the move: at 0.35 s it dipped 6pt; 0.05 s late it rose 13pt; at 0.4 s
            // it stays within 5pt).
            .animation(Motion.gentle(.smooth(duration: 0.4)), value: transcribing)
        }
        .onAppear { listen() }
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
    @ViewBuilder
    private var content: some View {
        switch phase {
        case .listening, .typing, .heardNothing, .thinking: input.transition(leaves)
        case .result(let result): resultView(result)
        case .saved(let count): savedView(count).transition(leaves)
        case .failed(let message): failedView(message).transition(leaves)
        }
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
    ///   card as it comes, the sheet with it (`SheetScaffold.fitStep`).
    private var input: some View {
        let waiting = phase == .thinking
        return VStack(alignment: .leading, spacing: Spacing.l) {
            if let asked { question(asked) }
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
                .strokeBorder(Palette.primary, lineWidth: 1.5)
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
        let hint = phase == .heardNothing ? Copy.heardNothing : (asked == nil ? Copy.hint : Copy.answerHint)
        return ZStack(alignment: .topLeading) {
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
                        // Answered, the words become the quote over Milu's answer.
                        .matchedGeometryEffect(id: "said", in: flow, properties: .position, anchor: .topLeading)
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
            .accessibilityLabel(asked == nil ? "Khoản muốn ghi" : "Câu trả lời")
    }

    /// The card's last row. The same two buttons in every state, of one size (user report
    /// 2026-11-18: ⌨ was small beside ■), their glyphs and actions changing in place: listening,
    /// ⌨ and ■ (done, send) with the wave between them; typing, the mic and ↑; nothing heard, ⌨
    /// and the mic again. While Milu composes there is nothing to press, and no row
    /// (`waitingLines`), rather than buttons left there dimmed.
    private var controls: some View {
        let listens = phase == .listening
        let typing = phase == .typing
        let empty = typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(spacing: Spacing.m) {
            roundButton(typing ? "mic" : "keyboard", label: typing ? "Nói thay vì gõ" : "Gõ thay vì nói") {
                if typing {
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
                       label: typing ? "Gửi cho Milu" : listens ? "Xong, gửi cho Milu" : "Nói lại") {
                if typing {
                    send(typed)
                } else if listens {
                    finishListening()
                } else if asked == nil {
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
    private var tip: some View {
        ZStack(alignment: .topLeading) {
            switch phase {
            case .listening:
                ListeningTip(startedAt: dictation.startedAt)
                    .transition(.opacity)
            case .typing:
                Text(note ?? (asked == nil ? Copy.typeTip : " "))
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
        static let hint = "Hôm nay bạn tiêu gì rồi? Kể Milu nghe, ví dụ: "
            + "“Cà phê 35k, gửi xe 5k”".replacingOccurrences(of: " ", with: "\u{00A0}")
        static let answerHint = "Câu trả lời của bạn"
        static let heardNothing = "Milu chưa nghe thấy giọng nói. Bạn hãy nói lại hoặc nhập bằng bàn phím."
        /// The pause that sends is otherwise a surprise.
        static let autoSendTip = "Milu tự gửi khi bạn ngừng nói \(Int(DictationAutoStop.pauseAfterWords)) giây."
        static let typeTip = "Có thể nhập nhiều khoản, cách nhau bằng dấu phẩy."
        static let transcribing = "Đang chuyển thành chữ"
        static let composing = "Milu đang soạn"
        static let answerBar = "Nói hoặc gõ câu trả lời"
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

    @ViewBuilder
    private func resultView(_ result: QuickRecordResult) -> some View {
        saidLine
        switch result {
        case .card(let draft, let note):
            if let note { words(note).transition(rises) }
            // Huỷ and Lưu inside the card, under its tear (user feedback 2026-11-17).
            DraftCard(draft: draft, onRow: { id in
                if draft.isPending, let row = draft.row(id) { editingRow = AssistantView.EditingRow(row: row) }
            }, actions: AnyView(HStack(spacing: Spacing.s) {
                MiluButton("Huỷ", role: .secondary, fullWidth: true) { dismiss() }
                MiluButton(draft.liveRows.count > 1 ? "Lưu cả \(draft.liveRows.count)" : "Lưu",
                           role: .primary, fullWidth: true) { save(draft) }
            }))
            .transition(rises)
            // From the start, the card dropped: "Nói lại" alone read as saying this card again.
            againButton("Nói lại từ đầu")
                .transition(follows)
        case .asking(let question, let choices):
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
            answerBar
                .transition(follows)
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
            saidLine
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
    private var saidLine: some View {
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

    /// Under a question back, to answer it in one's own words: the card's last row alone, the
    /// same two buttons where the card will have them, so it opens into the card rather than
    /// being two discs at the sheet's two ends. An answer goes on with the exchange.
    private var answerBar: some View {
        HStack(spacing: Spacing.m) {
            roundButton("keyboard", label: "Gõ câu trả lời") { startTyping() }
            Text(Copy.answerBar)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
            mainButton("mic.fill", label: "Nói câu trả lời") { listen() }
        }
        .padding(Spacing.m)
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous))
        // The words between the buttons open the keyboard, as a field would.
        .contentShape(Rectangle())
        .onTapGesture { startTyping() }
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

    /// From the start: nothing said, nothing asked.
    private func startOver() {
        closing?.cancel()
        answering?.cancel()
        history = []
        said = ""
        asked = nil
        listen()
    }

    /// The field, and the keyboard. From a question back the sheet first takes its new height,
    /// then the keyboard comes: both at once could leave the sheet too low (see `input`).
    private func startTyping() {
        let resizes: Bool = if case .result = phase { true } else { false }
        phase = .typing
        Task { @MainActor in
            if resizes { try? await Task.sleep(for: .milliseconds(400)) }
            isTyping = true
        }
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
        isTyping = false
        said = words
        typed = ""
        phase = .thinking
        Haptics.selection()
        let before = history
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
                phase = .failed((error as? LocalizedError)?.errorDescription ?? Copy.failed)
                return
            }
            if Task.isCancelled { return }
            let result = QuickRecordResult.of(reply, said: words)
            let card: ChatMessage.Card? = if case .card(let draft, _) = result { .draft(draft) } else { nil }
            history = before + [ChatMessage(role: .user, text: words),
                                ChatMessage(role: .assistant, text: reply.text, card: card)]
            Haptics.selection()
            // Asked back, the question stays over the answer to it; anything else ends it.
            if case .asking(let question, _) = result { asked = question } else { asked = nil }
            phase = .result(result)
            AccessibilityNotification.Announcement(Self.spoken(result)).post()
        }
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
            if !Task.isCancelled, case .saved = phase { dismiss() }
        }
    }

    /// The form or the chat, once the sheet has gone.
    private func open(_ next: QuickRecordNext) {
        onNext(next)
        dismiss()
    }

    private func setCard(_ draft: TransactionDraft) {
        guard case .result(.card(_, let note)) = phase else { return }
        phase = .result(.card(draft, note: note))
    }

    /// A row of the card changed in its form, or taken off it.
    private func changeCard(_ change: (TransactionDraft) -> TransactionDraft) {
        guard case .result(.card(let draft, _)) = phase, draft.isPending else { return }
        setCard(change(draft))
    }

    /// What VoiceOver says as the answer comes.
    private static func spoken(_ result: QuickRecordResult) -> String {
        switch result {
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

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.25)) { timeline in
            if let left = ListeningCountdown.left(at: timeline.date, since: startedAt) {
                Text("Còn \(left) giây")
                    .monospacedDigit()
                    .onAppear {
                        AccessibilityNotification.Announcement("Còn \(left) giây").post()
                    }
            } else {
                Text(QuickRecordSheet.Copy.autoSendTip)
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
            .onAppear {
                withAnimation(Motion.gentle(.spring(duration: 0.45, bounce: 0.45))) { shown = true }
            }
    }
}
