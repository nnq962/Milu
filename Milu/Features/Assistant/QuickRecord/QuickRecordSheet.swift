import SwiftUI

/// "Thêm bằng AI" from the +: a small sheet that listens at once, and records without the chat
/// (user design 2026-11-17). The words show as they are heard; a pause of two seconds sends them
/// (`DictationAutoStop`, as in the chat); the answer comes in the same sheet: the receipt card
/// to check and "Lưu", a question back with answers to tap, or, plainly, what Milu cannot record
/// yet with the form to do it by hand. Saved, it says so and closes by itself.
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
    /// The voice on its way to words, from ■ or a pause until they come: set at once, so no frame
    /// shows "Milu đang soạn" before the bubble waiting for them.
    @State private var transcribing = false

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
        SheetScaffold(title: "Thêm bằng AI", fitsContent: true) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(Motion.gentle(.snappy), value: phase)
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

    /// Listening, typing, nothing heard, or the voice turning into words: one view (`input`).
    @ViewBuilder
    private var content: some View {
        if showsInput {
            input
        } else {
            answer
        }
    }

    private var showsInput: Bool {
        switch phase {
        case .listening, .typing, .heardNothing: true
        case .thinking: transcribing
        default: false
        }
    }

    @ViewBuilder
    private var answer: some View {
        switch phase {
        case .listening, .typing, .heardNothing: input
        case .thinking: thinking
        case .result(let result): resultView(result)
        case .saved(let count): savedView(count)
        case .failed(let message): failedView(message)
        }
    }

    // MARK: - Nghe và gõ

    /// Listening, typing, or nothing heard, laid out alike line for line: a line of words, the
    /// wave or the field in the middle, ⌨ or the mic and the main button under them (user choice
    /// 2026-11-17: the first design, the keyboard and the sheet left to iOS). So the sheet keeps
    /// its height and only the keyboard lifts it (user report 2026-11-17: "the sheet closed and
    /// opened again" when the field was shorter). One view for the three, only the middle and the
    /// buttons changing in place: with one whole view fading into another as the keyboard rose, the
    /// sheet now and then stopped 68 points too low, the field under the keyboard (Simulator,
    /// 2026-11-17, three times in four as ⌨ was tapped).
    ///
    /// While listening, the words as they are heard (the iPhone's recognizer; the server's take
    /// their place once done). Nothing heard: the field, not focused, a tap on it types.
    private var input: some View {
        // The voice turning into words: the words heard over the field lit up, as in the chat
        // (user choice 2026-11-17, "Ô nhập sáng lên").
        let listens = phase == .listening || transcribing
        let heard = transcribing ? said : dictation.transcript
        let line = listens ? (heard.isEmpty ? "Nói khoản cần ghi, ví dụ: cà phê 35k, gửi xe 5k" : heard)
            : phase == .heardNothing ? "Milu chưa nghe thấy gì. Bạn nói lại, hoặc gõ nhé."
            : note ?? "Gõ khoản cần ghi, ví dụ: cà phê 35k, gửi xe 5k"
        return VStack(alignment: .leading, spacing: Spacing.l) {
            Text(line)
                .textRole(.body)
                .foregroundStyle(listens && !heard.isEmpty ? Palette.label : Palette.secondaryLabel)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
                .accessibilityLabel(listens && heard.isEmpty ? "Milu đang nghe" : line)
            ZStack {
                if transcribing {
                    TranscribingStatus()
                        .padding(.horizontal, Spacing.m)
                        .frame(maxWidth: .infinity, minHeight: Self.middleHeight)
                        .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous)
                                .strokeBorder(Palette.primary, lineWidth: 1.5)
                        }
                        .transition(.opacity)
                } else if listens {
                    HStack(spacing: 0) {
                        ListeningCountdown(startedAt: dictation.startedAt)
                        VoiceWaveform(dictation: dictation)
                    }
                    .frame(height: Self.middleHeight)
                    .transition(.opacity)
                } else {
                    field
                        .transition(.opacity)
                }
            }
            .frame(minHeight: Self.middleHeight)
            inputButtons
                .disabled(transcribing)
                .opacity(transcribing ? 0.4 : 1)
        }
    }

    private var field: some View {
        TextField("cà phê 35k, gửi xe 5k", text: $typed, axis: .vertical)
            .textRole(.body)
            .lineLimit(1...4)
            // Sent as typed, as the chat's field (user request 2026-11-10): "phe" became "how"
            // (Simulator, 2026-11-17).
            .autocorrectionDisabled()
            .writingToolsDisabledIfAvailable()
            .focused($isTyping)
            .submitLabel(.send)
            .onSubmit { send(typed) }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s + 2)
            .frame(minHeight: Self.middleHeight)
            .background(Palette.fill, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
    }

    /// The same two buttons in every state, their glyphs and actions changing: listening, ⌨ and
    /// ■ (done, send); typing, the mic and ↑; nothing heard, ⌨ and the mic again.
    private var inputButtons: some View {
        let empty = typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(spacing: Spacing.m) {
            switch phase {
            case .typing:
                roundButton("mic", label: "Nói thay vì gõ") { listen() }
                Spacer(minLength: 0)
                mainButton("arrow.up", label: "Gửi cho Milu") { send(typed) }
                    .opacity(empty ? 0.4 : 1)
            case .heardNothing:
                roundButton("keyboard", label: "Gõ thay vì nói") { startTyping() }
                Spacer(minLength: 0)
                mainButton("mic.fill", label: "Nói lại") { startOver() }
            default:
                roundButton("keyboard", label: "Gõ thay vì nói") {
                    dictation.stop()
                    startTyping()
                }
                Spacer(minLength: 0)
                mainButton("stop.fill", label: "Xong, gửi cho Milu") { finishListening() }
            }
        }
    }

    /// The wave's height, and the field's in its place.
    private static let middleHeight = ControlHeight.regular

    /// The words said, and Milu at work on the card as the chat's "Đang nghĩ…" is: the light
    /// passing over it, the three dots (user feedback 2026-11-17: under a spinner, it went unseen).
    private var thinking: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            saidLine
            HStack(spacing: Spacing.s) {
                ShimmerText(text: "Milu đang soạn")
                TypingDots()
                    .scaleEffect(0.8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Milu đang soạn")
        }
    }

    // MARK: - Câu trả lời

    @ViewBuilder
    private func resultView(_ result: QuickRecordResult) -> some View {
        saidLine
        switch result {
        case .card(let draft, let note):
            if let note { words(note) }
            // Huỷ and Lưu inside the card, under its tear (user feedback 2026-11-17).
            DraftCard(draft: draft, onRow: { id in
                if draft.isPending, let row = draft.row(id) { editingRow = AssistantView.EditingRow(row: row) }
            }, actions: AnyView(HStack(spacing: Spacing.s) {
                MiluButton("Huỷ", role: .secondary, fullWidth: true) { dismiss() }
                MiluButton(draft.liveRows.count > 1 ? "Lưu cả \(draft.liveRows.count)" : "Lưu",
                           role: .primary, fullWidth: true) { save(draft) }
            }))
            againButton("Nói lại")
        case .asking(let question, let choices):
            words(question)
            if !choices.isEmpty {
                FlowLayout(spacing: Spacing.s) {
                    ForEach(choices, id: \.self) { choice in
                        TagChip(title: choice, isProminent: false) { send(choice) }
                            .fixedSize()
                    }
                }
            }
            HStack(spacing: Spacing.m) {
                roundButton("keyboard", label: "Gõ câu trả lời") { startTyping() }
                Spacer(minLength: 0)
                // An answer to the question: the exchange goes on.
                mainButton("mic.fill", label: "Nói câu trả lời") { listen() }
            }
        case .refused(let message, let form):
            words(message)
            if let form {
                MiluButton(form.title, role: .primary, fullWidth: true) { open(.form(form)) }
            }
            againButton("Nói khoản khác")
        case .notRecord:
            words("Ghi nhanh chỉ để ghi khoản chi và thu. Câu này bạn hỏi trong Hỏi Milu nhé.")
            MiluButton("Mở Hỏi Milu", role: .primary, fullWidth: true) { open(.chat(said)) }
            againButton("Nói lại")
        }
    }

    private func savedView(_ count: Int) -> some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "checkmark")
                .font(.system(size: IconSize.control, weight: .semibold))
                .foregroundStyle(Palette.income)
                .frame(width: 52, height: 52)
                .background(Palette.incomeSoft, in: Circle())
                .accessibilityHidden(true)
            Text(count > 1 ? "Đã lưu \(count) khoản" : "Đã lưu")
                .textRole(.title)
            againButton("Ghi tiếp")
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

    /// What the user said, small, over the answer.
    @ViewBuilder
    private var saidLine: some View {
        if !said.isEmpty {
            Text("“\(said)”")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .lineLimit(3)
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

    /// ⌨ and the mic: a glyph on a grey disc.
    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: IconSize.control))
                .foregroundStyle(Palette.label)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: ControlHeight.regular, height: ControlHeight.regular)
                .background(Palette.fill, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// ■, ↑, the mic: the sheet's one main action, on the primary disc.
    private func mainButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: IconSize.control, weight: .semibold))
                .foregroundStyle(Palette.onPrimary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: ControlHeight.large, height: ControlHeight.large)
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
        said = dictation.transcript
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
                phase = .failed((error as? LocalizedError)?.errorDescription ?? "Milu chưa trả lời được. Bạn thử lại sau nhé.")
                return
            }
            if Task.isCancelled { return }
            let result = QuickRecordResult.of(reply, said: words)
            let card: ChatMessage.Card? = if case .card(let draft, _) = result { .draft(draft) } else { nil }
            history = before + [ChatMessage(role: .user, text: words),
                                ChatMessage(role: .assistant, text: reply.text, card: card)]
            Haptics.selection()
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
        case .notRecord: "Câu này bạn hỏi trong Hỏi Milu nhé"
        }
    }
}
