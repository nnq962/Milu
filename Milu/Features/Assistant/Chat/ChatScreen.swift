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
    /// A question is out and Milu's answer not in yet: three dots under the last message.
    let isThinking: Bool
    @Binding var draft: String
    /// Listening or turning the voice into words: the field is hidden, `fieldOverlay` in its place.
    let isDictating: Bool
    /// ✕ at the field's start and ■ before the action button, only while listening.
    let showsLeading: Bool
    let isOutOfQuestions: Bool
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
            draft: self.draft,
            isDictating: isDictating,
            showsLeading: showsLeading,
            isOutOfQuestions: isOutOfQuestions,
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
struct AnswerWords: UIViewRepresentable {
    let text: AttributedString

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var shown: AttributedString?
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
        guard context.coordinator.shown != text else { return }
        context.coordinator.shown = text
        view.attributedText = Self.attributed(text)
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
        hangItems(in: result, font: regular, base: paragraph)
        return result
    }

    /// A list item's lines after its first start under its words, not under its "•", as lists
    /// are set everywhere (user report 2026-11-12: wrapped lines ran back to the margin).
    private static func hangItems(in text: NSMutableAttributedString, font: UIFont, base: NSParagraphStyle) {
        let string = text.string as NSString
        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: .byParagraphs) { paragraph, range, _, _ in
            guard let paragraph,
                  let marker = [AnswerMarkdown.subBullet, AnswerMarkdown.bullet].first(where: paragraph.hasPrefix)
                    ?? paragraph.firstMatch(of: #/^\d{1,2}[.)] /#).map({ String($0.0) }) else { return }
            let style = base.mutableCopy() as! NSMutableParagraphStyle
            style.headIndent = ceil((marker as NSString).size(withAttributes: [.font: font]).width)
            text.addAttribute(.paragraphStyle, value: style, range: range)
        }
    }
}
