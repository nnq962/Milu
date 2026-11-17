import SwiftUI

/// The chat's page, built with UIKit (user choice 2026-11-11: SwiftUI's scroll view and text field
/// could not keep the caret, the keyboard and the end of the chat in step). `AssistantView` keeps
/// the data, the bar's buttons and the sheets; `ChatViewController` lays the messages, the field
/// and the keyboard out.
///
/// The parts built in SwiftUI (the rows, the buttons, the greeting) come in as views and are hosted
/// as they are.
struct ChatScreen: UIViewControllerRepresentable {
    let conversation: Conversation
    /// A question is out and Milu's answer not in yet: "Đang nghĩ…" under the last message.
    let isThinking: Bool
    /// What Milu has done so far on the answer on its way, listed under "Đang nghĩ…".
    let progress: AssistantProgress
    @Binding var draft: String
    /// Listening or turning the voice into words: the field is hidden, `fieldOverlay` in its place.
    let isDictating: Bool
    /// ✕ at the field's start and ■ before the action button, only while listening.
    let showsLeading: Bool
    let isOutOfQuestions: Bool
    /// The empty field's words: "Hỏi Milu", or for a moment why the mic stopped.
    var placeholder = ChatViewController.defaultPlaceholder
    let leading: AnyView
    let stop: AnyView
    let action: AnyView
    let fieldOverlay: AnyView
    let outOfQuestions: AnyView
    let greeting: AnyView
    let onAction: (CardAction, ChatMessage) -> Void

    @Environment(FinanceStore.self) private var store

    func makeUIViewController(context: Context) -> ChatViewController {
        ChatViewController(store: store)
    }

    func updateUIViewController(_ controller: ChatViewController, context: Context) {
        let draft = $draft
        controller.onDraftChange = { text in
            if draft.wrappedValue != text { draft.wrappedValue = text }
        }
        controller.onAction = onAction
        controller.update(ChatViewController.State(
            conversation: conversation,
            isThinking: isThinking,
            progress: progress,
            draft: self.draft,
            isDictating: isDictating,
            showsLeading: showsLeading,
            isOutOfQuestions: isOutOfQuestions,
            placeholder: placeholder,
            leading: leading,
            stop: stop,
            action: action,
            fieldOverlay: fieldOverlay,
            outOfQuestions: outOfQuestions,
            greeting: greeting
        ))
    }
}

/// The day a chat began, over its first message.
struct ChatDateChip: View {
    let date: Date

    var body: some View {
        Text(date.transactionDayTitle)
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryLabel)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background(Palette.surfaceMuted, in: Capsule())
            .frame(maxWidth: .infinity)
    }
}

/// How the chat's typed words are set, shared by the field and the question's bubble: one font,
/// one text engine (a `UITextView`), no padding at the sides. A question then breaks its lines in
/// its bubble exactly where it broke them in the field, and flies up unchanged (user report
/// 2026-11-11: with SwiftUI's `Text` in the bubble, the same width still broke some lines
/// elsewhere, two engines measuring words a hair apart).
enum ChatWords {
    /// Nunito Medium at the body size, scaled with Dynamic Type.
    static func font() -> UIFont {
        _ = Typography.font(.body, size: TextRole.body.size) // registers Nunito
        let base = UIFont(name: Typography.instance(for: .medium), size: TextRole.body.size)
            ?? .systemFont(ofSize: TextRole.body.size, weight: .medium)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base)
    }

    /// The words' setting on `textView`, the same for the field and the bubble.
    static func set(_ textView: UITextView) {
        textView.font = font()
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset.left = 0
        textView.textContainerInset.right = 0
    }
}

extension EnvironmentValues {
    /// How wide the field's words are (`ChatViewController` measures it): a question's words in
    /// its bubble are never wider, so they break where they broke in the field.
    @Entry var questionWordsWidth: CGFloat? = nil
}

/// A question's words in its bubble, set as the field sets them (`ChatWords`) and never wider
/// than the field's words (`questionWordsWidth`): read-only, no touches of its own, so holding
/// the bubble still opens its menu.
struct QuestionWords: UIViewRepresentable {
    let text: String
    @Environment(\.questionWordsWidth) private var widest

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        ChatWords.set(view)
        view.textContainerInset = .zero
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = false
        view.isUserInteractionEnabled = false
        view.textColor = UIColor(Palette.onPrimary)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if view.text != text { view.text = text }
    }

    /// As wide as its longest line, up to the width it is offered; as tall as its lines.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView view: UITextView, context: Context) -> CGSize? {
        let width = min(proposal.width ?? .greatestFiniteMagnitude, widest ?? .greatestFiniteMagnitude)
        let fits = view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: min(ceil(fits.width), width), height: ceil(fits.height))
    }
}

/// Milu's answer's words: selectable, as in ChatGPT and Claude (user request 2026-11-11), held to
/// select a word and dragged for more, with iOS's own Copy. Set as the body text is (Nunito
/// Medium, its 24 line), **bold** and _italic_ kept.
///
/// `reveals`: an answer just in shows its words one after another, each fading in (user design
/// 2026-11-15), laid out from the start where they end up; `onRevealed` once all are shown.
struct AnswerWords: UIViewRepresentable {
    let text: AttributedString
    var reveals = false
    var onRevealed: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var shown: AttributedString?
        var reveal: WordReveal?
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        ChatWords.set(view)
        // Set again whole when the text size changes: iOS scaled the letters but kept the old line
        // height, and the lines ran into each other (Simulator, 2026-11-12).
        view.adjustsFontForContentSizeCategory = false
        let coordinator = context.coordinator
        view.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: UITextView, _) in
            if let text = coordinator.shown { view.attributedText = Self.attributed(text) }
        }
        view.textContainerInset = .zero
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.dataDetectorTypes = []
        view.tintColor = UIColor(Palette.primary)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        // Set only when the words change: set again, the reader's selection went.
        let coordinator = context.coordinator
        guard coordinator.shown != text else { return }
        let first = coordinator.shown == nil
        coordinator.shown = text
        coordinator.reveal?.stop()
        coordinator.reveal = nil
        let attributed = Self.attributed(text)
        view.attributedText = attributed
        guard reveals else { return }
        if first, !UIAccessibility.isReduceMotionEnabled {
            coordinator.reveal = WordReveal(view: view, text: attributed) { [weak coordinator] in
                coordinator?.reveal = nil
                onRevealed?()
            }
        } else {
            // Not in this update: the row's state changes with it.
            DispatchQueue.main.async { onRevealed?() }
        }
    }

    /// As wide as its longest line, up to the width it is offered; as tall as its lines.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView view: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? .greatestFiniteMagnitude
        let fits = view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: min(ceil(fits.width), width), height: ceil(fits.height))
    }

    /// The markdown's runs in Nunito at the body size, each line 24 tall (scaled), as
    /// `textRole(.body)` sets SwiftUI's text.
    static func attributed(_ text: AttributedString) -> NSAttributedString {
        let metrics = UIFontMetrics(forTextStyle: .body)
        let size = TextRole.body.size
        func font(_ name: String) -> UIFont {
            metrics.scaledFont(for: UIFont(name: name, size: size) ?? .systemFont(ofSize: size))
        }
        let regular = ChatWords.font()
        let bold = font(Typography.instance(for: .bold))
        let line = metrics.scaledValue(for: TextRole.body.lineHeight ?? 24)
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = line
        paragraph.maximumLineHeight = line
        let color = UIColor(Palette.label)

        let result = NSMutableAttributedString()
        for run in text.runs {
            let intent = run.inlinePresentationIntent ?? []
            var runFont = intent.contains(.stronglyEmphasized) ? bold : regular
            if intent.contains(.emphasized),
               let italic = runFont.fontDescriptor.withSymbolicTraits(runFont.fontDescriptor.symbolicTraits.union(.traitItalic)) {
                runFont = UIFont(descriptor: italic, size: runFont.pointSize)
            }
            result.append(NSAttributedString(string: String(text[run.range].characters), attributes: [
                .font: runFont,
                .foregroundColor: color,
                .paragraphStyle: paragraph,
                // The words in the middle of their line, not at its foot.
                .baselineOffset: (line - runFont.lineHeight) / 4,
            ]))
        }
        setParagraphs(in: result, font: regular, base: paragraph, metrics: metrics)
        return result
    }

    /// What a paragraph of an answer is: words, a list's item ("• ", "◦ " under it, "1. "), or the
    /// blank line between two parts.
    private enum Block: Equatable {
        case blank, words, item(level: Int), numbered

        var isItem: Bool { self != .blank && self != .words }
    }

    /// An answer's paragraphs set as Claude and ChatGPT set theirs (user report 2026-11-15: the
    /// "•" stood on the margin, and a blank line between two parts took a whole empty line):
    /// - a list stands in from the margin, its "•" a little in and its words further in, every
    ///   line of an item under its words; an item under another stands in once more;
    /// - a little room between items, a little more where a list starts or ends, and a part
    ///   after a blank line starts a paragraph's gap lower, the blank line itself gone.
    private static func setParagraphs(in text: NSMutableAttributedString, font: UIFont, base: NSParagraphStyle,
                                      metrics: UIFontMetrics) {
        let string = text.string as NSString
        var paragraphs: [(range: NSRange, block: Block, marker: String)] = []
        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: .byParagraphs) { words, _, enclosing, _ in
            let words = words ?? ""
            if words.isEmpty {
                paragraphs.append((enclosing, .blank, ""))
            } else if words.hasPrefix(AnswerMarkdown.subBullet) {
                paragraphs.append((enclosing, .item(level: 1), AnswerMarkdown.subBullet))
            } else if words.hasPrefix(AnswerMarkdown.bullet) {
                paragraphs.append((enclosing, .item(level: 0), AnswerMarkdown.bullet))
            } else if let number = words.firstMatch(of: #/^\d{1,2}[.)] /#) {
                paragraphs.append((enclosing, .numbered, String(number.0)))
            } else {
                paragraphs.append((enclosing, .words, ""))
            }
        }

        let scaled = { metrics.scaledValue(for: $0) }
        /// Where the "•" stands, and where an item's words start, one level further in for each.
        let markerIn = scaled(Spacing.s), wordsIn = scaled(Spacing.xxl), levelIn = scaled(Spacing.l)
        let partGap = scaled(Spacing.m), listGap = scaled(Spacing.xs + 2), itemGap = scaled(Spacing.xs)

        // From the end, so a paragraph changed or taken out leaves the ranges before it as they are.
        for index in paragraphs.indices.reversed() {
            let (range, block, marker) = paragraphs[index]
            if block == .blank {
                text.deleteCharacters(in: range)
                continue
            }
            let before = index > 0 ? paragraphs[index - 1].block : nil
            let style = base.mutableCopy() as! NSMutableParagraphStyle
            switch before {
            case .blank?: style.paragraphSpacingBefore = partGap
            case let previous? where previous.isItem && block.isItem: style.paragraphSpacingBefore = itemGap
            case let previous? where previous.isItem != block.isItem: style.paragraphSpacingBefore = listGap
            default: break
            }
            var glyph = ""
            switch block {
            case .item(let level):
                style.firstLineHeadIndent = markerIn + CGFloat(level) * levelIn
                style.headIndent = wordsIn + CGFloat(level) * levelIn
                glyph = level == 0 ? "•" : "◦"
            case .numbered:
                let width = ceil((marker as NSString).size(withAttributes: [.font: font]).width)
                style.firstLineHeadIndent = scaled(Spacing.xs)
                style.headIndent = max(wordsIn, scaled(Spacing.xs) + width + scaled(Spacing.xs))
                glyph = marker.trimmingCharacters(in: .whitespaces)
            case .words, .blank:
                break
            }
            if block.isItem {
                // The marker, then a tab to where the words start: they line up whatever its width.
                style.tabStops = [NSTextTab(textAlignment: .natural, location: style.headIndent)]
                style.defaultTabInterval = style.headIndent
            }
            text.addAttribute(.paragraphStyle, value: style, range: range)
            if block.isItem {
                text.replaceCharacters(in: NSRange(location: range.location, length: (marker as NSString).length),
                                       with: glyph + "\t")
            }
        }
        // No line break left at the end once a blank line before it went.
        while text.string.hasSuffix("\n") { text.deleteCharacters(in: NSRange(location: text.length - 1, length: 1)) }
    }
}

/// How an answer's words come in: each fades in over `fade`, the next starting `stagger` after,
/// so a short answer reads as written and a long one still takes little more than a second.
enum AnswerReveal {
    static let fade: Double = 0.32

    static func stagger(_ words: Int) -> Double { min(0.02, 1.2 / Double(max(words, 1))) }

    /// From the first word starting to the last one shown.
    static func duration(words: Int) -> Double { stagger(words) * Double(max(words - 1, 0)) + fade }

    /// The words of `string`, as runs between spaces and line breaks (a "•" or a "12%," is one).
    static func words(in string: String) -> [NSRange] {
        let text = string as NSString
        let spaces = CharacterSet.whitespacesAndNewlines
        var ranges: [NSRange] = []
        var start: Int?
        for index in 0..<text.length {
            let isSpace = Unicode.Scalar(text.character(at: index)).map(spaces.contains) ?? false
            if isSpace {
                if let begun = start { ranges.append(NSRange(location: begun, length: index - begun)) }
                start = nil
            } else if start == nil {
                start = index
            }
        }
        if let begun = start { ranges.append(NSRange(location: begun, length: text.length - begun)) }
        return ranges
    }
}

/// An answer's words shown one after another in its text view: every word starts clear, then
/// each one's colour goes from clear to whole, frame by frame. Only the colour changes, so the
/// lines are where they end up from the first frame and the row never changes its height.
final class WordReveal: NSObject {
    private weak var view: UITextView?
    private let text: NSAttributedString
    private let words: [NSRange]
    private var shown: [CGFloat]
    private let color: UIColor
    private let stagger: Double
    private let start = CACurrentMediaTime()
    private var link: CADisplayLink?
    private let done: () -> Void

    init(view: UITextView, text: NSAttributedString, done: @escaping () -> Void) {
        self.view = view
        self.text = text
        self.done = done
        words = AnswerReveal.words(in: text.string)
        shown = Array(repeating: 0, count: words.count)
        stagger = AnswerReveal.stagger(words.count)
        color = text.length > 0 ? (text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? .label) : .label
        super.init()
        let storage = view.textStorage
        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: color.withAlphaComponent(0),
                             range: NSRange(location: 0, length: storage.length))
        storage.endEditing()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    @objc private func tick() {
        guard let view else { return stop() }
        let elapsed = CACurrentMediaTime() - start
        let storage = view.textStorage
        storage.beginEditing()
        for index in words.indices where shown[index] < 1 {
            let progress = (elapsed - Double(index) * stagger) / AnswerReveal.fade
            // The words after this one have not begun either.
            if progress <= 0 { break }
            let eased = 1 - pow(1 - min(progress, 1), 3)
            shown[index] = progress >= 1 ? 1 : CGFloat(eased)
            storage.addAttribute(.foregroundColor, value: color.withAlphaComponent(shown[index]), range: words[index])
        }
        storage.endEditing()
        if shown.allSatisfy({ $0 >= 1 }) { finish() }
    }

    /// All shown: the words set back as they are, then the row told.
    private func finish() {
        stop()
        view?.attributedText = text
        done()
    }

    func stop() {
        link?.invalidate()
        link = nil
    }
}
