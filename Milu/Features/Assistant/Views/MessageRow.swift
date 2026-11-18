import SwiftUI

/// One message of the chat: the user's in a bubble at the right; Milu's on the page itself, with
/// no bubble, avatar or name (user design 2026-11-15, Figma "12 · Milu · Trợ lý AI", as Claude and
/// ChatGPT), under how long it thought, with the card of a transaction it recorded or is asked to
/// delete, and "Sao chép" / "Hỏi lại".
struct MessageRow: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.onBubbleFrame) private var onBubbleFrame
    @Environment(\.chatRowWidth) private var rowWidth
    /// This answer just came in: its words show one after another (`AnswerWords`), then its card
    /// pops up and its buttons come.
    @Environment(\.revealsAnswer) private var revealsAnswer
    @Environment(\.resizeChatRow) private var resizeChatRow
    @Environment(\.unfoldChatRow) private var unfoldChatRow
    @Environment(\.slideChatRows) private var slideChatRows
    let message: ChatMessage
    let onAction: (CardAction, ChatMessage) -> Void
    @State private var revealDone = false
    /// The answer's steps laid out under "Đã nghĩ …", and drawn (they fade in once laid out, and
    /// out before they go).
    @State private var thoughtOpen = false
    @State private var stepsShown = false
    /// The steps are opening or closing: a tap then waits.
    @State private var thoughtMoving = false
    /// The chevron by "Đã nghĩ …" points down: turned at the tap.
    @State private var chevronOpen = false
    /// The room the answer's steps take once open (`ThoughtLine`).
    @State private var stepsRoom: CGFloat = 0
    /// How far up the words under the steps are drawn while they slide down into place.
    @State private var answerLift: CGFloat = 0
    /// How far that was as the slide began: what is left of it is told to the chat as it goes.
    @State private var liftWhole: CGFloat = 0
    @State private var copied = false
    /// Counted up as its card is saved: the tick by "Đã lưu" bounces.
    @State private var savedBounces = 0

    private var revealing: Bool { revealsAnswer && !revealDone }

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 0)
                // As wide as its words, which are never wider than the field's (`QuestionWords`).
                UserBubble(text: message.text)
                    .modifier(ReportsBubbleFrame(report: onBubbleFrame))
            }
            // Never narrower than the row, asked its size with no width (as iOS does when it lifts
            // the bubble for its menu): sized to the bubble alone, the row came back with it
            // mid-row for a moment (frames, 2026-11-12).
            .frame(minWidth: rowWidth, maxWidth: .infinity, alignment: .trailing)
        case .assistant:
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let thought = message.thought {
                    ThoughtLine(thought: thought, expanded: thoughtOpen, stepsShown: stepsShown,
                                turned: chevronOpen, toggle: toggleThought) { stepsRoom = $0 }
                        .modifier(FadesInAfterThinking(active: revealsAnswer))
                }
                answer
                    // Drawn moved, never laid out moved: the row keeps its height while it slides.
                    // The rows below are told how much of the way is left, at every frame.
                    .modifier(Lifted(lift: answerLift, whole: liftWhole, report: slideChatRows))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .notice:
            // A quiet line where the answer would have been, as ChatGPT and Claude say it.
            Label(message.text, systemImage: "stop.circle")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
        }
    }

    private var answer: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // Words to select and copy, as in ChatGPT and Claude: no hold menu on an answer
            // (user request 2026-11-11).
            AnswerWords(text: formattedText, reveals: revealsAnswer) {
                revealDone = true
                // The card pops up as the words are done: a "done" tap with it. None for a card
                // waiting for "Lưu": nothing is done yet.
                if case .recorded = message.card { Haptics.milestone() }
            }
            // Money and days said as words, as on every other screen (audit round 5, 2026-11-16:
            // "đ" was read as a letter, "23/11" as a fraction).
            .accessibilityLabel(SpokenText.of(String(formattedText.characters)))
            // The card's buttons inside it, at its foot (user feedback 2026-11-17).
            if let transaction = cardTransaction {
                TransactionCard(transaction: transaction, actions: cardActions)
                    .modifier(PopsIn(hidden: revealing))
            }
            if case .draft(let draft) = message.card {
                DraftCard(draft: draft, onRow: { id in
                    onAction(draft.isPending ? .editRow(id) : .viewRow(id), message)
                }, actions: cardActions)
                .modifier(PopsIn(hidden: revealing))
            }
            if let status = cardStatus {
                HStack(spacing: Spacing.xs + 2) {
                    // Saved: the steps' own tick before the words, with a small bounce as "Lưu"
                    // is tapped (the card changed with nothing to mark the moment, 2026-11-18).
                    if isSaved {
                        Image(systemName: "checkmark")
                            .font(.system(size: IconSize.inline - 2, weight: .bold))
                            .foregroundStyle(Palette.positive)
                            .symbolEffect(.bounce, value: savedBounces)
                            .accessibilityHidden(true)
                    }
                    Text(status)
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryLabel)
                }
            }
            if message.card == nil, message.isLocal != true {
                answerActions
                    .opacity(revealing ? 0 : 1)
                    .animation(Motion.gentle(.easeOut(duration: 0.25).delay(0.15)), value: revealing)
            }
        }
        .onChange(of: isSaved) { _, saved in
            guard saved, !UIAccessibility.isReduceMotionEnabled else { return }
            // As the card as it was has faded from over it (`ChatViewController.crossOver`).
            Task {
                try? await Task.sleep(for: .seconds(0.2))
                savedBounces += 1
            }
        }
    }

    /// A card of several rows or one, saved and not since deleted.
    private var isSaved: Bool {
        if case .draft(let draft) = message.card { draft.state == .saved && !draft.liveRows.isEmpty } else { false }
    }

    /// The steps opened or closed, the same way run forwards or backwards (user report 2026-11-18:
    /// opening an older answer's steps, the rows below jumped 29pt in one frame and the words
    /// slid a tenth of a second later; closing, the words slid up and the rows below followed
    /// after them: two moves each time, measured frame by frame).
    ///
    /// 1. At the tap the chevron turns, and the row takes its new height at once and unseen:
    ///    the steps' room is there or gone (`ThoughtLine`), the words under it are drawn where
    ///    they were (`answerLift`), and so is every row below (`unfoldChatRow`).
    /// 2. A moment later, in one go: the words slide to where they now are on a spring
    ///    (`ChatMotion.unfold`) and tell the chat at every frame how far they have left, so the
    ///    rows below go with them as one (`Lifted`); the steps fade in over their room, or out.
    ///
    /// Nothing is laid out while anything moves: an animation running as the row changed its
    /// height had iOS resize the cell on its own curve (`ThoughtLine`).
    private func toggleThought() {
        guard !thoughtMoving else { return }
        let opens = !thoughtOpen
        guard !UIAccessibility.isReduceMotionEnabled, stepsRoom > 0 else {
            thoughtOpen = opens
            stepsShown = opens
            chevronOpen = opens
            resizeChatRow?(message.id)
            return
        }
        thoughtMoving = true
        withAnimation(ChatMotion.unfold) { chevronOpen = opens }
        liftWhole = opens ? -stepsRoom : stepsRoom
        answerLift = liftWhole
        thoughtOpen = opens
        unfoldChatRow?(message.id)
        ChatMotion.afterResize {
            withAnimation(ChatMotion.unfold) {
                answerLift = 0
            } completion: {
                slideChatRows?(0)
                thoughtMoving = false
            }
            // Opening, the steps come into the room the words have begun to leave; closing,
            // they are gone before the words reach them.
            withAnimation(opens ? .easeOut(duration: 0.2).delay(0.08) : .easeOut(duration: 0.12)) { stepsShown = opens }
        }
    }

    /// "Sao chép" and "Hỏi lại" under an answer with no card: "Hỏi lại" asks its question once
    /// more, at the chat's end. Not under a card, where asking again would record or delete again.
    private var answerActions: some View {
        HStack(spacing: Spacing.xs) {
            answerAction(copied ? "Đã chép" : "Sao chép", icon: copied ? "checkmark" : "doc.on.doc") {
                UIPasteboard.general.string = Self.copiedText(of: message)
                Haptics.selection()
                withAnimation(Motion.gentle(.easeOut(duration: 0.2))) { copied = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    withAnimation(Motion.gentle(.easeOut(duration: 0.2))) { copied = false }
                }
            }
            answerAction("Hỏi lại", icon: "arrow.clockwise") { onAction(.retry, message) }
        }
        // Their glyphs in line with the words' edge.
        .padding(.leading, -Spacing.s)
    }

    private func answerAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs + 2) {
                Image(systemName: icon)
                    .font(.system(size: IconSize.inline, weight: .medium))
                    .frame(width: IconSize.inline + 4)
                    .contentTransition(.symbolEffect(.replace))
                Text(title)
                    .textRole(.caption)
                    .contentTransition(.opacity)
            }
            .foregroundStyle(Palette.tertiaryLabel)
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: ControlHeight.regular)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Shows the live transaction (after edits) while it exists, else the snapshot.
    private var cardTransaction: FinanceTransaction? {
        switch message.card {
        case .recorded(let snapshot, _), .confirmDelete(let snapshot, _):
            store.transaction(id: snapshot.id) ?? snapshot
        case .draft, nil: nil
        }
    }

    private var cardStatus: String? {
        switch message.card {
        // Short, like every status line (re-review 2026-10-31).
        case .recorded(_, removed: true), .confirmDelete(_, .deleted): "Đã xoá khoản này."
        case .confirmDelete(_, .cancelled): "Đã giữ lại khoản này."
        case .draft(let draft):
            switch draft.state {
            case .pending: nil
            case .saved: draft.liveRows.isEmpty ? "Đã xoá các khoản này." : draft.liveRows.count == 1 ? "Đã lưu." : "Đã lưu \(draft.liveRows.count) khoản."
            case .cancelled: "Đã huỷ, Milu chưa ghi gì."
            case .replaced: "Đã thay bằng bản mới bên dưới."
            }
        default: nil
        }
    }

    /// The card's buttons, for inside it; none, nil (no tear).
    private var cardActions: AnyView? {
        switch message.card {
        case .recorded(let snapshot, removed: false) where store.transaction(id: snapshot.id) != nil:
            // "Xem": it opens the transaction's sheet, where it is edited (strict review
            // 2026-10-31: "Sửa" promised an editor and showed the detail).
            AnyView(HStack(spacing: Spacing.s) {
                cardButton("Xem", icon: "hugeicons-eye", color: Palette.label) { onAction(.view, message) }
                cardButton("Xoá", icon: "hugeicons-delete-02", color: Palette.negative) { onAction(.remove, message) }
            })
        case .confirmDelete(let snapshot, .pending) where store.transaction(id: snapshot.id) != nil:
            AnyView(HStack(spacing: Spacing.s) {
                cardButton("Huỷ", color: Palette.label) { onAction(.cancel, message) }
                cardButton("Xoá khoản này", color: Palette.onNegative, fill: Palette.negative, role: .destructive) {
                    onAction(.confirm, message)
                }
            })
        case .draft(let draft) where draft.isPending:
            // Nothing is saved before this "Lưu" (user choice 2026-11-17).
            AnyView(HStack(spacing: Spacing.s) {
                cardButton("Huỷ", color: Palette.label) { onAction(.cancel, message) }
                cardButton(draft.liveRows.count > 1 ? "Lưu cả \(draft.liveRows.count)" : "Lưu",
                           color: Palette.onPrimary, fill: Palette.primary) {
                    onAction(.confirm, message)
                }
            })
        case .draft(let draft) where draft.state == .saved && draft.liveRows.count == 1
            && draft.liveRows.first.map({ store.transaction(id: $0.id) != nil }) == true:
            // One saved: seen or deleted as a recorded one always was; several open from their rows.
            AnyView(HStack(spacing: Spacing.s) {
                cardButton("Xem", icon: "hugeicons-eye", color: Palette.label) { onAction(.view, message) }
                cardButton("Xoá", icon: "hugeicons-delete-02", color: Palette.negative) { onAction(.remove, message) }
            })
        default:
            nil
        }
    }

    /// A flat capsule at least 44 tall: no Liquid Glass inside the chat, which scrolls (re-review
    /// 2026-10-31: glass, and ~34 tall). Its words and icon as on every button 44 tall
    /// (`MiluButton`: `button`, a 20 icon 8 before them; review 2026-11-17: 13 and 14, a size of
    /// their own).
    private func cardButton(_ title: String, icon: String? = nil, color: Color, fill: Color = Palette.fill,
                            role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            HStack(spacing: Spacing.s) {
                if let icon {
                    MiluIcon(icon, size: IconSize.control)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .textRole(.button)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.l)
            .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
        }
        .flatCapsuleButton(fill: fill)
    }

    /// Hiển thị **in đậm** và _in nghiêng_ theo cú pháp Markdown, giữ nguyên xuống dòng. Read
    /// once per answer and kept: an answer's text never changes.
    private var formattedText: AttributedString { Self.formatted(message.text) }

    static func formatted(_ markdown: String) -> AttributedString {
        if let cached = formatted[markdown] { return cached }
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        // Lists and headings put in the chat's one way first: only bold and italic are read below,
        // and a model's "* item" showed its star, beside a "•" (user report 2026-11-12).
        let clean = AnswerMarkdown.normalized(markdown)
        let text = (try? AttributedString(markdown: clean, options: options)) ?? AttributedString(clean)
        if formatted.count > 200 { formatted.removeAll() }
        formatted[markdown] = text
        return text
    }

    /// The words "Sao chép" puts on the clipboard: the question as typed, the answer without the
    /// markdown's stars.
    static func copiedText(of message: ChatMessage) -> String {
        switch message.role {
        case .user, .notice: message.text
        case .assistant: String(formatted(message.text).characters)
        }
    }

    private static var formatted: [String: AttributedString] = [:]
}

/// The transaction an answer recorded or asks to delete: the same row as every list of
/// transactions (`TransactionListRow`: plain icon, `MoneyText` with its sign and colour), on a card
/// of its own now that the answer has no bubble (user design 2026-11-15).
private struct TransactionCard: View {
    let transaction: FinanceTransaction
    /// Xem and Xoá, or Huỷ and Xoá khoản này: inside the card, at its foot (user feedback
    /// 2026-11-17).
    var actions: AnyView? = nil

    var body: some View {
        VStack(spacing: 0) {
            TransactionListRow(transaction: transaction, detail: .day)
                .accessibilityElement(children: .combine)
            if let actions {
                actions
                    .padding(.horizontal, RowMetrics.horizontal)
                    .padding(.bottom, Spacing.m)
            }
        }
        .cardSurface(radius: CardCorners.card)
        .cardShadow()
    }
}

/// An answer's words drawn `lift` off their place, and, as that eases to nothing, the chat told
/// at every frame how much of `whole` is left: the rows below are drawn that much off theirs
/// (`ChatViewController.slideRows`), in the same frame, so they and the words move as one.
private struct Lifted: ViewModifier, @preconcurrency Animatable {
    var lift: CGFloat
    let whole: CGFloat
    let report: ((CGFloat) -> Void)?

    var animatableData: CGFloat {
        get { lift }
        set {
            lift = newValue
            if whole != 0 { report?(newValue / whole) }
        }
    }

    func body(content: Content) -> some View {
        content.offset(y: lift)
    }
}

/// The answer's first line coming in a beat after it does, as "Đang nghĩ…" fades away in its
/// place: the two crossed at once, one over the other (frames, 2026-11-15).
private struct FadesInAfterThinking: ViewModifier {
    let active: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(active && !shown ? 0 : 1)
            .onAppear {
                guard active else { return }
                withAnimation(Motion.gentle(.easeOut(duration: 0.25).delay(0.12))) { shown = true }
            }
    }
}

/// Hidden while the answer's words show, then popping up: from 96% and clear to whole, on a
/// spring (user design 2026-11-15). Under Reduce Motion, there at once.
private struct PopsIn: ViewModifier {
    let hidden: Bool
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(hidden ? 0 : 1)
            .scaleEffect(hidden ? 0.96 : 1, anchor: .top)
            .animation(Motion.gentle(.spring(duration: 0.45, bounce: 0.3).delay(delay)), value: hidden)
    }
}

/// The user's words in their blue bubble: the chat's row, and the bubble that flies up from the
/// field as a question is sent (`ChatViewController.fly`), so the two are one drawing.
struct UserBubble: View {
    let text: String

    var body: some View {
        // Set as the field sets its words, so its lines break where they did as it was typed.
        QuestionWords(text: text)
            .accessibilityLabel(text)
            .padding(.horizontal, Bubble.userInset.leading)
            .padding(.vertical, Bubble.userInset.top)
            .background(Palette.primary, in: Bubble.userShape)
    }
}

/// Tells the chat where a message's bubble is in its row, so holding it lifts just the bubble
/// (`ChatViewController`'s hold menu). The menu is the list's, not SwiftUI's `.contextMenu`: inside
/// a UIKit list's row that one warns "_UIReparentingView … not supported" (user report 2026-11-11).
private struct ReportsBubbleFrame: ViewModifier {
    let report: ((CGRect) -> Void)?

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ChatRow.space)) } action: {
            report?($0)
        }
    }
}

enum ChatRow {
    /// The coordinate space of a chat row's content, inside the row's margins.
    static let space = "chatRow"
}

extension EnvironmentValues {
    /// The answer row just in, whose words show one after another (`ChatViewController`).
    @Entry var revealsAnswer = false
    /// Has the chat take a message's row's new height at once (`ChatViewController`).
    @Entry var resizeChatRow: ((UUID) -> Void)? = nil
    /// The same for the row of "Đang nghĩ…", a step more under it.
    @Entry var resizeThinkingRow: (() -> Void)? = nil
    /// A message's row to its new height at once, every row on screen drawn where it was; then
    /// `slideChatRows` is told how much of the way to where they are is left, 1 to 0
    /// (`MessageRow.toggleThought`).
    @Entry var unfoldChatRow: ((UUID) -> Void)? = nil
    @Entry var slideChatRows: ((CGFloat) -> Void)? = nil
    /// Where the row's bubble is, in `ChatRow.space`.
    @Entry var onBubbleFrame: ((CGRect) -> Void)? = nil
    /// The chat's rows' width, inside their margins (`ChatViewController`).
    @Entry var chatRowWidth: CGFloat? = nil
}

enum Bubble {
    /// A bubble rounds like a list card, with a small tail corner (re-review 2026-10-31:
    /// written as 24 and 8; a `CardCorners.bubbleTail` token would be the clean home for the 8).
    static let radius = CardCorners.card
    static let tail = CardCorners.small
    /// The user's bubble around its words, and its shape.
    static let userInset = EdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l)
    static let userShape = UnevenRoundedRectangle(
        topLeadingRadius: radius, bottomLeadingRadius: radius,
        bottomTrailingRadius: radius, topTrailingRadius: tail, style: .continuous)

    /// Milu's bubble's outline: its tail corner under the name.
    static let assistantOutline = UnevenRoundedRectangle(
        topLeadingRadius: tail, bottomLeadingRadius: radius,
        bottomTrailingRadius: radius, topTrailingRadius: radius, style: .continuous)

    /// Milu's bubble, in the card colour with the cards' edge, its tail corner under the name.
    static var assistantShape: some View {
        assistantOutline
            .fill(Palette.surface)
            .cardShadow()
    }
}

/// An answer's text in the chat's one layout, whatever markdown the model wrote: a list item is a
/// line starting "• " ("◦ " under another), a heading a bold line, rules and quote marks gone;
/// no blank line between items, at most one elsewhere. Bold and italic are left for the
/// markdown reader.
enum AnswerMarkdown {
    static let bullet = "• "
    static let subBullet = "    ◦ "

    static func normalized(_ text: String) -> String {
        var lines: [String] = []
        for raw in text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n") {
            var line = raw.replacingOccurrences(of: "\t", with: "    ")
            while line.last == " " { line.removeLast() }
            let body = String(line.drop(while: { $0 == " " }))
            let indent = line.count - body.count
            if let item = firstMatch(of: listItem, in: body), !item.isEmpty {
                lines.append((indent >= 2 ? subBullet : bullet) + item)
            } else if let title = firstMatch(of: heading, in: body), !title.isEmpty {
                lines.append("**\(title)**")
            } else if body.wholeMatch(of: rule) != nil {
                continue
            } else if body.hasPrefix(">") {
                lines.append(String(body.dropFirst()).trimmingCharacters(in: .whitespaces))
            } else {
                lines.append(body)
            }
        }
        var out: [String] = []
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                // Never two in a row, never first, never between two items.
                guard let last = out.last, !last.isEmpty else { continue }
                let next = lines[(index + 1)...].first { !$0.isEmpty }
                if isItem(last), next.map(isItem) == true { continue }
            }
            out.append(line)
        }
        while out.last?.isEmpty == true { out.removeLast() }
        return out.joined(separator: "\n")
    }

    static func isItem(_ line: String) -> Bool {
        line.hasPrefix(bullet) || line.hasPrefix(subBullet)
    }

    /// "* x", "- x", "+ x", "• x", "• * x": one or more markers, each followed by a space. "**bold**"
    /// and "*italic*" at a line's start have no space after the star and stay as they are.
    private static let listItem = /^(?:[*\-+•·●▪◦]\s+)+(.*)$/
    private static let heading = /^#{1,6}\s+(.*)$/
    private static let rule = /([-*_])\s*(?:\1\s*){2,}/

    private static func firstMatch(of regex: Regex<(Substring, Substring)>, in text: String) -> String? {
        text.wholeMatch(of: regex).map { String($0.1).trimmingCharacters(in: .whitespaces) }
    }
}
