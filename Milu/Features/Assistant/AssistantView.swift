import SwiftUI

/// Trợ lý AI: a screen of its own over everything, sliding up from Tổng quan and closed with ✕ or
/// a swipe down, so the input bar is the only thing at the bottom (user request 2026-10-30: tab
/// bar and input together looked crowded). Pushed, it hid the tab bar, which iOS brought back only
/// once the pop had finished, at once (user report 2026-10-31). Wrap it in a `NavigationStack`.
struct AssistantView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @Environment(AssistantChats.self) private var chats
    @State private var draft = ""
    /// The glass's height behind the field, which follows the field's on a spring (0 until first measured).
    @State private var glassHeight: CGFloat = 0
    /// The glass's height as it set off growing or folding, for the words to go between their
    /// two places on its way.
    @State private var glassFrom: CGFloat = 0
    /// Words just heard, held unseen while the glass grows to take them, then faded in, as
    /// ChatGPT does (user's recording of it, 2026-11-10).
    @State private var wordsHidden = false
    /// ✕ keeps its place, unseen, until the words just heard are about to fade in.
    @State private var keepsCross = false
    /// A question flying from the field up to its bubble as it is sent, as ChatGPT's do (user
    /// request 2026-11-10, after their recording of it); nil the rest of the time.
    @State private var flight: QuestionFlight?
    /// Where the flight is heading and whether it has set off, read by the flying copy and the
    /// chat's slide alone: written into this view's state it rebuilt the whole chat as the
    /// flight began, and its first frames were dropped (measured 2026-11-10).
    @State private var track = FlightTrack()
    /// Where the words start in the field, kept out of the view's state:
    /// they move with every frame of the glass, and nothing redraws for them.
    @State private var origins = FlightOrigins()
    @State private var isThinking = false
    /// Set on the first question; `OnboardingRewards` pays "Hỏi Milu một câu" in Làm quen với Milu.
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    @State private var viewingTransaction: FinanceTransaction?
    /// The chat card whose "Xoá" was tapped, until the alert is answered: deleting always asks
    /// first, in chat too (strict review 2026-10-31: it deleted at once).
    @State private var pendingRemoval: ChatMessage?
    @State private var dictation = SpeechDictation()
    @FocusState private var isInputFocused: Bool
    /// The chat is scrolled up from its end, far enough to show the ↓ that brings it back.
    @State private var isAwayFromEnd = false
    @State private var isShowingHistory = false
    @AppStorage(StorageKey.profileName) private var profileName = ""

    /// How far above the end, in points, before ↓ shows: past a short slip of the thumb.
    private static let awayDistance: CGFloat = 160

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }

    /// Where the newest question starts: it and what follows make the last turn, which is held
    /// at the top of the chat as Claude and ChatGPT hold it (user's recordings, 2026-11-10).
    private var lastTurnStart: Int? { messages.lastIndex { $0.role == .user } }

    /// The question whose turn keeps a screen's room under it: one sent here, until that room
    /// is out of sight. An old chat opened, or the room scrolled past, shows no blank under the
    /// last answer, as ChatGPT and Claude (user report 2026-11-10).
    @State private var roomFor: ChatMessage.ID?
    /// The chat scrolled to its very end (the room under the last turn included): it keeps its
    /// end in place as the keyboard comes or goes, frame for frame with it, as ChatGPT (user
    /// report 2026-11-10: a scroll after the keyboard had moved lagged and missed; the
    /// keyboard's notice comes after the chat has already been resized, too late to start one).
    @State private var isAtEnd = true
    /// From a question sent until its answer is in: the chat stays as the question left it, not
    /// pulled to the end of an answer longer than the screen.
    @State private var keepsTurn = false
    /// The chat's scroll view, for a question to scroll to the top as it sets off.
    @State private var chatProxy: ScrollViewProxy?
    /// The tallest the chat has shown, between the bars: its height with the keyboard down. The
    /// room under a question sent, for it to be held at the top, is this tall whatever the
    /// keyboard is doing. Sized to the keyboard still up, the chat was too short once it had
    /// gone and iOS slid it down 124pt as the question set off upward (user report 2026-11-10:
    /// jerky; offsets logged frame by frame). Shrunk as the keyboard came back, in the frame the
    /// chat itself is resized, iOS moved the chat twice over (offsets 640, 339, then 38, logged
    /// 2026-11-10) and the answer just read ended up behind the keyboard.
    @State private var fullHeight: CGFloat = 0

    /// The last turn keeps a screen's room under it. Never the first of a chat: it is at the
    /// top already.
    private var hasRoom: Bool {
        guard let start = lastTurnStart, start > 0 else { return false }
        return roomFor == messages[start].id
    }

    private static let turnID = "turn"
    /// The end of the last words and the gap under them, for an answer the keyboard would hide.
    private static let wordsGapID = "wordsGap"
    private var hasQuestions: Bool { chats.conversations[currentIndex].hasQuestions }

    /// The very end of the chat, under the last message and the typing dots.
    private static let endID = "end"
    /// Under the last message, to the end of the chat.
    private static let endGap = Spacing.xl + Spacing.s
    /// Where a question held at the top starts, in the scroll view's coordinates: where the
    /// first question of a chat sits, under the day, so every question lands in the one place
    /// (user report 2026-11-11: the second and on rested 55pt higher than the first). With a full
    /// room under it, that is the chat scrolled to its very end.
    private var turnRest: CGFloat { -Spacing.s + pinDrop }
    /// How far under the very top a question rests: the day's chip and the gap under it, and the
    /// `turnRest` it rested over before (measured on screen: 8pt short without it).
    private var pinDrop: CGFloat { chipHeight + Spacing.xl + Spacing.s }
    @State private var chipHeight: CGFloat = 0
    /// ✎ tapped: the chat is sliding away before the new one comes.
    @State private var isLeaving = false

    var body: some View {
        // One container for both pages, not a `Group`: a group hands the bar below to each
        // page, so the first question, swapping the pages, built a new field and iOS took the
        // keyboard away in a single frame, with no animation (logged 2026-11-10).
        ZStack {
            // A new chat greets in the middle of the page with what to ask, as the AI apps do
            // (user request 2026-11-09: a greeting bubble and a title bar read like a form).
            // ✎ cross-fades to the greeting (it swapped in at once, seen 2026-11-10); the first
            // question swaps the other way under its flight, with no animation.
            // ✎: the chat slides up first, then fades, and the greeting comes in after it (user
            // request 2026-11-11: a cross-fade read as a blink).
            // Slid away by hand before the chat changes: as a removal, the chat it left had turned
            // into the new, empty one, and its page scrolled down as it went (seen frame by frame).
            if hasQuestions {
                chat
                    .modifier(SlideAway(progress: isLeaving ? 1 : 0))
                    .transition(.asymmetric(insertion: .opacity, removal: .identity))
            } else {
                greeting.transition(.opacity)
            }
        }
        // Under the keyboard too: its rounded glass showed the window's white at its corners
        // (user report 2026-10-31).
        .background { PageBackground().ignoresSafeArea() }
        .foregroundStyle(Palette.label)
        // A bar of the system's: the chat scrolls under the glass, behind iOS's own edge fade.
        .bottomBar {
            if quota.isEmpty {
                outOfQuestions
            } else {
                // The bar keeps only the field's one-line room; past one line the field grows
                // up over the page, and what is above it stays where it is (user request
                // 2026-11-11: the greeting was pushed up with every new line).
                Color.clear
                    .frame(height: Self.barRestHeight)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
            }
        }
        // The field over the page, on the bar's room: inside the bar, a tap on its lines above
        // that room went to the page under it and closed the keyboard (seen on the Simulator).
        .overlay(alignment: .bottom) {
            if !quota.isEmpty { inputBar }
        }
        // Over the chat and the field both, so the question can fly from one to the other.
        .overlay { flightLayer }
        // No title or subtitle in the middle (user request 2026-11-09: AI apps show none); the
        // name stays for VoiceOver and the back button.
        .navigationTitle("Milu")
        .toolbarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            // An empty slot, not EmptyView: with nothing there, iOS shows the title.
            ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1).accessibilityHidden(true) }
            // Plain buttons: the bar draws their glass, each its own (`ToolbarSpacer`).
            ToolbarItem(placement: .topBarTrailing) { historyButton }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) { newChatButton }
        }
        .sheet(isPresented: $isShowingHistory) { ChatHistorySheet() }
        .sheet(item: $viewingTransaction) { TransactionDetailSheet(transactionID: $0.id) }
        .systemAlert("Xoá giao dịch?", isPresented: Binding(
            get: { pendingRemoval != nil },
            set: { if !$0 { pendingRemoval = nil } }
        )) {
            Button("Huỷ", role: .cancel) {}
            Button("Xoá", role: .destructive) {
                if let message = pendingRemoval { remove(message) }
            }
        }
        .systemAlert("Không dùng được micro", isPresented: Binding(
            get: { dictation.failure != nil },
            set: { if !$0 { dictation.failure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dictationMessage)
        }
        .onDisappear { dictation.stop() }
    }

    // MARK: - Chat

    private var chat: some View {
        ScrollViewReader { proxy in
            ScrollView {
                let start = lastTurnStart ?? messages.count
                // No gap of the stack's own before the end: the room under a question is counted
                // to the point (`turnRest`).
                VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    dateChip
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { chipHeight = $0 }
                    ForEach(messages[..<start]) { message in row(message) }
                    // The newest question and its answer, a screen tall at least, so a question
                    // sent goes to the top of the chat and stays there as its answer comes in
                    // under it: the one place, every time, as Claude and ChatGPT (user request
                    // 2026-11-10). The first question needs no room: it is at the top already.
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        ForEach(messages[start...]) { message in row(message) }
                        // Only once the question has landed, as ChatGPT: shown at once, the
                        // question flew up over "Milu •••" (seen frame by frame, 2026-11-10).
                        if isThinking && !isFlying {
                            // In softly, out at once: the answer takes its place in that very
                            // frame. Faded out, it stayed 0.2s under the answer, a second
                            // "Milu" there (user report 2026-11-11, seen frame by frame).
                            TypingIndicator().id("typing")
                                .transition(.asymmetric(
                                    insertion: .opacity.animation(Motion.gentle(.easeOut(duration: 0.2))),
                                    removal: .identity))
                        }
                    }
                    // Where the last words end (the room left for the answer comes under them),
                    // in the scroll view's coordinates: how far ↓ is from them.
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).maxY } action: {
                        origins.wordsEnd = $0
                        updateAway()
                    }
                    // What an answer the keyboard would hide is scrolled to: the gap under it.
                    .overlay(alignment: .bottom) {
                        Color.clear.frame(height: 1)
                            .id(Self.wordsGapID)
                            .alignmentGuide(.bottom) { _ in 1 - Self.endGap }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: hasRoom ? max(fullHeight - Spacing.xl - pinDrop, 0) : nil, alignment: .top)
                    // What a question sent is scrolled to: a mark a little under the turn's top,
                    // so the turn comes to rest at `turnRest` whatever the room under it. The
                    // mark stays out of the chat's slide: a scroll goes to where its mark is
                    // drawn, and to a mark drawn 279pt lower it went 279pt too far (logged
                    // 2026-11-10).
                    .overlay(alignment: .top) {
                        Color.clear.frame(height: 1)
                            .id(Self.turnID)
                            .modifier(ChatSlideHost(track: track, undoes: true))
                            .alignmentGuide(.top) { _ in turnRest }
                    }
                }
                // Close to the screen's edges, as the field below (user request 2026-10-31).
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Self.endGap)
                // A tap on a message closes the keyboard too; a card's buttons still take theirs.
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }
                .modifier(ChatSlideHost(track: track))
                Color.clear.frame(height: 0).id(Self.endID)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // The gap over the first message, and over a question held at the top: a margin of
            // the scroll view's, so scrolling a question to the top leaves it under the bar.
            .contentMargins(.top, Spacing.l, for: .scrollContent)
            // The shown height now, the keyboard's room taken off.
            .modifier(ShownHeight { height in
                let was = origins.shown
                origins.shown = height
                takeHeight()
                keepAnswerInSight(from: was, to: height)
                updateAway()
            })
            .modifier(ScrollMoves { scrolled(by: $0) })
            // Opened at its end, an old chat or one picked in the history, and kept there when
            // the keyboard comes up or the field grows: it opened at the top, and the keyboard
            // hid the last answer until ↓ (user report 2026-11-10).
            // Not under a turn that keeps its room: that one stays where it is, and is scrolled
            // only when the keyboard would hide its answer (`keepAnswerInSight`).
            .modifier(StaysAtEnd(holdsEnd: isAtEnd && !keepsTurn && flight == nil && !hasRoom) { atEnd in
                if atEnd != isAtEnd { isAtEnd = atEnd }
            })
            .onAppear {
                // iOS 17, which has no initial anchor for a scroll view: scrolled there at once.
                if #unavailable(iOS 18.0) {
                    Task { proxy.scrollTo(Self.endID, anchor: .bottom) }
                }
            }
            .onChange(of: isInputFocused) { _, focused in
                // iOS 17, which cannot tell the keyboard took the room: after it has.
                if #unavailable(iOS 18.0), focused, !isAwayFromEnd {
                    Task {
                        try? await Task.sleep(for: .seconds(0.3))
                        withAnimation { proxy.scrollTo(Self.endID, anchor: .bottom) }
                    }
                }
            }
            // A tap on the empty page under the chat closes the keyboard (user report 2026-11-09).
            .keyboardDismissArea()
            // Away from the last words, not from the room kept under them for the answer: from
            // the end of that room, ↓ showed over the answer once the keyboard was up (seen
            // 2026-11-10).
            // ↓ in glass over the chat, centred just above the field, as in Claude and ChatGPT
            // (user request 2026-10-31): only while scrolled up, and gone once back at the end.
            .overlay(alignment: .bottom) {
                if isAwayFromEnd {
                    Button {
                        // To the very end, under the chat's bottom margin: to the last message's
                        // own edge it stopped 28pt short, the answer touching the field, and a
                        // swipe had to finish it (user reports 2026-11-10, measured).
                        withAnimation(Motion.gentle(Self.scrollAnimation)) {
                            proxy.scrollTo(Self.endID, anchor: .bottom)
                        }
                    } label: {
                        // SF's arrow, as iOS draws it (user request 2026-11-09).
                        Image(systemName: "arrow.down")
                            .font(.system(size: IconSize.control, weight: .semibold))
                            .foregroundStyle(Palette.label)
                            // A full 44 of glass: the glass button style drew a 32 circle inside it.
                            .frame(width: ControlHeight.regular, height: ControlHeight.regular)
                            .interactiveGlass(in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, Spacing.s)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                    .accessibilityLabel("Cuộn xuống tin mới nhất")
                }
            }
            // A question sent with no flight (Reduce Motion) goes to the top by a scroll of its
            // own. Its answer then comes in under it with no scroll.
            .onChange(of: messages) { old, new in
                guard new.count > old.count, new.last?.role == .user, new.count > 1, flight == nil else { return }
                withAnimation(Self.flightAnimation) {
                    proxy.scrollTo(Self.turnID, anchor: .top)
                }
            }
            .onAppear { chatProxy = proxy }
        }
        // A scroll view of its own for each chat, so one picked in the history opens at its end
        // rather than where the last one was.
        .id(chats.currentID)
    }

    /// ↓ shows while the last words are more than `awayDistance` under the shown part.
    private func updateAway() {
        // Mid-flight the chat is drawn under where it is scrolled to: nothing to tell from that.
        // Nor while an answer is being scrolled back into sight (`keepAnswerInSight`).
        guard !isFlying, !origins.isSettling,
              let end = origins.wordsEnd, let shown = origins.shown else { return }
        // The last words gone under the shown part: the room under them is out of sight, and
        // goes with nothing on screen moving, so the chat ends at its last words again.
        if roomFor != nil, end > shown + 1, !keepsTurn {
            roomFor = nil
        }
        let away = end > shown + Self.awayDistance
        if away != isAwayFromEnd {
            withAnimation(.spring(duration: 0.3)) { isAwayFromEnd = away }
        }
    }

    private func row(_ message: ChatMessage) -> some View {
        MessageRow(message: message, isLanding: flight?.id == message.id,
                   onTextPlace: { land(message.id, at: $0) }, onAction: handle)
            .equatable()
            .id(message.id)
    }

    // MARK: - Đầu trang

    private var historyButton: some View {
        Button { isShowingHistory = true } label: {
            BarSymbol("clock.arrow.circlepath")
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Lịch sử trò chuyện")
    }

    /// ✎ a new chat, as in the AI apps; nothing to do while this one is still empty.
    private var newChatButton: some View {
        Button { startNewConversation() } label: {
            BarSymbol("square.and.pencil")
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .disabled(!hasQuestions)
        .accessibilityLabel("Cuộc trò chuyện mới")
    }

    // MARK: - Lời chào

    @ScaledMetric(relativeTo: .title) private var greetingMark: CGFloat = 72

    /// A new chat: ✨, "Chào Minh!" and what Milu does, in the middle of the page (scrolling when
    /// the text is large). No questions to pick: the field is where to ask (user request
    /// 2026-11-11).
    private var greeting: some View {
        // The room between the bars, to centre in (a reader is cheap on this short page).
        GeometryReader { room in
        ScrollView {
            VStack(spacing: Spacing.section) {
                VStack(spacing: Spacing.m) {
                    Image(IconCatalog.emojiName("✨"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: greetingMark * 0.55, height: greetingMark * 0.55)
                        .frame(width: greetingMark, height: greetingMark)
                        .background(Palette.surfaceMuted, in: Circle())
                        .accessibilityHidden(true)
                    Text(greetingTitle)
                        .textRole(.pageTitle)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Hỏi mình về chi tiêu, khoản vay, hoặc nhờ mình ghi, sửa, xoá giao dịch.")
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.l)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.xl)
            // In the middle of what shows between the bars.
            .frame(maxWidth: .infinity, minHeight: room.size.height)
            .contentShape(Rectangle())
            .onTapGesture { dismissKeyboard() }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        }
    }

    /// "Chào Minh!", or "Chào bạn!" with no name set in Cài đặt.
    private var greetingTitle: String {
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Chào \(name.isEmpty ? "bạn" : name)!"
    }

    private var dateChip: some View {
        Text(chats.conversations[currentIndex].startedAt.transactionDayTitle)
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryLabel)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background(Palette.surfaceMuted, in: Capsule())
            .frame(maxWidth: .infinity)
    }

    // MARK: - Ô nhập

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    /// Every button in the field: 36, one size, so they sit on one line (user report 2026-11-09:
    /// the mic and the send arrow sat out of line).
    private static let buttonSize = ControlHeight.small
    /// The mic turning into ↑ and back: a fade and a grow, nothing that moves.
    private static var morph: Animation? { Motion.gentle(.spring(response: 0.3, dampingFraction: 0.9)) }
    /// The glass growing a line or folding back once sent (user report 2026-11-10: it snapped).
    /// Fast at first, then settling: a spring starts from rest, and for its first frames the new
    /// line sat under the buttons before the glass had moved (seen frame by frame, 2026-11-10).
    /// ChatGPT's, from the user's recording (2026-11-11): 40pt in about 0.15s, half of it in
    /// the first two frames after a soft start.
    private static var resize: Animation? { Motion.gentle(.timingCurve(0.3, 0, 0.2, 1, duration: 0.17)) }

    /// The field's inset around its buttons; its corner is the buttons' plus this, so both curves
    /// share one centre, a capsule while one line.
    private static let inset = Spacing.s
    private static let inputRadius = buttonSize / 2 + inset
    /// The bar's height with the field on one line: the glass and the gap under it.
    private static let barRestHeight = buttonSize + inset * 2 + Spacing.s
    private var glassShape: RoundedRectangle { RoundedRectangle(cornerRadius: Self.inputRadius, style: .continuous) }

    /// One Liquid Glass field over the chat, as Claude's (user request 2026-11-09), one line
    /// whatever it does (user request 2026-11-10: it should not grow into two). Typing: the words,
    /// then the mic, or the send arrow once there are words. Listening: ✕ (drop it), the sound
    /// running right to left where the words were, ■ (done) and ↑ (done, and send). Then
    /// "Milu đang hiểu ý bạn…" in the sound's place, and the words come into the field there.
    /// Nothing shows while listening, as ChatGPT (user request 2026-11-10).
    ///
    /// The text field stays put under the sound, only hidden, so the keyboard stays up if it was
    /// (user report 2026-11-10: the mic closed it). The glass clips what it holds, so a button on
    /// its way out never shows outside it.
    private var inputBar: some View {
        let isDictating = dictation.isRecording || dictation.isTranscribing
        // Past one line the words take the whole width and the buttons keep a row of their own at
        // the foot, as ChatGPT (user request 2026-11-10: they hopped with every new line). Decided
        // in the layout itself, in the same pass as the words, so nothing shows a frame late.
        return InputBarLayout(spacing: Spacing.s, rowGap: Spacing.xs, minHeight: Self.buttonSize,
                              wordsInset: EdgeInsets(top: Spacing.xs, leading: Spacing.s, bottom: Spacing.xs, trailing: 0),
                              isOneLine: isDictating,
                              revealed: glassHeight == 0 ? nil : glassHeight - Self.inset * 2,
                              revealedFrom: glassFrom == 0 ? nil : glassFrom - Self.inset * 2) {
            HStack(alignment: .top, spacing: Spacing.s) {
                // Kept in place, fading and shrinking, while the glass grows for the words just
                // heard, and gone once they show: dropped at once, it went in a frame and
                // "Milu đang hiểu ý bạn…" jumped left with it (user report 2026-11-10).
                if isDictating || keepsCross {
                    roundButton("xmark", label: "Huỷ nhập giọng nói") { dictation.stop() }
                        .animation(Motion.gentle(.easeOut(duration: 0.2))) {
                            $0.opacity(isDictating ? 1 : 0).scaleEffect(isDictating ? 1 : 0.6)
                        }
                        .allowsHitTesting(isDictating)
                        .transition(.blurReplace.combined(with: .scale(0.6)))
                }
                // Top, so the sound and "Milu đang hiểu ý bạn…" keep to the first line: centred,
                // the words grew tall first and dropped them to the glass's lower edge for a
                // frame (seen frame by frame, 2026-11-10).
                ZStack(alignment: .topLeading) {
                    TextField("Hỏi Milu", text: $draft, axis: .vertical)
                        // The body's font with the font's own line box, not the role's exact
                        // one: the text view under the field draws its lines at the font's
                        // height whatever the role says, so at five lines it came out 6pt
                        // taller than SwiftUI held it, scrolled itself and cut its top line in
                        // half (user report 2026-11-11, seen frame by frame).
                        .font(TextRole.body.font)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                            origins.field = $0
                        }
                        // One limit always: changing it, or turning off its taps, made iOS put
                        // another field in its place and the keyboard went down (user report
                        // 2026-11-10). While listening it is only hidden, and held to one line.
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        // The key makes a new line in this many-line field, as ChatGPT's, and
                        // shows the return key: as "Gửi", a blue arrow like ↑, it read as
                        // sending (user report 2026-11-11). ↑ in the field sends. No
                        // `onSubmit`: with one, the key sent the question instead of breaking
                        // the line (seen on the Simulator the same day).
                        .submitLabel(.return)
                        // A question to Milu is sent as typed: no rewriting by Apple Intelligence
                        // over the keyboard, no autocorrect swapping words (user request 2026-11-10).
                        .writingToolsDisabledIfAvailable()
                        .autocorrectionDisabled()
                        .padding(.vertical, Spacing.xs)
                        .padding(.leading, isDictating || keepsCross ? 0 : Spacing.s)
                        // As tall as a button while one line, its words on the button's centre.
                        .frame(minHeight: Self.buttonSize)
                        .frame(maxHeight: isDictating ? Self.buttonSize : nil, alignment: .top)
                        // Hidden and shown at once: "Hỏi Milu" never lies over the sound, and
                        // no fade here can carry the buttons along as the field changes height.
                        // Gone at once as listening starts, back only once the sound has faded
                        // out. Under the field's spring it faded both ways, over the sound
                        // (seen frame by frame, 2026-11-10).
                        .animation(isDictating || wordsHidden
                                   ? nil : Motion.gentle(.easeOut(duration: 0.2).delay(0.14))) {
                            $0.opacity(isDictating || wordsHidden ? 0 : 1)
                        }
                        // "Hỏi Milu" comes back once the question has flown off, not under it
                        // as it leaves (seen frame by frame, 2026-11-10).
                        // Gone at once as it leaves, faded back in.
                        .animation(flight == nil ? Motion.gentle(.easeOut(duration: 0.2)) : nil) {
                            $0.opacity(flight == nil ? 1 : 0)
                        }
                    if dictation.isRecording {
                        VoiceWaveform(dictation: dictation)
                            .frame(height: Self.buttonSize)
                            // Quick to go, so "Hỏi Milu" never comes back over it.
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .opacity.animation(Motion.gentle(.easeOut(duration: 0.14)))))
                    } else if dictation.isTranscribing || wordsHidden {
                        // Fades out on its own as the words come, while the glass grows.
                        ShimmerText("Milu đang hiểu ý bạn…")
                            .frame(height: Self.buttonSize)
                            .animation(Motion.gentle(.easeOut(duration: 0.15))) {
                                $0.opacity(dictation.isTranscribing ? 1 : 0)
                            }
                            .transition(.opacity.combined(with: .offset(x: 8)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Takes the height the layout gives it, measured from the words.
            .frame(maxHeight: .infinity, alignment: .top)
            trailingButtons(isDictating: isDictating)
            // Unseen: the words as the field shows them, for the layout to measure. The text
            // field itself told the height for the width it had before, so it came out a line
            // too tall after the switch (seen in testing 2026-11-10).
            // An empty last line counts too: a text drops it, and on ⏎ the measure stayed a line
            // short, the caret sat clipped on the glass's edge until the field caught up (seen
            // frame by frame, 2026-11-11).
            Text(draft.isEmpty || draft.hasSuffix("\n") ? draft + " " : draft)
                .font(TextRole.body.font)
                .lineLimit(5)
                .hidden()
                .accessibilityHidden(true)
        }
        // One spring for every change of the field, as iOS moves its glass: buttons trade places,
        // the field grows a line at a time, nothing jumps.
        .animation(.spring(response: 0.36, dampingFraction: 0.9), value: dictation.isRecording)
        // No animation as the words grow a line: the field grows upward at once and the buttons
        // stay put. Animated, the buttons kept their place from the old top edge and slid down
        // 40pt (seen frame by frame in a recording, 2026-11-10).
        .sensoryFeedback(.impact(weight: .light), trigger: dictation.isRecording)
        .padding(Self.inset)
        // The words and buttons take their new place at once; only the glass behind them grows
        // or folds, on a spring, from the foot up (user report 2026-11-10: it snapped). Anything
        // animated inside moved with the field's top edge, so the buttons slid; the glass alone
        // moving keeps them still. Growing, the new top line shows as the glass reaches it.
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            if glassHeight == 0 {
                glassHeight = height
                glassFrom = height
            } else {
                glassFrom = glassHeight
                // At rest again, the glass starts the next change from where it is: the frames
                // before that change sets off then read as its start.
                withAnimation(Self.resize, completionCriteria: .logicallyComplete) {
                    glassHeight = height
                } completion: {
                    glassFrom = glassHeight
                }
            }
        }
        .mask(alignment: .bottom) { glassShape.frame(height: glassHeight == 0 ? nil : glassHeight) }
        // The field itself is the hit area: a tap anywhere on the glass starts typing.
        .contentShape(glassShape)
        .onTapGesture { if !isDictating { isInputFocused = true } }
        .background(alignment: .bottom) {
            Color.clear
                .frame(height: glassHeight == 0 ? nil : glassHeight)
                .interactiveGlass(in: glassShape)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.s)
    }

    /// The buttons at the end of the field: ■ while listening, then the one action button.
    private func trailingButtons(isDictating: Bool) -> some View {
        HStack(spacing: Spacing.s) {
            if dictation.isRecording {
                roundButton("stop.fill", label: "Xong, chuyển thành chữ") { finishDictation(thenSend: false) }
                    .transition(.blurReplace.combined(with: .scale(0.6)))
            }
            actionButton(isDictating: isDictating)
        }
    }

    /// One button for the mic and ↑: only its glyph and its disc change, inside it. Two views
    /// swapped in and out carried an animation of their place, and iOS counts a place from the
    /// field's top edge: as the field grew upward the new one slid down 48pt into place (user
    /// report 2026-11-10, measured frame by frame). Nothing here ever animates where it stands.
    private func actionButton(isDictating: Bool) -> some View {
        let sends = isDictating || canSend
        let enabled = sends ? (dictation.isRecording || (!isDictating && canSend)) : !isThinking
        return Button {
            if sends { submit() } else { startDictation() }
        } label: {
            // Both glyphs and the disc are always there; only their fade and size change, and
            // the spring reaches those alone (`animation(_:body:)`). A plain `.animation(value:)`
            // here also carried the button's place: on a paste the field grew upward in the same
            // change, and the button rose with the old top edge, then slid down (user report
            // 2026-11-10, seen frame by frame).
            ZStack {
                Circle()
                    .fill(Palette.primary)
                    .animation(Self.morph) { $0.scaleEffect(sends ? 1 : 0.6).opacity(sends ? 1 : 0) }
                Image(systemName: "mic")
                    .font(.system(size: IconSize.control))
                    .foregroundStyle(Palette.secondaryLabel)
                    .animation(Self.morph) { $0.scaleEffect(sends ? 0.5 : 1).opacity(sends ? 0 : 1) }
                Image(systemName: "arrow.up")
                    .font(.system(size: IconSize.bar, weight: .semibold))
                    .foregroundStyle(Palette.onPrimary)
                    .animation(Self.morph) { $0.scaleEffect(sends ? 1 : 0.5).opacity(sends ? 1 : 0) }
            }
            .frame(width: Self.buttonSize, height: Self.buttonSize)
            .animation(Self.morph) { $0.opacity(sends && !enabled ? 0.4 : 1) }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(sends ? "Gửi tin nhắn" : "Nhập bằng giọng nói")
    }

    /// ✕ and ■ while listening: a glyph on a grey disc.
    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: IconSize.inline + 2, weight: .semibold))
                .foregroundStyle(Palette.label)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .background(Palette.fill, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// In place of the input once this month's questions and the bonus are used up.
    private var outOfQuestions: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            // A glyph in content, not a toolbar's (re-review 2026-10-31).
            AssistantAvatar()
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text("Đã dùng hết lượt AI")
                    .textRole(.bodyStrong)
                // Only when it comes back; Milu Pro is told about on Tổng quan (strict review 2026-10-31).
                // The one short date (`shortDay`).
                Text("Lượt mới vào \(quota.renewsOn.shortDay)")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        // A card like every other, with the shared shadow (strict review 2026-10-31).
        .padding(RowMetrics.horizontal)
        .cardSurface(radius: CardCorners.card)
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.s)
    }

    private var dictationMessage: String {
        switch dictation.failure {
        case .denied: "Hãy cho phép Milu dùng micro và nhận dạng giọng nói trong Cài đặt."
        case .unavailable: "Nhận dạng giọng nói tiếng Việt hiện chưa sẵn sàng trên thiết bị này."
        case .audio, nil: "Không mở được micro. Bạn thử lại sau nhé."
        }
    }

    // MARK: - Câu hỏi bay lên

    /// The question on its way up, drawn over everything in the window's own coordinates.
    @ViewBuilder
    private var flightLayer: some View {
        if let flight {
            FlightLayer(flight: flight, track: track)
        }
    }

    /// A question on its way up: flying, or carried up by the chat on the second leg. The chat
    /// is drawn off its place meanwhile, so nothing measured in it tells where it is.
    private var isFlying: Bool { flight != nil || track.stage != .atField }

    /// The bubble waiting for `id` is laid out, its words at `place`: the flight is made ready.
    /// Nothing moves yet, and the keyboard stays up: the keyboard, the words and the chat set
    /// off together (`setOff`). The keyboard closed at the tap fell alone for the frames the new
    /// bubble takes to lay out, the words hanging over the field, then lurching after it (user
    /// report 2026-11-10: jerky; seen frame by frame, 4 frames late, 9 on a first question).
    private func land(_ id: ChatMessage.ID, at place: TextPlace) {
        guard let flight, flight.id == id, !track.hasSetOff else { return }
        if flight.buildsChat {
            // The first question is at the top already: the bubble is where it will stay.
            track.target = place.onScreen
            guard !track.isReady else { return }
            track.isReady = true
            // Off at once, after this update: closing the keyboard lays the window out again.
            Task { setOff(id) }
            return
        }
        guard !track.isReady else { return }
        track.isReady = true
        // How far the scroll brings the turn up: from where it is to where it rests.
        let turnTop = place.inChat.minY - Bubble.userInset.top
        let rise = turnTop - turnRest
        // How far the chat has come up already: iOS keeps a chat at its end there as it grows,
        // so the question's own bubble lifted it before this (68pt, logged 2026-11-10; it showed
        // as a hop at the tap). The turn would be a row's gap under the words that were last.
        let lifted = origins.wordsEndAtSend.map { max($0 + Spacing.xl - turnTop, 0) } ?? 0
        // Scrolled there at once, and drawn where it was. Scrolled with an animation, iOS ran its
        // own curve, a third of the way in the first frame (user report 2026-11-10, offsets
        // logged frame by frame).
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still) {
            chatProxy?.scrollTo(Self.turnID, anchor: .top)
            track.slide = rise + lifted
            track.target = place.onScreen.offsetBy(dx: 0, dy: -rise)
        }
        track.awaited = FlightTrack.Awaited(id: id, onScreen: place.onScreen, rise: rise)
        // Off once the scroll has told how far it went (`scrolled`); a frame or two on where it
        // cannot tell (iOS 17).
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            setOff(id)
        }
    }

    /// The chat's scroll moved by `distance`. If that is the scroll a question waits on, the
    /// question lands where its bubble really went, measured, not reckoned: reckoned 8pt short,
    /// the chat hopped 8pt as the flight began and the bubble another 8pt as it landed (seen
    /// frame by frame, 2026-11-10).
    private func scrolled(by distance: CGFloat) {
        guard let awaited = track.awaited, flight?.id == awaited.id, !track.hasSetOff,
              abs(distance - awaited.rise) < 40 else { return }
        track.awaited = nil
        track.target = awaited.onScreen.offsetBy(dx: 0, dy: -distance)
        // After the scroll view's own update: closing the keyboard lays the window out again.
        Task { setOff(awaited.id) }
    }

    /// The words go to the right and up in one move, as in Claude (the user's recording, measured
    /// frame by frame, 2026-11-11): across at once and over in a sixth of a second, up from a
    /// twentieth of a second on with the page, the page a frame behind, so the question curves
    /// up out of the field and rides the page to the top. Two legs, across and then up with a
    /// stop between, read as a slide and a lurch (user report 2026-11-11). The keyboard goes
    /// down as they set off: one move, begun in one turn. The words and the chat move by SwiftUI's
    /// own offset on the one curve, with nothing of this page's worked out frame by frame.
    private func setOff(_ id: ChatMessage.ID) {
        guard let flight, flight.id == id, !track.hasSetOff else { return }
        track.hasSetOff = true
        track.awaited = nil
        // Settled in full before the bubble takes over: the rise ends on a small bounce, and
        // handed over on it the words would hop back the 2pt.
        // Three changes, each with its curve: one `animation(_:body:)` inside the others left
        // the words across on the rise's spring (0.3s, not Claude's 0.17), and a `transaction`
        // retiming one part moved its place on that part's curve too (both measured frame by
        // frame, 2026-11-11).
        withAnimation(Self.fillAnimation) { track.isFilled = true }
        withAnimation(Self.arcAcross) { track.isAcross = true }
        withAnimation(Self.flightAnimation, completionCriteria: .removed) {
            track.stage = .atTop
        } completion: {
            guard self.flight?.id == id else { return }
            finishFlight(id)
        }
        // Sent: the keyboard goes down so the answer has the room (user request 2026-11-10).
        dismissKeyboard()
    }

    /// The bubble shows where its copy is, with no animation, so nothing changes on screen; then
    /// "Milu •••" fades in under it.
    private func finishFlight(_ id: ChatMessage.ID) {
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still) {
            self.flight = nil
            track.reset()
        }
        // What was put off for the flight, once it is over for this page too.
        Task {
            takeHeight()
            updateAway()
        }
    }

    /// The chat's shown height, into this page's state when it is the tallest yet. Not while a
    /// question flies: this page rebuilt as the keyboard closes cost the flight a frame; the
    /// landing takes it.
    private func takeHeight() {
        guard !isFlying, let height = origins.shown else { return }
        if height > fullHeight { fullHeight = height }
    }

    /// The chat's shown height shrank (the keyboard came, the field grew a line) under a turn
    /// that keeps its room. Nothing moves while its words still fit: the question stays at the
    /// top with its answer under it. Once they no longer fit, the chat comes up just enough to
    /// keep the answer's end over the field, and the turn, no longer at the top, gives up its
    /// room: from there the chat ends at its last words and iOS keeps that end in place as the
    /// keyboard comes and goes (`StaysAtEnd`). Only for someone reading that end: scrolled
    /// elsewhere, the chat stays where it was put.
    private func keepAnswerInSight(from old: CGFloat?, to new: CGFloat) {
        guard hasRoom, !isFlying, !keepsTurn, let old, new < old,
              let end = origins.wordsEnd,
              end + Self.endGap <= old + 1, end + Self.endGap > new + 0.5 else { return }
        bringAnswerUp()
    }

    /// The answer has come in under a question that keeps its room, the keyboard up: tapped into
    /// the field while Milu was writing, the keyboard came while the turn was held (`keepsTurn`),
    /// and the answer then ran on under it, its end hidden, the room let go there, and the chat
    /// stopped short of its end (user report 2026-11-11). Its end is brought up over the field as
    /// when the keyboard comes over an answer already there. Only where the turn is still at the
    /// top: the answer would show in full without the keyboard. Scrolled elsewhere, nothing moves.
    /// The first question of a chat has no room: its answer is brought up if the chat was at its
    /// end as the answer came (the same report, seen on a new chat).
    private func revealAnswer(wasAtEnd: Bool) {
        guard !isFlying, let shown = origins.shown, let end = origins.wordsEnd,
              end + Self.endGap > shown + 0.5, end + Self.endGap <= fullHeight + 1 else { return }
        if hasRoom {
            bringAnswerUp()
        } else if wasAtEnd, let chatProxy {
            withAnimation(Motion.gentle(Self.keyboardAnimation)) {
                chatProxy.scrollTo(Self.wordsGapID, anchor: .bottom)
            }
        }
    }

    /// The chat up just enough for the answer's end to sit over the field, then the room let go
    /// with nothing on screen moving.
    private func bringAnswerUp() {
        guard let turn = roomFor else { return }
        origins.settling += 1
        Task {
            // A moment on, once iOS has the chat's new size in full: begun in the very update
            // that resizes it, the scroll dipped 14pt the other way first (offsets logged
            // 2026-11-10).
            try? await Task.sleep(for: .milliseconds(20))
            if roomFor == turn, flight == nil, let chatProxy {
                withAnimation(Motion.gentle(Self.keyboardAnimation)) {
                    chatProxy.scrollTo(Self.wordsGapID, anchor: .bottom)
                }
                // Until the scroll is over, by the clock: a scroll is no animation of this
                // page's, and its completion came at once (logged 2026-11-10).
                try? await Task.sleep(for: .milliseconds(450))
                // The room goes with nothing on screen moving: the chat is at its last words.
                if roomFor == turn, flight == nil, !keepsTurn {
                    roomFor = nil
                }
            }
            origins.settling -= 1
            updateAway()
        }
    }

    /// Up, and the chat with it: Claude's rise, fitted to the recording within half a point in
    /// a hundred (2026-11-11): a spring of 0.36s with a little bounce (0.6% over, back by 0.6s),
    /// begun 50ms after the words start across.
    static let flightAnimation = Animation.spring(duration: 0.36, bounce: 0.15).delay(0.05)
    /// Across to the bubble's side: from the first frame, done in 0.17s (fitted the same way).
    static let arcAcross = Animation.timingCurve(0.2, 0.2, 0.6, 1, duration: 0.17)
    /// The bubble and the words' white, full in two frames as Claude's: see-through for longer,
    /// the chat moving under the bubble read as a blurred shadow trailing the words (user report
    /// 2026-11-10).
    static let fillAnimation = Animation.easeOut(duration: 0.06)
    /// ↓ back to the end of the chat.
    static let scrollAnimation = Animation.spring(duration: 0.45, bounce: 0)
    /// The chat coming up with the keyboard: about its pace, as measured (half way in three
    /// frames, 2026-11-10).
    static let keyboardAnimation = Animation.spring(duration: 0.26, bounce: 0)

    // MARK: - Hành động

    /// Closes the keyboard: the field's focus and iOS's first responder, as the forms do (a
    /// focus set to false alone left the vertical field's keyboard up, Simulator 2026-11-09).
    private func dismissKeyboard() {
        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// The keyboard stays as it was (user report 2026-11-10: the mic closed it).
    private func startDictation() {
        wordsHidden = false
        keepsCross = false
        Task { await dictation.start() }
    }

    /// ■ or ↑ while listening: the words go after what was typed, and ↑ sends them too.
    private func finishDictation(thenSend: Bool) {
        Task {
            guard let heard = await dictation.finish() else { return }
            let text = [draft.trimmingCharacters(in: .whitespacesAndNewlines), heard]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if thenSend {
                draft = text
                dictation.endTranscribing()
                send(text, from: origins.field)
                return
            }
            // As ChatGPT (user's recording of it, 2026-11-10): "Milu đang hiểu ý bạn…" fades,
            // the glass grows to the words' height with nothing in it yet, then the words fade in
            // where they will stay. The buttons never move.
            wordsHidden = true
            keepsCross = true
            draft = text
            dictation.endTranscribing()
            try? await Task.sleep(for: .seconds(0.26))
            guard wordsHidden else { return }
            // ✕'s room goes back first, with the words still unseen, so they do not slide as
            // they fade in.
            keepsCross = false
            try? await Task.sleep(for: .seconds(0.02))
            guard wordsHidden else { return }
            withAnimation(Motion.gentle(.easeOut(duration: 0.2))) { wordsHidden = false }
        }
    }

    /// ↑ in the field.
    private func submit() {
        if dictation.isRecording {
            finishDictation(thenSend: true)
        } else if !dictation.isTranscribing {
            send(draft, from: origins.field)
        }
    }

    private func startNewConversation() {
        draft = ""
        guard let slide = Motion.gentle(.easeIn(duration: 0.28)) else {
            chats.startNew()
            return
        }
        dismissKeyboard()
        withAnimation(slide, completionCriteria: .logicallyComplete) {
            isLeaving = true
        } completion: {
            withAnimation(.easeOut(duration: 0.25)) { chats.startNew() }
            isLeaving = false
        }
    }

    /// `from`: where the words start on screen (the field), for them to
    /// fly up from there.
    private func send(_ text: String, from origin: CGRect?) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking, quota.spend() else { return }
        dictation.stop()
        wordsHidden = false
        keepsCross = false
        let index = currentIndex
        let message = ChatMessage(role: .user, text: question)
        roomFor = message.id
        track.reset()
        origins.wordsEndAtSend = hasQuestions ? origins.wordsEnd : nil
        if let origin, !UIAccessibility.isReduceMotionEnabled {
            flight = QuestionFlight(id: message.id, text: question, from: origin, buildsChat: !hasQuestions)
        } else {
            // Sent: the keyboard goes down so the answer has the room (user request 2026-11-10).
            // With a flight it goes as the flight sets off (`setOff`).
            dismissKeyboard()
        }
        isThinking = true
        keepsTurn = true
        chats.conversations[index].messages.append(message)
        draft = ""
        hasAskedAI = true

        Task {
            // Giả lập thời gian "suy nghĩ" của AI
            try? await Task.sleep(for: .seconds(1))
            let reply = MockAssistant(store: store).reply(to: question)
            let card: ChatMessage.Card? = switch reply.action {
            case .recorded(let transaction): .recorded(transaction, removed: false)
            case .confirmDelete(let transaction): .confirmDelete(transaction, state: .pending)
            case nil: nil
            }
            let wasAtEnd = isAtEnd
            chats.conversations[index].messages.append(ChatMessage(role: .assistant, text: reply.text, card: card))
            isThinking = false
            // A frame on, once the answer is laid out: brought up as it shows, not 0.3s later
            // with its end hidden meanwhile (seen frame by frame, 2026-11-11).
            try? await Task.sleep(for: .milliseconds(30))
            revealAnswer(wasAtEnd: wasAtEnd)
            // Once the answer is laid out under the question.
            try? await Task.sleep(for: .seconds(0.27))
            keepsTurn = false
        }
    }

    private func handle(_ action: CardAction, in message: ChatMessage) {
        let index = currentIndex
        guard let row = chats.conversations[index].messages.firstIndex(where: { $0.id == message.id }),
              let card = message.card else { return }
        switch (action, card) {
        case (.view, .recorded(let snapshot, _)):
            viewingTransaction = store.transaction(id: snapshot.id)
        case (.remove, .recorded):
            Haptics.warning()
            pendingRemoval = message
        case (.confirm, .confirmDelete(let snapshot, .pending)):
            store.delete(snapshot)
            chats.conversations[index].messages[row].card = .confirmDelete(snapshot, state: .deleted)
        case (.cancel, .confirmDelete(let snapshot, .pending)):
            chats.conversations[index].messages[row].card = .confirmDelete(snapshot, state: .cancelled)
        default:
            break
        }
    }

    /// "Xoá" on a recorded card, once the alert said yes.
    private func remove(_ message: ChatMessage) {
        let index = currentIndex
        guard let row = chats.conversations[index].messages.firstIndex(where: { $0.id == message.id }),
              case .recorded(let snapshot, removed: false) = chats.conversations[index].messages[row].card
        else { return }
        store.delete(snapshot)
        chats.conversations[index].messages[row].card = .recorded(snapshot, removed: true)
    }
}

#Preview {
    NavigationStack { AssistantView() }
        .environment(FinanceStore())
        .environment(AssistantChats(saving: false))
        .environment(AIQuota())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}

/// Words with a soft light running over them, left to right, as the AI apps show they are
/// working; still with Reduce Motion.
private struct ShimmerText: View {
    let text: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .textRole(.body)
            .foregroundStyle(Palette.secondaryLabel)
            .lineLimit(1)
            .overlay {
                if !reduceMotion {
                    Text(text)
                        .textRole(.body)
                        .foregroundStyle(Palette.label)
                        .lineLimit(1)
                        .mask {
                            GeometryReader { proxy in
                                LinearGradient(colors: [.clear, .black, .clear], startPoint: .leading, endPoint: .trailing)
                                    .frame(width: proxy.size.width * 0.45)
                                    .offset(x: sweep ? proxy.size.width : -proxy.size.width * 0.45)
                            }
                        }
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { sweep = true }
            }
    }
}

/// The chat field's two parts: the words (with ✕ while listening) and the buttons. While the words
/// fit one line beside the buttons, side by side, their feet level; past it, the words take the
/// whole width and the buttons go on a row under them, at the right. The buttons sit at the lower
/// right either way, so they never move (user report 2026-11-10). How tall the words are comes
/// from the third, unseen subview: the same words in a `Text`.
private struct InputBarLayout: Layout {
    let spacing: CGFloat
    let rowGap: CGFloat
    /// The words' least height: a button's, so one line sits on the buttons' centre.
    let minHeight: CGFloat
    /// The text field's padding around its words.
    let wordsInset: EdgeInsets
    /// While listening: one line, beside the buttons, whatever the words.
    let isOneLine: Bool
    /// How much of the field the glass shows, from the foot up, while it grows or folds on its
    /// spring (nil: all of it). The words ride its top edge, so as the glass grows a line they
    /// move up with it and never hide behind its edge (seen 2026-11-10: they vanished a moment
    /// on each new line); the buttons stay at the foot. Animated frame by frame, the field's own
    /// size never changes on the way, so the text inside it never scrolls.
    var revealed: CGFloat?
    /// `revealed` as the glass set off: how far it has come between its two heights.
    var revealedFrom: CGFloat?

    var animatableData: CGFloat {
        get { revealed ?? 0 }
        set { if revealed != nil { revealed = newValue } }
    }

    private struct Plan {
        var isTall: Bool
        var words: CGSize
        /// The words' width beside the buttons, and whether they still fit there on one line.
        var beside: CGFloat
        var fitsBeside: Bool
        var buttons: CGSize
        var size: CGSize
    }

    /// How much sooner than the field the measure wraps. The field (a text view) wraps a few
    /// points before a `Text` of the same words: with a hair of slack the words beside the
    /// buttons ran under ↑, then broke onto a second line the one-line glass hid, the caret with
    /// them, and hopped back up as the field went full width (user report 2026-11-11, seen frame
    /// by frame). Gone tall first, while the words are still one line, nothing moves but the
    /// buttons. A few letters' worth: a key typed at 12 to go put the words past ↑ before the
    /// glass had grown (seen frame by frame, 2026-11-11).
    private static let wrapSlack: CGFloat = 28
    /// The same while tall: a hair sooner than the field, so its new line is never late.
    private static let lineSlack: CGFloat = 12

    private func wordsHeight(width: CGFloat, measure: LayoutSubview, slack: CGFloat = Self.wrapSlack) -> CGFloat {
        let textWidth = max(width - wordsInset.leading - wordsInset.trailing - slack, 1)
        let text = measure.sizeThatFits(ProposedViewSize(width: textWidth, height: nil)).height
        return max(text + wordsInset.top + wordsInset.bottom, minHeight)
    }

    private func plan(width: CGFloat, subviews: Subviews) -> Plan {
        let buttons = subviews[1].sizeThatFits(.unspecified)
        let beside = max(width - buttons.width - spacing, 0)
        let short = isOneLine ? minHeight : wordsHeight(width: beside, measure: subviews[2])
        if short <= minHeight {
            return Plan(isTall: false, words: CGSize(width: beside, height: minHeight),
                        beside: beside, fitsBeside: true, buttons: buttons,
                        size: CGSize(width: width, height: max(minHeight, buttons.height)))
        }
        // Tall, the field's own height at the width it keeps from now on, or the measure's,
        // taken a little narrow, if more: the measure alone wrapped later than the field and
        // hid its last line; the field alone told its new line a frame late, the line under the
        // glass's edge, and the field scrolled itself to its caret and left its top line cut
        // when the glass caught up (both seen frame by frame, 2026-11-11). With both, the room
        // for a new line is there in the frame the words wrap, and nothing scrolls.
        let field = subviews[0].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        let measured = wordsHeight(width: width, measure: subviews[2], slack: Self.lineSlack)
        let tall = max(field, measured, minHeight)
        let fits = wordsHeight(width: beside, measure: subviews[2], slack: 6) <= minHeight
        return Plan(isTall: true, words: CGSize(width: width, height: tall),
                    beside: beside, fitsBeside: fits, buttons: buttons,
                    size: CGSize(width: width, height: tall + rowGap + buttons.height))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        plan(width: proposal.width ?? 320, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let plan = plan(width: bounds.width, subviews: subviews)
        // At rest the glass shows it all, and this is the top (tall) or the words beside the
        // buttons (one line). On the way the words ride the glass's top edge, always in sight,
        // as ChatGPT's do (user's recording of it, 2026-11-10). Holding them back above and
        // uncovering them left the field empty a moment on each new line.
        var wordsTop = bounds.maxY - (revealed ?? plan.size.height)
        // Going from one line to the buttons' own row (⏎, or the words reaching ↑) and back, the
        // words' last line, the caret's, goes straight from its old place to its new one, on the
        // glass's way: riding the glass's top, the new line showed under the old one, on the
        // glass's edge, and the caret dropped to it before it rose (user's recording of
        // ChatGPT, 2026-11-11: its caret goes straight up). A line above comes into sight as the
        // glass reaches it.
        let gap = rowGap + plan.buttons.height
        if let revealed, let from = revealedFrom, abs(plan.size.height - from) > 0.5 {
            let wasTall = from > max(minHeight, plan.buttons.height) + 0.5
            if wasTall != plan.isTall {
                let progress = min(max((revealed - from) / (plan.size.height - from), 0), 1)
                let start: CGFloat = wasTall ? gap : 0
                let end: CGFloat = plan.isTall ? gap : 0
                let bottom = bounds.maxY - (start + (end - start) * progress)
                wordsTop = bottom - plan.words.height
            }
        }
        // While the glass grows to the buttons' own row, the words keep beside the buttons as
        // long as they still fit there: at the full width at once, they ran under ↑ until the
        // glass had grown (seen frame by frame, 2026-11-11). One line either way, so they never
        // wrap anew.
        let growing = plan.isTall && (revealed.map { $0 < plan.size.height - 0.5 } ?? false)
        var words = plan.words
        if growing, plan.fitsBeside { words.width = plan.beside }
        subviews[0].place(at: CGPoint(x: bounds.minX, y: wordsTop), proposal: ProposedViewSize(words))
        subviews[1].place(at: CGPoint(x: bounds.maxX, y: bounds.maxY), anchor: .bottomTrailing,
                          proposal: ProposedViewSize(plan.buttons))
        subviews[2].place(at: bounds.origin, proposal: .zero)
    }
}

/// A question sent: its words, where they started on screen, and where its bubble's words are
/// (nil until the bubble is laid out). Window coordinates.
private struct QuestionFlight {
    let id: ChatMessage.ID
    let text: String
    let from: CGRect
    /// The first question of a chat, whose page is built as it is sent.
    let buildsChat: Bool
}

/// The flight's moving parts, observed by `FlightLayer` and the chat's slide alone.
@Observable
private final class FlightTrack {
    /// Where the bubble's words will rest, in window coordinates; nil until it is laid out.
    var target: CGRect?
    /// How far the words have come: set on the flight's animations, which are what move them.
    /// Up (and the chat with them), across, and the bubble filled in are three changes, each
    /// sent with its own curve.
    var stage = Stage.atField
    var isAcross = false
    var isFilled = false
    /// How far under where it is scrolled to the chat is drawn until the words set off: it is
    /// scrolled to the question at once and slides up from where it was.
    var slide: CGFloat = 0

    enum Stage {
        /// In the field, the chat as it was when sent.
        case atField
        /// At the bubble, the chat in its place.
        case atTop
    }

    /// How far under its place the chat is drawn now.
    var chatOffset: CGFloat { stage == .atField ? slide : 0 }
    /// The bubble is laid out and the chat scrolled: the flight waits only to set off.
    @ObservationIgnored var isReady = false
    @ObservationIgnored var hasSetOff = false
    /// The scroll the flight waits on, to hear how far it really went.
    @ObservationIgnored var awaited: Awaited?

    struct Awaited {
        let id: ChatMessage.ID
        /// The bubble's words before the scroll, in window coordinates.
        let onScreen: CGRect
        /// How far the scroll is reckoned to bring them up.
        let rise: CGFloat
    }

    func reset() {
        target = nil
        stage = .atField
        isAcross = false
        isFilled = false
        slide = 0
        isReady = false
        hasSetOff = false
        awaited = nil
    }
}

/// The question flying up over everything, in the window's own coordinates, as ChatGPT's (user's
/// recording, 2026-11-10): the words leave the field already wrapped as in their bubble, the
/// bubble filling in around them as they rise to it, so at landing they are the bubble itself.
/// Only offsets and fades, which SwiftUI moves by itself between the two ends: nothing here is
/// worked out frame by frame.
private struct FlightLayer: View {
    let flight: QuestionFlight
    let track: FlightTrack

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let isUp = track.stage != .atField
            // Until the bubble is laid out (a frame), the words stay as wide as they were, so
            // they are drawn from the very first frame.
            let target = track.target ?? CGRect(origin: flight.from.origin,
                                                 size: CGSize(width: flight.from.width, height: 0))
            // Each moved by its own change, so each on its own curve (`setOff`).
            let filled = track.isFilled
            let x = track.isAcross ? target.minX : flight.from.minX
            let y = isUp ? target.minY : flight.from.minY
            let inset = Bubble.userInset
            // The white words fade in over the dark ones, which stay: one colour turning into
            // the other, never two half-seen copies.
            ZStack(alignment: .topLeading) {
                words(width: target.width)
                    .foregroundStyle(Palette.label)
                words(width: target.width)
                    .foregroundStyle(Palette.onPrimary)
                    .opacity(filled ? 1 : 0)
            }
            .padding(inset)
            .background {
                Bubble.userShape.fill(Palette.primary)
                    .opacity(filled ? 1 : 0)
            }
            // Across as an effect of its own: as a second `offset`, the rise's spring took it
            // over, kept its speed and threw it 8pt past the bubble (measured frame by frame,
            // 2026-11-11).
            .modifier(Across(x: x - origin.x - inset.leading))
            .offset(y: y - origin.y - inset.top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func words(width: CGFloat) -> some View {
        Text(flight.text)
            .textRole(.body)
            .frame(width: width, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A chat leaving for a new one: up first, and fading only on the second half of the way, so it
/// reads as slid away, not blinked out.
private struct SlideAway: ViewModifier, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .offset(y: -Spacing.section * 2 * progress)
            .opacity(1 - min(max((progress - 0.4) / 0.6, 0), 1))
    }
}

/// A shift sideways, animated by the change that set it and by nothing else.
private struct Across: GeometryEffect {
    var x: CGFloat
    var animatableData: CGFloat {
        get { x }
        set { x = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

/// Where words start on screen, written as the views move and read only when sending.
private final class FlightOrigins {
    var field: CGRect?
    /// The bottom of the chat's last words, in the scroll view's own coordinates (from under its
    /// top inset), and the height shown in them now.
    var wordsEnd: CGFloat?
    var shown: CGFloat?
    /// `wordsEnd` as the last question was sent, before its bubble was in the chat.
    var wordsEndAtSend: CGFloat?
    /// An answer is being scrolled back into sight as the keyboard comes (how many such scrolls
    /// are under way).
    var settling = 0
    var isSettling: Bool { settling > 0 }
}

/// The chat drawn `slide` under where it is scrolled to until the flight is up, and in its place
/// after: SwiftUI's own offset, moved by the flight's animation with the words, so the two go as
/// one. Read here, not in the chat page's body, which would be rebuilt as the flight sets off.
private struct ChatSlideHost: ViewModifier {
    let track: FlightTrack
    /// Inside the slide, takes it off again: for what must stay where it is laid out.
    var undoes = false

    func body(content: Content) -> some View {
        content.offset(y: undoes ? -track.chatOffset : track.chatOffset)
    }
}

/// Tells how far the chat has just scrolled (iOS 18): a scroll made in code is known to have
/// happened, and how far it really went.
private struct ScrollMoves: ViewModifier {
    let moved: (CGFloat) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { old, new in
                moved(new - old)
            }
        } else {
            content
        }
    }
}

/// Keeps the chat at its end: opened there, and, while `holdsEnd`, held there as its room
/// changes (the keyboard coming up or going down, the field growing a line), moving with it frame
/// for frame. iOS 18 and later; iOS 17 is handled where it is used.
private struct StaysAtEnd: ViewModifier {
    let holdsEnd: Bool
    let atEnd: (Bool) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                // The opening place: a short chat still starts at the top.
                .defaultScrollAnchor(.bottom, for: .initialOffset)
                .defaultScrollAnchor(holdsEnd ? .bottom : nil, for: .sizeChanges)
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentSize.height + geometry.contentInsets.bottom - geometry.visibleRect.maxY < 24
                } action: { _, new in
                    atEnd(new)
                }
        } else {
            content
        }
    }
}

/// The height the chat shows between its bars and the keyboard, its top margin left out: the
/// room a question held at the top has under it.
private struct ShownHeight: ViewModifier {
    let changed: (CGFloat) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            // The visible rect runs under the bars; the insets are what they (and the keyboard,
            // and the top margin) cover. `containerSize` has the bars taken off already.
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.visibleRect.height - geometry.contentInsets.top - geometry.contentInsets.bottom
            } action: { _, height in
                changed(height)
            }
        } else {
            content.onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom - Spacing.l
            } action: { changed($0) }
        }
    }
}
