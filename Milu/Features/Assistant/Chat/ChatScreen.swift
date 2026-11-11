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
