import SwiftUI

/// "Lịch sử trò chuyện": every chat with a question, by when it was last spoken in (Hôm nay, Hôm
/// qua, 7 ngày qua, Trước đó), as the app's cards: its first question and its time, Milu's last
/// words under it (user choice 2026-11-17). Tap one to go back to it; swipe it left for "Xoá",
/// inside the card, asked first. Chats not spoken in for 30 days are deleted on their own
/// (`AssistantChats.keptDays`), as the note under the list says.
struct ChatHistorySheet: View {
    @Environment(AssistantChats.self) private var chats
    @Environment(\.dismiss) private var dismiss
    /// The chat whose "Xoá" was tapped, until the alert is answered.
    @State private var pendingDeletion: Conversation?
    /// The row slid open on its "Xoá"; one at a time, closed by a tap anywhere on the list.
    @State private var openID: Conversation.ID?

    var body: some View {
        NavigationStack {
            Group {
                if chats.history.isEmpty {
                    ScrollView {
                        EmptyStateCard(title: "Chưa có cuộc trò chuyện",
                                       message: "Những câu bạn hỏi Milu sẽ được lưu ở đây trong \(AssistantChats.keptDays) ngày.",
                                       picture: IconCatalog.emojiName("✨"))
                            .padding(.horizontal, Spacing.page)
                            .padding(.top, Spacing.l)
                    }
                } else {
                    list
                }
            }
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle("Lịch sử trò chuyện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
            .systemAlert("Xoá cuộc trò chuyện?", isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            )) {
                Button("Huỷ", role: .cancel) {
                    withAnimation(Motion.gentle(.snappy)) { openID = nil }
                }
                Button("Xoá", role: .destructive) {
                    if let conversation = pendingDeletion {
                        withAnimation(Motion.gentle(.snappy)) {
                            openID = nil
                            chats.delete(conversation.id)
                        }
                    }
                }
            } message: {
                Text("Không thể hoàn tác.")
            }
        }
        // On the page colour, not a sheet's white: its white rows would vanish on white, as on
        // the main pages (Simulator 2026-11-09).
        .presentationDetents([.large])
        .sheetGround(Palette.background)
        .scrollIndicators(.hidden, axes: .vertical)
    }

    /// The groups as the app's cards (`FormGroup`'s layout), not iOS's list: its swipe drew the
    /// button outside the card, on the page, and cut the card in two (user report 2026-11-17).
    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                ForEach(Self.sections(of: chats.history), id: \.title) { section in
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: section.title, style: .group)
                        VStack(spacing: 0) {
                            ForEach(Array(section.chats.enumerated()), id: \.element.id) { index, conversation in
                                row(conversation)
                                    .separatorAbove(index > 0, order: index) { RowDivider(column: .none) }
                                    .transition(.opacity)
                            }
                        }
                        .cardSurface(radius: CardCorners.card)
                    }
                }
                FormFooter(message: "Milu tự xoá đoạn chat sau \(AssistantChats.keptDays) ngày không dùng.")
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
        }
        // A row left open closes as the list scrolls (from iOS 18).
        .onScrollMoved {
            guard openID != nil else { return }
            withAnimation(Motion.gentle(.snappy)) { openID = nil }
        }
    }

    private func row(_ conversation: Conversation) -> some View {
        let isCurrent = conversation.id == chats.currentID
        return SwipeToDeleteRow(isOpen: openID == conversation.id) { open in
            // In the row's own spring: another row open closes with it.
            if open {
                openID = conversation.id
            } else if openID == conversation.id {
                openID = nil
            }
        } onTap: {
            // A tap while a row is open only closes it.
            guard openID == nil else {
                withAnimation(Motion.gentle(.snappy)) { openID = nil }
                return
            }
            chats.currentID = conversation.id
            dismiss()
        } onDelete: {
            pendingDeletion = conversation
        } content: {
            ChatHistoryRow(conversation: conversation, isCurrent: isCurrent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: "Xoá") { pendingDeletion = conversation }
    }

    // MARK: - Nhóm theo ngày

    struct DaySection {
        let title: String
        let chats: [Conversation]
    }

    /// Hôm nay, Hôm qua, 7 ngày qua and Trước đó, in that order, leaving out the empty ones.
    static func sections(of chats: [Conversation], now: Date = .now) -> [DaySection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        func bucket(_ date: Date) -> Int {
            if calendar.isDate(date, inSameDayAs: now) { return 0 }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
               calendar.isDate(date, inSameDayAs: yesterday) { return 1 }
            return date >= weekAgo ? 2 : 3
        }
        let titles = ["Hôm nay", "Hôm qua", "7 ngày qua", "Trước đó"]
        let grouped = Dictionary(grouping: chats) { bucket($0.lastActivity) }
        return (0..<titles.count).compactMap { index in
            grouped[index].map { DaySection(title: titles[index], chats: $0) }
        }
    }

    /// "14:30" today, "08/11" this year, "08/11/2025" before.
    static func when(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
            : date.shortDay
    }

    /// Milu's last words in a chat, on one line: the first line of its last answer, without the
    /// markdown's stars or a list's "•", or the app's own line ("Milu chưa kịp trả lời câu này");
    /// nil before any.
    static func lastWords(of chat: Conversation) -> String? {
        guard let message = chat.messages.last(where: { $0.role != .user }) else { return nil }
        let line = MessageRow.copiedText(of: message)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
        guard var line else { return nil }
        for marker in [AnswerMarkdown.bullet, "◦ "] where line.hasPrefix(marker) {
            line = String(line.dropFirst(marker.count))
        }
        return line
    }
}

/// A chat in the history, as every list row: its first question in `bodyStrong` and its time on
/// the right; Milu's last words under it in `caption`, and a ✓ on the chat that is open.
private struct ChatHistoryRow: View {
    let conversation: Conversation
    let isCurrent: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let large = dynamicTypeSize.isAccessibilitySize
        let words = ChatHistorySheet.lastWords(of: conversation)
        VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
            AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s, stackedSpacing: RowMetrics.lineGap) {
                Text(conversation.title)
                    .textRole(.bodyStrong)
                    .foregroundStyle(Palette.label)
                    .lineLimit(large ? 3 : 1)
                if !large { Spacer(minLength: Spacing.s) }
                Text(ChatHistorySheet.when(conversation.lastActivity))
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .monospacedDigit()
                    .accessibilityLabel(FormDateRow.spokenDays(in: ChatHistorySheet.when(conversation.lastActivity)))
            }
            if words != nil || isCurrent {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    Text(words ?? "")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(large ? 3 : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if isCurrent {
                        Image(systemName: "checkmark")
                            .font(.system(size: IconSize.inline, weight: .semibold))
                            .foregroundStyle(Palette.primary)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
    }
}

/// A row of a card that slides left under the thumb to show a red "Xoá" inside the card, never
/// past its edge (user choice 2026-11-17: iOS's own swipe drew its button outside the card, on the
/// page, and cut the card in two). Moved as iOS moves its own rows (user report 2026-11-17: it
/// jerked away and back): it follows the finger from where the drag began, gives less and less
/// past open, and when let go settles in one spring that carries on at the finger's speed, open
/// on a flick left or past half its "Xoá", closed on a flick right or short of it. It never
/// slides right of its place. Only a sideways drag moves it (`sidewaysDrag`): up and down scroll.
private struct SwipeToDeleteRow<Content: View>: View {
    /// Open as the list wants it: false when another row opens, the list scrolls or a tap closes it.
    let isOpen: Bool
    /// Tells the list the row opened or closed under the finger, once it has moved.
    let setOpen: (Bool) -> Void
    let onTap: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    /// How far the finger has moved the row since the drag began; 0 at rest. The row's one state of
    /// movement: two (a drag that resets and an open that changes) ran two animations at once.
    @State private var drag: CGFloat = 0
    /// Open or closed, kept by the row itself, so a drag let go changes it and `drag` in one update
    /// (Simulator 2026-11-17, frame by frame: kept by the list, the row first sprang back to where
    /// it was, then on to where it went). Follows `isOpen` when the list changes it.
    @State private var open = false
    /// When the last sideways drag ended: the tap iOS may still send as the finger lifts is not one.
    @State private var lastSwipe = Date.distantPast
    @ScaledMetric(relativeTo: .headline) private var buttonWidth: CGFloat = 76

    /// How far the row slides to show "Xoá" with its margins.
    private var reveal: CGFloat { buttonWidth + 2 * Spacing.s }

    /// A flick this fast (points a second) opens or closes the row however far it went.
    private var flick: CGFloat { 400 }

    var body: some View {
        let offset = position(resting + drag)
        let shown = min(1, -offset / reveal)
        ZStack(alignment: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Text("Xoá")
                    .textRole(.button)
                    .foregroundStyle(Palette.onNegative)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Palette.negative, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
            }
            .buttonStyle(.card)
            .padding(Spacing.s)
            .opacity(shown)
            .scaleEffect(0.8 + 0.2 * shown, anchor: .trailing)
            .allowsHitTesting(open)
            .accessibilityHidden(true)
            Button {
                guard Date.now.timeIntervalSince(lastSwipe) > 0.35 else { return }
                onTap()
            } label: {
                content
                    .contentShape(Rectangle())
            }
            .buttonStyle(.row)
            // Solid, so "Xoá" shows only where the row has moved off it; clear along its top, where
            // the line over it is drawn (`separatorAbove`).
            .background(Palette.surface.padding(.top, RowMetrics.separator))
            .offset(x: offset)
        }
        .sidewaysDrag { distance in
            // With the finger, never animated.
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) { drag = distance }
        } onEnded: { distance, speed in
            lastSwipe = .now
            settle(from: position(resting + distance), speed: speed)
        }
        .onAppear { open = isOpen }
        .onChange(of: isOpen) { _, wanted in
            guard wanted != open else { return }
            withAnimation(Motion.gentle(.snappy)) { open = wanted }
        }
    }

    /// Where the row rests: closed, or slid left by its "Xoá".
    private var resting: CGFloat { open ? -reveal : 0 }

    /// Where the row sits for a finger at `raw` (0 closed, −reveal open): never right of closed;
    /// past open it follows less and less, as a scroll view past its end.
    private func position(_ raw: CGFloat) -> CGFloat {
        if raw >= 0 { return 0 }
        guard raw < -reveal else { return raw }
        return -reveal - Self.rubberBand(-reveal - raw)
    }

    /// UIScrollView's rubber band: `distance` past the end gives at most `limit`.
    private static func rubberBand(_ distance: CGFloat, limit: CGFloat = 60) -> CGFloat {
        (1 - 1 / (distance * 0.55 / limit + 1)) * limit
    }

    /// Open or closed from where it was let go, in one spring: the drag's own distance and the
    /// open state change together, and the spring starts at the finger's speed.
    private func settle(from current: CGFloat, speed: CGFloat) {
        let opens = speed < -flick ? true : speed > flick ? false : current < -reveal / 2
        let target: CGFloat = opens ? -reveal : 0
        let way = target - current
        // The spring's speed is a share of the way left each second; none against the way, and
        // none over the last few points, where a finger still drifting sent it far past and back
        // (Simulator 2026-11-17). Kept under the spring's own pace (2π / 0.35 s), so it never
        // overshoots.
        let carried = abs(way) < 12 ? 0 : min(max(speed / way, 0), 12)
        withAnimation(Motion.gentle(.interpolatingSpring(duration: 0.35, bounce: 0, initialVelocity: carried))) {
            drag = 0
            open = opens
        }
        if opens != isOpen { setOpen(opens) }
    }
}
