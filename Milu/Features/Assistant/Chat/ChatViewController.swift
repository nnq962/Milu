import SwiftUI
import UIKit

/// The chat page in UIKit: the messages in a collection view that scrolls under the field, the
/// field (a `UITextView` in glass) riding on the keyboard through `keyboardLayoutGuide`, and the
/// greeting in the messages' place while the chat is empty.
///
/// Step 1 of the UIKit chat (user request 2026-11-11): iOS's own motion only. The chat keeps to
/// its end when it was there and the keyboard or the field changes its room.
final class ChatViewController: UIViewController {
    struct State {
        var conversation: Conversation
        var isThinking: Bool
        var draft: String
        var isDictating: Bool
        var showsLeading: Bool
        var isOutOfQuestions: Bool
        var leading: AnyView
        var stop: AnyView
        var action: AnyView
        var fieldOverlay: AnyView
        var outOfQuestions: AnyView
        var greeting: AnyView
    }

    var onDraftChange: (String) -> Void = { _ in }
    var onAction: (CardAction, ChatMessage) -> Void = { _, _ in }

    private let store: FinanceStore
    private var state: State?

    // MARK: Parts

    private nonisolated enum Item: Hashable, Sendable {
        case date
        case message(UUID)
        case typing
    }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Item>!
    /// Each message's bubble in its row (`ChatRow.space`), as the row reports it: what holding a
    /// message lifts.
    private var bubbleFrames: [UUID: CGRect] = [:]
    /// A message's hold menu is up. iOS puts the keyboard down for it and up again after; the
    /// chat followed it down and jumped back (user report 2026-11-11), so it is held still.
    private var menuHoldsChat = false
    /// The question held for its menu: the picture over its bubble and its hidden row.
    fileprivate var heldBubble: (id: UUID, picture: UIImageView, row: UIView, ending: Bool)?
    private var messagesByID: [UUID: ChatMessage] = [:]
    private var shownConversation: Conversation?
    private var shownThinking = false
    /// The chat keeps to its end as it grows, the rows find their heights (they start from an
    /// estimate) and the keyboard comes and goes, until the reader scrolls away; back at the end,
    /// it keeps there again (as Messages does).
    private var holdsToEnd = true
    private var contentSizeWatch: NSKeyValueObservation?

    /// Holds the field's glass, or the "out of questions" card in its place.
    private let bar = UIStackView()
    private let glass = UIVisualEffectView(effect: ChatViewController.glassEffect())
    private let fieldRow = UIStackView()
    private let fieldBox = UIView()
    private let textView = UITextView()
    private let placeholder = UILabel()
    /// The words' own height, set at once; the box around them (`boxHeight`) follows in an
    /// animation, so the line being typed never drops a line and climbs back (step 2 of the
    /// UIKit chat, user request 2026-11-11).
    private var textHeight: NSLayoutConstraint!
    private var boxHeight: NSLayoutConstraint!
    /// Growing, the words sit on the box's foot (the caret's line stays put, the box opens above);
    /// shrinking, they hang from its top and slide down with it (no line jumps down at once).
    private var textOnFoot: NSLayoutConstraint!
    private var textOnTop: NSLayoutConstraint!
    private var fieldLeading: NSLayoutConstraint!
    /// The width the field's height was measured at.
    private var measuredWidth: CGFloat = 0

    private let leadingHost = ChatViewController.host()
    private let stopHost = ChatViewController.host()
    private let actionHost = ChatViewController.host()
    /// Sized by the field it covers, never by itself: the wave redraws every frame, and a host
    /// that reported its size each time had UIKit lay the page out again and again until iOS
    /// killed the app (watchdog, iPhone 16 Pro, 2026-11-11).
    private let overlayHost = ChatViewController.host(sizing: false)
    private let outHost = ChatViewController.host()
    private let greetingHost = ChatViewController.host(sizing: false)

    // MARK: Metrics

    private static let buttonSize = ControlHeight.small
    private static let inset = Spacing.s
    private static let radius = buttonSize / 2 + inset
    private static let maxLines: CGFloat = 5

    private lazy var font: UIFont = ChatWords.font()

    init(store: FinanceStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Building

    override func viewDidLoad() {
        super.viewDidLoad()
        // The field's buttons knock evenly from the first tap (`Haptics.prepare`).
        Haptics.prepare()
        view.backgroundColor = .clear
        buildList()
        buildGreeting()
        buildBar()
        buildDownButton()
        // A tap on the chat or the greeting puts the keyboard away (user request 2026-11-11:
        // only a swipe down did). It rides along with every other touch, so scrolling, holding
        // to copy and the cards' buttons work as before, and it acts only with the keyboard up.
        for page in [collectionView!, greetingHost.view!] {
            let tap = UITapGestureRecognizer(target: self, action: #selector(putKeyboardAway))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            page.addGestureRecognizer(tap)
            keyboardTaps.append(tap)
        }
        view.keyboardLayoutGuide.followsUndockedKeyboard = true
        if #available(iOS 26.0, *) {
            // iOS's soft edge where the chat runs under the field, as under its own bars.
            let edge = UIScrollEdgeElementContainerInteraction()
            edge.scrollView = collectionView
            edge.edge = .bottom
            bar.addInteraction(edge)
        }
    }

    /// The top bar (SwiftUI's navigation bar) blurs the chat that runs under it, as it would its
    /// own scroll view: it is told which one through the screen it belongs to.
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        var screen = parent
        while let candidate = screen, !(candidate.parent is UINavigationController), let up = candidate.parent {
            screen = up
        }
        screen?.setContentScrollView(collectionView, for: .top)
    }

    private func buildList() {
        var layoutItem = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: layoutItem)
        layoutItem = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: layoutItem, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Spacing.xl
        section.contentInsets = NSDirectionalEdgeInsets(top: Spacing.l, leading: 0, bottom: Spacing.l, trailing: 0)

        collectionView = ChatList(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(section: section))
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        // The insets are set by hand: the bar's room at the foot changes with the keyboard.
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.allowsSelection = false
        collectionView.delegate = self
        collectionView.addInteraction(UIContextMenuInteraction(delegate: self))
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        contentSizeWatch = collectionView.observe(\.contentSize, options: [.old, .new]) { [weak self] _, change in
            guard change.oldValue != change.newValue else { return }
            MainActor.assumeIsolated { self?.contentSizeChanged() }
        }
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let registration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
            guard let self else { return }
            // A reused cell may still carry a reveal's mask (`reveal`).
            cell.contentView.layer.mask = nil
            cell.contentConfiguration = UIHostingConfiguration { self.row(for: item) }
                .margins(.horizontal, Spacing.l)
                .margins(.vertical, 0)
            // The question in flight is drawn by its flyer until it lands (`fly`); set after the
            // configuration, which puts up its own content view.
            cell.contentView.alpha = self.flyingID.map { item == .message($0) } == true ? 0 : 1
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }
    }

    @ViewBuilder
    private func row(for item: Item) -> some View {
        Group {
            switch item {
            case .date:
                ChatDateChip(date: state?.conversation.startedAt ?? .now)
            case .message(let id):
                if let message = messagesByID[id] {
                    MessageRow(message: message) { [weak self] action, message in
                        self?.onAction(action, message)
                    }
                    .environment(\.onBubbleFrame) { [weak self] frame in self?.bubbleFrames[id] = frame }
                }
            case .typing:
                TypingIndicator()
            }
        }
        .modifier(MiluEnvironment(store: store))
        .environment(\.questionWordsWidth, questionWordsWidth)
        .environment(\.chatRowWidth, max(0, collectionView.bounds.width - 2 * Spacing.l))
        .coordinateSpace(.named(ChatRow.space))
    }

    /// How wide the field's words are: measured once the field is laid out, worked out from the
    /// bar before (its inset each side, the words' lead, ↑ and its gap).
    private var questionWordsWidth: CGFloat {
        if textView.bounds.width > 0 { return textView.bounds.width }
        let row = (view.bounds.width > 0 ? view.bounds.width : collectionView.bounds.width) - 2 * Spacing.l
        return row - (2 * Self.inset + Spacing.s + Self.buttonSize + Spacing.s)
    }

    private func buildGreeting() {
        addHost(greetingHost)
        greetingHost.view.translatesAutoresizingMaskIntoConstraints = false
        // It takes the room the bar leaves, never the other way round.
        greetingHost.view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        greetingHost.view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
        view.addSubview(greetingHost.view)
        NSLayoutConstraint.activate([
            greetingHost.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            greetingHost.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            greetingHost.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func buildBar() {
        // The words, its hint and, while listening, what replaces them.
        // Set as the question's bubble sets them (`ChatWords`).
        ChatWords.set(textView)
        textView.textColor = Palette.uiLabel
        textView.tintColor = UIColor(Palette.primary)
        textView.isScrollEnabled = false
        let lineGap = max(Spacing.xs, (Self.buttonSize - font.lineHeight) / 2)
        textView.textContainerInset = UIEdgeInsets(top: lineGap, left: 0, bottom: lineGap, right: 0)
        // A question to Milu is sent as typed (user request 2026-11-10); ⏎ breaks a line.
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        if #available(iOS 18.0, *) { textView.writingToolsBehavior = .none }
        textView.accessibilityLabel = "Hỏi Milu"
        textView.delegate = self

        placeholder.text = "Hỏi Milu"
        placeholder.font = font
        placeholder.adjustsFontForContentSizeCategory = true
        placeholder.textColor = Palette.uiSecondaryLabel.withAlphaComponent(0.7)
        placeholder.isAccessibilityElement = false

        [textView, placeholder].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            fieldBox.addSubview($0)
        }
        addHost(overlayHost)
        overlayHost.view.translatesAutoresizingMaskIntoConstraints = false
        fieldBox.addSubview(overlayHost.view)
        textHeight = textView.heightAnchor.constraint(equalToConstant: Self.buttonSize)
        boxHeight = fieldBox.heightAnchor.constraint(equalToConstant: Self.buttonSize)
        fieldBox.clipsToBounds = true
        textOnFoot = textView.bottomAnchor.constraint(equalTo: fieldBox.bottomAnchor)
        textOnTop = textView.topAnchor.constraint(equalTo: fieldBox.topAnchor)
        textOnFoot.isActive = true
        fieldLeading = textView.leadingAnchor.constraint(equalTo: fieldBox.leadingAnchor, constant: Spacing.s)
        NSLayoutConstraint.activate([
            boxHeight,
            fieldLeading,
            textView.trailingAnchor.constraint(equalTo: fieldBox.trailingAnchor),
            textHeight,
            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholder.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor),
            placeholder.topAnchor.constraint(equalTo: textView.topAnchor, constant: lineGap),
            overlayHost.view.leadingAnchor.constraint(equalTo: fieldBox.leadingAnchor),
            overlayHost.view.trailingAnchor.constraint(equalTo: fieldBox.trailingAnchor),
            overlayHost.view.bottomAnchor.constraint(equalTo: fieldBox.bottomAnchor),
            overlayHost.view.heightAnchor.constraint(equalToConstant: Self.buttonSize),
        ])

        // ✕, the field, then ■ and the mic or ↑, on the field's last line.
        addHost(leadingHost)
        addHost(stopHost)
        addHost(actionHost)
        fieldRow.axis = .horizontal
        fieldRow.alignment = .bottom
        fieldRow.spacing = Spacing.s
        [leadingHost.view, fieldBox, stopHost.view, actionHost.view].forEach { fieldRow.addArrangedSubview($0) }
        fieldBox.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fieldBox.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        [leadingHost.view, stopHost.view, actionHost.view].forEach {
            $0?.setContentHuggingPriority(.required, for: .horizontal)
            $0?.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        glass.layer.cornerRadius = Self.radius
        glass.layer.cornerCurve = .continuous
        glass.clipsToBounds = true
        fieldRow.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView.addSubview(fieldRow)
        NSLayoutConstraint.activate([
            fieldRow.topAnchor.constraint(equalTo: glass.contentView.topAnchor, constant: Self.inset),
            fieldRow.bottomAnchor.constraint(equalTo: glass.contentView.bottomAnchor, constant: -Self.inset),
            fieldRow.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor, constant: Self.inset),
            fieldRow.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor, constant: -Self.inset),
        ])
        // A tap anywhere in the glass, not only on the words, opens the keyboard.
        let tap = UITapGestureRecognizer(target: self, action: #selector(focusField))
        tap.delegate = self
        glass.addGestureRecognizer(tap)

        addHost(outHost)
        bar.axis = .vertical
        bar.addArrangedSubview(glass)
        bar.addArrangedSubview(outHost.view)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.setContentHuggingPriority(.required, for: .vertical)
        bar.setContentCompressionResistancePriority(.required, for: .vertical)
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.l),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.l),
            bar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -Spacing.s),
            greetingHost.view.bottomAnchor.constraint(equalTo: bar.topAnchor),
        ])
    }

    private static func glassEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let glass = UIGlassEffect(style: .regular)
            glass.isInteractive = true
            return glass
        }
        return UIBlurEffect(style: .systemMaterial)
    }

    private static func host(sizing: Bool = true) -> UIHostingController<AnyView> {
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        host.view.backgroundColor = .clear
        // No safe area and no keyboard avoidance of SwiftUI's own: the page places these by hand.
        // With them, ✕ and ■ grew by the keyboard's overlap, which raised the bar, which changed
        // the overlap, again and again until iOS killed the app (mic with the keyboard up,
        // iPhone 16 Pro, 2026-11-11).
        host.safeAreaRegions = []
        if sizing { host.sizingOptions = .intrinsicContentSize }
        return host
    }

    private func addHost(_ host: UIViewController) {
        addChild(host)
        host.didMove(toParent: self)
    }

    // MARK: Updating

    /// The bar to how the page is now (`state`, the latest, whatever came since it was asked):
    /// ✕ and ■ grow in as the field makes room for them, or shrink away as it takes it back, on
    /// one spring; what is in the field goes first, quickly, then the other comes (crossed in one
    /// fade the words and the wave lay over each other, frames 2026-11-11).
    private func animateBar() {
        guard let state else { return }
        UIView.animate(springDuration: 0.35, bounce: 0.12, initialSpringVelocity: 0, delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.applyBar(state, fades: false)
            self.view.layoutIfNeeded()
        }
        let leaving = state.isDictating ? [textView, placeholder] : [overlayHost.view!]
        let coming = state.isDictating ? [overlayHost.view!] : [textView, placeholder]
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            leaving.forEach { $0.alpha = 0 }
        }
        UIView.animate(withDuration: 0.2, delay: 0.1, options: [.curveEaseOut, .beginFromCurrentState]) {
            coming.forEach { $0.alpha = 1 }
        }
    }

    /// The bar as `state` has it: ✕ and ■ while listening, the wave or the words in the field,
    /// or the "out of questions" card in the field's place. Run inside an animation, it animates.
    private func applyBar(_ state: State, fades: Bool = true) {
        for button in [leadingHost.view!, stopHost.view!] {
            // The stack view counts each `isHidden = true`: set it only when it changes.
            if button.isHidden == state.showsLeading { button.isHidden = !state.showsLeading }
            button.alpha = state.showsLeading ? 1 : 0
            button.transform = state.showsLeading ? .identity : CGAffineTransform(scaleX: 0.4, y: 0.4)
        }
        if glass.isHidden != state.isOutOfQuestions { glass.isHidden = state.isOutOfQuestions }
        if outHost.view.isHidden == state.isOutOfQuestions { outHost.view.isHidden = !state.isOutOfQuestions }
        glass.alpha = state.isOutOfQuestions ? 0 : 1
        outHost.view.alpha = state.isOutOfQuestions ? 1 : 0
        // Hidden, never disabled: a disabled field gives up the keyboard, and the keyboard going
        // down inside an update is where the page hung (iPhone 16 Pro, 2026-11-11). It stays up
        // while listening, as asked (user report 2026-11-10); the wave covers the field's taps and
        // `shouldChangeTextIn` its typing. (A view at alpha 0 takes no taps either.)
        if fades {
            textView.alpha = state.isDictating ? 0 : 1
            placeholder.alpha = state.isDictating ? 0 : 1
            overlayHost.view.alpha = state.isDictating ? 1 : 0
        }
        fieldLeading.constant = state.isDictating ? 0 : Spacing.s
    }

    func update(_ new: State) {
        let old = state
        state = new

        leadingHost.rootView = AnyView(new.leading.modifier(MiluEnvironment(store: store)))
        stopHost.rootView = AnyView(new.stop.modifier(MiluEnvironment(store: store)))
        actionHost.rootView = AnyView(new.action.modifier(MiluEnvironment(store: store)))
        overlayHost.rootView = AnyView(new.fieldOverlay.modifier(MiluEnvironment(store: store)))
        outHost.rootView = AnyView(new.outOfQuestions.modifier(MiluEnvironment(store: store)))
        greetingHost.rootView = AnyView(new.greeting.modifier(MiluEnvironment(store: store)))

        let barChanged = old?.showsLeading != new.showsLeading || old?.isDictating != new.isDictating
            || old?.isOutOfQuestions != new.isOutOfQuestions
        if barChanged {
            if old != nil, view.window != nil, !UIAccessibility.isReduceMotionEnabled {
                // On the next turn of the run loop, once SwiftUI is done with this update: laid
                // out from inside it, the bar's SwiftUI buttons were drawn mid-update and SwiftUI
                // logged an AttributeGraph cycle at every mic tap (lldb, 2026-11-11).
                DispatchQueue.main.async { self.animateBar() }
            } else {
                applyBar(new)
            }
        }

        // Words changed outside the field (sent, dictated); never mid-word while a Vietnamese
        // keyboard is still composing a letter.
        // A question just sent from the field: where its words were, for them to fly up from,
        // read before the field is cleared below.
        if let last = new.conversation.messages.last, last.role == .user,
           old?.conversation.id == new.conversation.id,
           old?.conversation.messages.contains(where: { $0.id == last.id }) == false {
            flightStart = textView.convert(
                CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top), to: view)
        }

        if textView.text != new.draft, textView.markedTextRange == nil {
            textView.text = new.draft
            textDidChange(animated: true)
            view.layoutIfNeeded()
        }

        if old?.conversation != new.conversation || old?.isThinking != new.isThinking {
            showMessages(of: new.conversation, thinking: new.isThinking)
        }
    }

    private func showMessages(of conversation: Conversation, thinking: Bool, slidesAway: Bool = true) {
        // Sliding away: its end shows the chat as it is by then.
        guard !isLeaving else { return }
        let sameChat = shownConversation?.id == conversation.id
        // ✎ a new chat: the one on screen slides up and fades first, then the greeting comes.
        if slidesAway, !sameChat, conversation.messages.isEmpty, shownConversation?.messages.isEmpty == false,
           view.window != nil, !UIAccessibility.isReduceMotionEnabled {
            slideAway()
            return
        }
        let previous = messagesByID
        messagesByID = Dictionary(uniqueKeysWithValues: conversation.messages.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        snapshot.appendSections([0])
        if !conversation.messages.isEmpty {
            snapshot.appendItems([.date] + conversation.messages.map { .message($0.id) })
            if thinking { snapshot.appendItems([.typing]) }
        }
        // A card that changed (deleted, cancelled) is drawn again in place.
        let changed = conversation.messages.filter { previous[$0.id] != nil && previous[$0.id] != $0 }
        snapshot.reconfigureItems(changed.map { .message($0.id) })

        let grew = sameChat && (conversation.messages.count > (shownConversation?.messages.count ?? 0) || thinking != shownThinking)
        // A question just sent from this page (not one that came with a chat from the history).
        let asked = sameChat ? conversation.messages.last.flatMap { $0.role == .user && previous[$0.id] == nil ? $0.id : nil } : nil
        // Milu's answer just in: the three dots go at once and the words show from the top down
        // in their place (no cross-fade of the two).
        let answered = sameChat ? conversation.messages.last.flatMap { $0.role == .assistant && previous[$0.id] == nil ? $0.id : nil } : nil
        shownConversation = conversation
        shownThinking = thinking

        // A question about to fly: its row is hidden from the moment it is in the list, or it
        // showed for a frame before its flyer took over (frames, 2026-11-11).
        if let asked, flightStart != nil, view.window != nil, !UIAccessibility.isReduceMotionEnabled {
            removeFlyer()
            flyingID = asked
        }
        // The answer in: the three dots, as they were, fade over its first lines as they show.
        let dots = answered != nil ? typingSnapshot() : nil
        dataSource.apply(snapshot, animatingDifferences: sameChat && view.window != nil && answered == nil)
        if !sameChat {
            // Another chat (the history, a new one): opened at its end, nothing pinned.
            endFlight()
            stopFollowing()
            pinnedID = nil
            pinRests = false
            holdsToEnd = true
            collectionView.layoutIfNeeded()
            updateInsets()
            scrollToEnd(animated: false)
        } else if let asked {
            stopFollowing()
            pinnedID = asked
            // Held only once the scroll is under way: held from here, the chat's new size snapped
            // it to the spot at once and the scroll had nowhere left to go (log, 2026-11-11).
            pinRests = false
            holdsToEnd = false
            collectionView.layoutIfNeeded()
            updateInsets(keepingEnd: false)
            if let offset = pinnedOffset {
                // The scroll first: adding the flyer lays the page out, and a pin held before
                // the scroll began snapped the chat to its spot at once (frames, 2026-11-11).
                scroll(to: offset, animated: true)
                pinRests = true
                if let start = flightStart {
                    // Built on the next turn of the run loop, once the scroll is under way:
                    // built in this one, the page laid out and the scroll ran at once.
                    DispatchQueue.main.async { self.fly(asked, from: start, landingAt: offset) }
                }
            } else {
                // No spot to fly to: the row shows as it is.
                endFlight()
            }
            flightStart = nil
        } else if grew, pinnedID == nil {
            holdsToEnd = true
            collectionView.layoutIfNeeded()
            scrollToEnd(animated: true)
        }
        if let answered {
            collectionView.layoutIfNeeded()
            reveal(answered)
        }
        if let dots { fadeOut(dots) }
        showGreeting(conversation.messages.isEmpty, animated: view.window != nil)
        updateDownButton()
    }

    // MARK: Effects (step 4 of the UIKit chat, user request 2026-11-11)

    private var isLeaving = false

    /// ✎: the chat goes up and fades on the second half of the way, so it reads as slid away,
    /// not blinked out (user request 2026-11-11, as the SwiftUI page did); then the new chat.
    private func slideAway() {
        isLeaving = true
        let duration = 0.28
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn]) {
            self.collectionView.transform = CGAffineTransform(translationX: 0, y: -Spacing.section * 2)
        }
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.calculationModeLinear]) {
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                self.collectionView.alpha = 0
            }
        } completion: { _ in
            self.collectionView.transform = .identity
            self.isLeaving = false
            if let state = self.state {
                self.showMessages(of: state.conversation, thinking: state.isThinking, slidesAway: false)
            }
        }
    }

    /// The three dots' row as it is on screen, laid over the list where it is: the row itself
    /// goes with the answer's coming, the picture of it fades (`fadeOut`).
    private func typingSnapshot() -> UIView? {
        guard view.window != nil, let indexPath = dataSource.indexPath(for: .typing),
              let cell = collectionView.cellForItem(at: indexPath),
              let picture = cell.contentView.snapshotView(afterScreenUpdates: false) else { return nil }
        picture.frame = cell.frame
        picture.isUserInteractionEnabled = false
        collectionView.addSubview(picture)
        return picture
    }

    /// The three dots going, over the answer's bubble growing in their place (user request
    /// 2026-11-11: they went at once, a blink before the words came).
    private func fadeOut(_ picture: UIView) {
        guard !UIAccessibility.isReduceMotionEnabled else {
            picture.removeFromSuperview()
            return
        }
        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            picture.alpha = 0
        } completion: { _ in
            picture.removeFromSuperview()
        }
    }

    /// Milu's words show from the top down, under a soft edge, as if written (the avatar and
    /// the name are there at once, where the three dots were). Under Reduce Motion, a short fade.
    private func reveal(_ id: UUID) {
        guard view.window != nil, let indexPath = dataSource.indexPath(for: .message(id)),
              let cell = collectionView.cellForItem(at: indexPath) else { return }
        let content = cell.contentView
        guard !UIAccessibility.isReduceMotionEnabled else {
            content.alpha = 0
            UIView.animate(withDuration: 0.2) { content.alpha = 1 }
            return
        }
        let height = content.bounds.height, width = content.bounds.width
        let edge: CGFloat = 48
        let sender = IconSize.rowArtwork + Spacing.s
        let span = height + edge
        let mask = CAGradientLayer()
        mask.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        mask.locations = [0, NSNumber(value: Double(height / span)), 1]
        mask.bounds = CGRect(x: 0, y: 0, width: width, height: span)
        // From: shown down to the name, the soft edge under it. To: all shown.
        let from = CGPoint(x: width / 2, y: sender + edge - span / 2)
        let to = CGPoint(x: width / 2, y: span / 2)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.position = to
        content.layer.mask = mask
        CATransaction.commit()

        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = NSValue(cgPoint: from)
        animation.toValue = NSValue(cgPoint: to)
        // Longer answers take a little longer, never long.
        animation.duration = min(0.9, 0.35 + Double(height) * 0.0012)
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak content] in
            if content?.layer.mask === mask { content?.layer.mask = nil }
        }
        mask.add(animation, forKey: "reveal")
        CATransaction.commit()
        follow(id, mask: mask, rowHeight: height, span: span)
    }

    // MARK: Following the words

    /// The answer being written, followed down: the page rises with its newest line once that
    /// line would pass under the field (user request 2026-11-11), the question pinned at the
    /// head going up with it only then. A touch on the chat lets it go at once.
    private struct Follow {
        let id: UUID
        let mask: CAGradientLayer
        let rowHeight: CGFloat
        let span: CGFloat
        let link: CADisplayLink
    }

    private var following: Follow?

    private func follow(_ id: UUID, mask: CAGradientLayer, rowHeight: CGFloat, span: CGFloat) {
        stopFollowing()
        let link = CADisplayLink(target: self, selector: #selector(followTick))
        link.add(to: .main, forMode: .common)
        following = Follow(id: id, mask: mask, rowHeight: rowHeight, span: span, link: link)
    }

    /// Each frame: where the words are shown down to, and the page brought up to keep that line
    /// over the field, never down, never past the chat's end.
    @objc private func followTick() {
        guard let follow = following, !collectionView.isTracking, !collectionView.isDecelerating,
              let indexPath = dataSource.indexPath(for: .message(follow.id)),
              let row = collectionView.layoutAttributesForItem(at: indexPath)?.frame else {
            stopFollowing()
            return
        }
        let writing = follow.mask.animation(forKey: "reveal") != nil
        let mask = follow.mask.presentation() ?? follow.mask
        let shownTo = writing ? min(mask.position.y - follow.span / 2 + follow.rowHeight, follow.rowHeight) : follow.rowHeight
        let visible = collectionView.bounds.height - barRoom
        let inset = collectionView.contentInset
        let end = collectionView.contentSize.height + inset.bottom - collectionView.bounds.height
        let target = min(row.minY + shownTo + Spacing.l - visible, end)
        if target > collectionView.contentOffset.y + 0.5 {
            // Past the question's spot: the pin lets go, or it pulled the page back.
            pinRests = false
            collectionView.contentOffset.y = target
        }
        if !writing { stopFollowing() }
    }

    private func stopFollowing() {
        following?.link.invalidate()
        following = nil
        updateDownButton()
    }

    /// The greeting while the chat is empty. It goes up and fades as the first question flies
    /// (user request 2026-11-11: it blinked out), and comes up a little into its place for a new
    /// chat.
    private func showGreeting(_ shows: Bool, animated: Bool) {
        let greeting = greetingHost.view!
        let shown = greeting.alpha > 0.5
        let change = {
            greeting.alpha = shows ? 1 : 0
            self.collectionView.alpha = shows ? 0 : 1
        }
        guard animated, shown != shows, !UIAccessibility.isReduceMotionEnabled else {
            greeting.layer.removeAllAnimations()
            greeting.transform = .identity
            change()
            return
        }
        if shows {
            greeting.transform = CGAffineTransform(translationX: 0, y: Spacing.xl)
            UIView.animate(springDuration: 0.45, bounce: 0, options: [.beginFromCurrentState]) {
                greeting.transform = .identity
                change()
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
                greeting.transform = CGAffineTransform(translationX: 0, y: -Spacing.section)
                    .scaledBy(x: 0.96, y: 0.96)
                greeting.alpha = 0
            } completion: { _ in
                if greeting.alpha == 0 { greeting.transform = .identity }
            }
            // The chat comes in under the question's flight, a beat after the greeting starts.
            UIView.animate(withDuration: 0.25, delay: 0.08, options: [.curveEaseOut, .beginFromCurrentState]) {
                self.collectionView.alpha = 1
            }
        }
    }

    // MARK: Scrolling

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if textView.bounds.width != measuredWidth {
            measuredWidth = textView.bounds.width
            textDidChange()
        }
        updateInsets()
    }

    // MARK: The question at the head

    /// The question just sent. It rises to the page's head, to the spot the first question of a
    /// chat has under its date, so every question rests in one place (user request 2026-11-09,
    /// as Claude and ChatGPT do); Milu's answer comes in under it. Room is made below the chat
    /// for it to get there, and the room goes as the answer fills it (step 3 of the UIKit chat,
    /// user request 2026-11-11).
    private var pinnedID: UUID?
    /// The pinned question is held at its spot, as rows find their heights (iOS pulls the chat
    /// down when one comes out shorter than its estimate) and the keyboard comes and goes, until
    /// the reader scrolls.
    private var pinRests = false

    /// From the page's head to a question at rest: the chat's top margin, its date and the gap
    /// under it.
    private var restGap: CGFloat {
        let size = traitCollection.preferredContentSizeCategory
        if let cached = measuredRestGap, cached.size == size { return cached.gap }
        let chip = UIHostingController(rootView: ChatDateChip(date: .now).modifier(MiluEnvironment(store: store)))
        let width = max(view.bounds.width - 2 * Spacing.l, 1)
        let gap = Spacing.l + chip.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height + Spacing.xl
        measuredRestGap = (size, gap)
        return gap
    }

    private var measuredRestGap: (size: UIContentSizeCategory, gap: CGFloat)?

    /// The scroll offset that rests the pinned question at its spot.
    private var pinnedOffset: CGFloat? {
        guard let id = pinnedID,
              let indexPath = dataSource.indexPath(for: .message(id)),
              let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else { return nil }
        return frame.minY - restGap - view.safeAreaInsets.top
    }

    /// The chat's room at the head (the top bar's) and at the foot: the field's, or more while a
    /// question is pinned and what is under it is shorter than the page.
    /// `keepingEnd`: a chat at its end stays there as the room changes (the keyboard).
    private func updateInsets(keepingEnd: Bool = true) {
        // A message's hold menu is up: the chat stays as it is under it (`menuHoldsChat`).
        guard !menuHoldsChat else { return }
        let barRoom = max(0, view.bounds.maxY - bar.frame.minY)
        self.barRoom = barRoom
        var bottom = barRoom
        if let offset = pinnedOffset {
            bottom = max(barRoom, offset + collectionView.bounds.height - collectionView.contentSize.height)
        }
        let insets = UIEdgeInsets(top: view.safeAreaInsets.top, left: 0, bottom: bottom, right: 0)
        // Set only on a real change: one set on every scroll frame, for a rounding difference,
        // fought the reader's finger.
        let current = collectionView.contentInset
        guard abs(current.top - insets.top) > 0.5 || abs(current.bottom - insets.bottom) > 0.5 else { return }
        let keepsEnd = keepingEnd && (holdsToEnd || isAtEnd)
        collectionView.contentInset = insets
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: insets.top, left: 0, bottom: barRoom, right: 0)
        if pinRests {
            holdPin()
        } else if keepsEnd, !collectionView.isTracking, !isAnimatingScroll {
            scrollToEnd(animated: false)
        }
    }

    /// Back to the pinned question's spot, if something moved the chat off it.
    private func holdPin() {
        guard pinRests, !menuHoldsChat, !collectionView.isTracking, !isAnimatingScroll, let offset = pinnedOffset else { return }
        let point = CGPoint(x: 0, y: max(-collectionView.contentInset.top, offset))
        if abs(collectionView.contentOffset.y - point.y) > 0.5 { collectionView.contentOffset = point }
    }

    // MARK: Scrolling

    /// A row found its height: the room under a pinned question is measured again, and a chat
    /// settling at its end goes back there.
    private func contentSizeChanged() {
        guard !menuHoldsChat else { return }
        updateInsets()
        holdPin()
        updateDownButton()
        guard holdsToEnd, !collectionView.isTracking, !isAnimatingScroll else { return }
        scrollToEnd(animated: false)
    }

    /// Within a few points of the chat's last line.
    private var isAtEnd: Bool {
        let inset = collectionView.contentInset
        let visibleBottom = collectionView.contentOffset.y + collectionView.bounds.height - inset.bottom
        return visibleBottom >= collectionView.contentSize.height - 24
    }

    /// To the last line, over the field; a chat shorter than the page stays at its top.
    private func scrollToEnd(animated: Bool, bounce: CGFloat = 0.15) {
        let inset = collectionView.contentInset
        scroll(to: collectionView.contentSize.height + inset.bottom - collectionView.bounds.height,
               animated: animated, bounce: bounce)
    }

    /// Scrolls to `offset` (kept within the chat). Animated, on a soft spring: the 0.36 s, bounce
    /// 0.15 measured from Claude's own question rising (2026-11-10).
    private func scroll(to offset: CGFloat, animated: Bool, bounce: CGFloat = 0.15) {
        let point = CGPoint(x: 0, y: max(-collectionView.contentInset.top, offset))
        guard animated, view.window != nil, !UIAccessibility.isReduceMotionEnabled else {
            collectionView.contentOffset = point
            return
        }
        isAnimatingScroll = true
        UIView.animate(springDuration: 0.36, bounce: bounce, initialSpringVelocity: 0, delay: 0,
                       options: [.allowUserInteraction]) {
            self.collectionView.contentOffset = point
        } completion: { _ in
            self.isAnimatingScroll = false
            self.updateDownButton()
            self.holdPin()
            // The rows that came in may have grown past their estimate on the way.
            // Settled the rest of the way with no overshoot, so it never bobs.
            if self.holdsToEnd, !self.collectionView.isTracking, !self.isAtEnd {
                self.scrollToEnd(animated: true, bounce: 0)
            }
        }
    }

    private var isAnimatingScroll = false
    /// The field's room at the foot of the page, as `updateInsets` last measured it.
    private var barRoom: CGFloat = 0

    // MARK: Jump to the end

    /// ↓ in the middle over the field, once the chat's end is out of sight (as the AI apps have
    /// it, user request 2026-11-11): it fades and grows in, and takes the chat to its end.
    private let downGlass = UIVisualEffectView(effect: ChatViewController.glassEffect())
    private var downShown = false
    private static let downSize: CGFloat = 40
    /// How far below the visible end the chat's end must be before ↓ shows.
    private static let downDistance: CGFloat = 120

    private func buildDownButton() {
        downGlass.layer.cornerRadius = Self.downSize / 2
        downGlass.layer.cornerCurve = .continuous
        downGlass.clipsToBounds = true
        downGlass.alpha = 0
        downGlass.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        downGlass.isUserInteractionEnabled = false
        downGlass.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        let symbol = UIImage.SymbolConfiguration(pointSize: IconSize.inline + 2, weight: .semibold)
        button.setImage(UIImage(systemName: "arrow.down", withConfiguration: symbol), for: .normal)
        button.tintColor = Palette.uiLabel
        button.accessibilityLabel = "Xuống tin mới nhất"
        button.addTarget(self, action: #selector(jumpToEnd), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        downGlass.contentView.addSubview(button)

        view.addSubview(downGlass)
        NSLayoutConstraint.activate([
            downGlass.widthAnchor.constraint(equalToConstant: Self.downSize),
            downGlass.heightAnchor.constraint(equalToConstant: Self.downSize),
            downGlass.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Close over the field, as ChatGPT has it (user choice 2026-11-11).
            downGlass.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -Spacing.s + 2),
            button.topAnchor.constraint(equalTo: downGlass.contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: downGlass.contentView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: downGlass.contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: downGlass.contentView.trailingAnchor),
        ])
    }

    /// Shows ↓ while the chat's end is well below what is on screen, hides it near the end.
    private func updateDownButton() {
        let inset = collectionView.contentInset
        let below = collectionView.contentSize.height + inset.bottom
            - (collectionView.contentOffset.y + collectionView.bounds.height)
        // Not while the chat is being taken somewhere (a question rising to its spot): its end
        // is out of sight only on the way, and ↓ flashed up for a moment (frames, 2026-11-11).
        let shows = state?.conversation.messages.isEmpty == false && !isLeaving && !isAnimatingScroll
            && flyingID == nil && following == nil && below > Self.downDistance
        guard shows != downShown else { return }
        downShown = shows
        downGlass.isUserInteractionEnabled = shows
        let change = {
            self.downGlass.alpha = shows ? 1 : 0
            self.downGlass.transform = shows ? .identity : CGAffineTransform(scaleX: 0.6, y: 0.6)
        }
        if view.window != nil, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(springDuration: 0.25, bounce: 0, initialSpringVelocity: 0, delay: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: change)
        } else {
            change()
        }
    }

    /// ↓: to the chat's end in one smooth glide that stops there, no overshoot (user report
    /// 2026-11-11: it went down, up a little, down again, and bobbed when tapped mid-swipe).
    @objc private func jumpToEnd() {
        Haptics.selection()
        // The swipe's own glide stopped first, or it and this scroll pulled against each other.
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
        holdsToEnd = true
        pinRests = false
        // From far up (more than two pages), first to a page above the end, so the rows there
        // find their heights before the glide: found on the way, they moved the end and the
        // glide went again. Nearer, one glide all the way.
        let inset = collectionView.contentInset
        let end = collectionView.contentSize.height + inset.bottom - collectionView.bounds.height
        if end - collectionView.contentOffset.y > collectionView.bounds.height * 2 {
            collectionView.contentOffset.y = end - collectionView.bounds.height
            collectionView.layoutIfNeeded()
        }
        scrollToEnd(animated: true, bounce: 0)
    }

    // MARK: The question's flight

    /// Where the words of the question just sent sat in the field (`update`).
    private var flightStart: CGPoint?
    /// The question in flight: its row is hidden until the flyer lands on it.
    private var flyingID: UUID?
    private var flyer: UIViewController?

    /// The question's bubble rises from the field to its row as the chat brings the row up to its
    /// spot: from where its words were typed, on the scroll's own spring (Claude's, measured
    /// 2026-11-10: 0.36 s, bounce 0.15, a beat after the tap), fading in as it leaves the field.
    /// The row shows in its place as it lands.
    private func fly(_ id: UUID, from start: CGPoint, landingAt offset: CGFloat) {
        removeFlyer()
        guard flyingID == id, view.window != nil, !UIAccessibility.isReduceMotionEnabled,
              let message = messagesByID[id], let indexPath = dataSource.indexPath(for: .message(id)),
              let row = collectionView.layoutAttributesForItem(at: indexPath)?.frame else {
            endFlight()
            return
        }
        let host = UIHostingController(rootView: AnyView(UserBubble(text: message.text)
            .modifier(MiluEnvironment(store: store))
            .environment(\.questionWordsWidth, questionWordsWidth)))
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        let rowWidth = collectionView.bounds.width - 2 * Spacing.l
        let size = host.sizeThatFits(in: CGSize(width: rowWidth, height: .greatestFiniteMagnitude))
        let landing = CGRect(x: collectionView.bounds.width - Spacing.l - size.width,
                             y: row.minY - max(-collectionView.contentInset.top, offset),
                             width: size.width, height: size.height)
        let from = CGPoint(x: start.x - Bubble.userInset.leading, y: start.y - Bubble.userInset.top)

        addChild(host)
        host.view.frame = landing
        host.view.transform = CGAffineTransform(translationX: from.x - landing.minX, y: from.y - landing.minY)
        host.view.alpha = 0
        view.insertSubview(host.view, belowSubview: bar)
        host.didMove(toParent: self)
        flyer = host
        flyingID = id
        collectionView.cellForItem(at: indexPath)?.contentView.alpha = 0

        UIView.animate(withDuration: 0.15, delay: 0.05, options: [.curveEaseOut]) {
            host.view.alpha = 1
        }
        UIView.animate(springDuration: 0.36, bounce: 0.15, initialSpringVelocity: 0, delay: 0.05,
                       options: [.allowUserInteraction]) {
            host.view.transform = .identity
        } completion: { _ in
            if self.flyer === host { self.endFlight() }
        }
    }

    /// The animated scroll stopped at the offset on screen: left running, the reader's drag
    /// started from where it was headed, and the chat jumped there under the finger.
    private func stopScrollAnimation() {
        guard isAnimatingScroll else { return }
        let shown = collectionView.layer.presentation()?.bounds.origin ?? collectionView.contentOffset
        collectionView.layer.removeAllAnimations()
        collectionView.contentOffset = shown
        isAnimatingScroll = false
    }

    /// The question's flyer, frozen where it is, fades as its row fades in under it.
    private func landFlightSoftly() {
        guard let host = flyer else {
            endFlight()
            return
        }
        // Taken off first, so the stopped animation's completion does not end it again.
        flyer = nil
        let presented = host.view.layer.presentation()
        host.view.layer.removeAllAnimations()
        host.view.transform = presented?.affineTransform() ?? host.view.transform
        host.view.alpha = CGFloat(presented?.opacity ?? 1)
        let row = flyingID.flatMap { dataSource.indexPath(for: .message($0)) }.flatMap(collectionView.cellForItem(at:))
        flyingID = nil
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            host.view.alpha = 0
            row?.contentView.alpha = 1
        } completion: { _ in
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
        }
        updateDownButton()
    }

    /// The flyer away and the question's own row shown.
    private func endFlight() {
        if let id = flyingID, let indexPath = dataSource.indexPath(for: .message(id)) {
            collectionView.cellForItem(at: indexPath)?.contentView.alpha = 1
        }
        flyingID = nil
        removeFlyer()
        updateDownButton()
    }

    private func removeFlyer() {
        flyer?.willMove(toParent: nil)
        flyer?.view.removeFromSuperview()
        flyer?.removeFromParent()
        flyer = nil
    }

    // MARK: The field

    private var keyboardTaps: [UITapGestureRecognizer] = []

    @objc private func putKeyboardAway() {
        textView.resignFirstResponder()
    }

    @objc private func focusField() {
        Haptics.prepare()
        guard state?.isDictating != true else { return }
        textView.becomeFirstResponder()
    }

    /// The field grows with its lines up to five, then scrolls inside. `animated`: the box opens
    /// or closes over iOS's own keyboard-like curve, the chat above moving with it.
    private func textDidChange(animated: Bool = false) {
        placeholder.isHidden = !textView.text.isEmpty
        let width = textView.bounds.width
        guard width > 0 else { return }
        let fits = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        let inset = textView.textContainerInset
        let most = font.lineHeight * Self.maxLines + inset.top + inset.bottom
        let height = min(max(fits, Self.buttonSize), most)
        textView.isScrollEnabled = fits > most
        guard boxHeight.constant != height else { return }

        // The words take their new height at once, on the box's foot: the new line shows where
        // the caret was, the lines before it above, hidden until the box opens over them.
        let grows = height > boxHeight.constant
        textOnTop.isActive = false
        textOnFoot.isActive = false
        (grows ? textOnFoot : textOnTop).isActive = true
        textHeight.constant = height
        UIView.performWithoutAnimation { fieldBox.layoutIfNeeded() }
        boxHeight.constant = height
        guard animated, view.window != nil, !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: Self.resizeDuration, delay: 0, usingSpringWithDamping: 1,
                       initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.view.layoutIfNeeded()
        }
    }

    private static let resizeDuration: TimeInterval = 0.25
}

extension ChatViewController: UITextViewDelegate {
    /// The keyboard coming: the field's buttons are about to be used.
    func textViewDidBeginEditing(_ textView: UITextView) {
        Haptics.prepare()
    }

    /// No typing into the hidden field while listening.
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        state?.isDictating != true
    }

    func textViewDidChange(_ textView: UITextView) {
        textDidChange(animated: true)
        view.layoutIfNeeded()
        onDraftChange(textView.text)
    }
}

extension ChatViewController: UICollectionViewDelegate {
    /// The reader's own scroll wins over holding to the end.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDownButton()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // The reader took the chat mid-rise (user report 2026-11-12: a swipe as the question
        // rose jumped): the rising scroll stops where it is on screen, not at where it was
        // going, and the question's flyer hands over to its row with a short fade instead of
        // vanishing.
        stopScrollAnimation()
        landFlightSoftly()
        stopFollowing()
        holdsToEnd = false
        pinRests = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { holdsToEnd = isAtEnd }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        holdsToEnd = isAtEnd
    }
}

// MARK: Hold to copy

/// Holding a question's bubble: "Sao chép" (user request 2026-11-11), as in Messages. Milu's
/// answers have no menu: their words are selected, as in ChatGPT and Claude (`AnswerWords`). A menu of
/// the page's own on the list, not SwiftUI's `.contextMenu` in the row (it warns
/// "_UIReparentingView … not supported" inside a UIKit list) nor the list's cell menu (on
/// closing, it drew a copy of the row sliding in from the side, user report 2026-11-11).
extension ChatViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = collectionView.indexPathForItem(at: location),
              case .message(let id)? = dataSource.itemIdentifier(for: indexPath),
              let message = messagesByID[id], message.role == .user,
              let cell = collectionView.cellForItem(at: indexPath),
              let bubble = bubbleRect(id, in: cell),
              bubble.contains(collectionView.convert(location, to: cell.contentView)) else { return nil }
        let text = MessageRow.copiedText(of: message)
        return UIContextMenuConfiguration(identifier: id as NSUUID, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Sao chép", image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = text
                    Haptics.success()
                },
            ])
        }
    }

    /// A still picture of the bubble, laid over it in its row the moment the hold begins (the
    /// row hidden under it, the two alike): iOS lifts the picture, hides it while it is up and
    /// puts it back where it was, as Messages does. Lifted, the row's own SwiftUI came back laid
    /// out mid-row for a moment; a picture lifted from nowhere and the row hidden by hand left a
    /// second bubble under the one moved, or none once the menu was gone (user reports
    /// 2026-11-11 and 2026-11-12).
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configuration: UIContextMenuConfiguration,
                                highlightPreviewForItemWithIdentifier identifier: any NSCopying) -> UITargetedPreview? {
        guard let id = (identifier as? NSUUID).map({ $0 as UUID }) else { return nil }
        // A picture of its own for each hold; within one hold, the same. A hold soon after the
        // last took that one's picture, which the last then took away: the bubble did not lift
        // (user report 2026-11-12).
        if heldBubble?.id != id || heldBubble?.ending == true { coverBubble(id) }
        return heldPreview()
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configuration: UIContextMenuConfiguration,
                                dismissalPreviewForItemWithIdentifier identifier: any NSCopying) -> UITargetedPreview? {
        heldPreview()
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                animator: (any UIContextMenuInteractionAnimating)?) {
        menuHoldsChat = true
    }

    /// The menu gone: the chat takes the room the bar has by then, softly if it changed (the
    /// keyboard stayed down).
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration,
                                animator: (any UIContextMenuInteractionAnimating)?) {
        heldBubble?.ending = true
        let held = heldBubble?.picture
        // In case iOS never says it is done: the picture is the bubble's twin, so taking it away
        // a moment later shows nothing. Each takes away its own hold's picture only.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            if let self, self.heldBubble?.picture === held { self.uncoverBubble() }
        }
        let release = { [weak self] in
            guard let self else { return }
            if self.heldBubble?.picture === held { self.uncoverBubble() }
            guard self.menuHoldsChat else { return }
            self.menuHoldsChat = false
            self.view.layoutIfNeeded()
            if UIAccessibility.isReduceMotionEnabled {
                self.updateInsets()
            } else {
                UIView.animate(springDuration: 0.36, bounce: 0) { self.updateInsets() }
            }
            self.updateDownButton()
        }
        if let animator {
            animator.addCompletion(release)
        } else {
            release()
        }
    }

    /// The picture laid over the held question's bubble, its row hidden under it.
    private func coverBubble(_ id: UUID) {
        // The same bubble held again while the last hold's picture is still up (the row under it
        // hidden, drawn as nothing): its picture is drawn again from that one.
        let lastImage = heldBubble?.id == id ? heldBubble?.picture.image : nil
        uncoverBubble()
        guard let indexPath = dataSource.indexPath(for: .message(id)),
              let cell = collectionView.cellForItem(at: indexPath),
              let bubble = bubbleRect(id, in: cell) else { return }
        let row = cell.contentView
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        let image = lastImage ?? UIGraphicsImageRenderer(size: bubble.size, format: format).image { _ in
            row.drawHierarchy(in: CGRect(origin: CGPoint(x: -bubble.minX, y: -bubble.minY), size: row.bounds.size),
                              afterScreenUpdates: false)
        }
        let picture = UIImageView(image: image)
        picture.frame = row.convert(bubble, to: cell)
        cell.addSubview(picture)
        row.alpha = 0
        heldBubble = (id, picture, row, false)
        // A hold let go before its menu came: no menu ends it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if let self, !self.menuHoldsChat, self.heldBubble?.picture === picture { self.uncoverBubble() }
        }
    }

    /// The picture taken away and the row shown again.
    private func uncoverBubble() {
        guard let held = heldBubble else { return }
        heldBubble = nil
        held.row.alpha = 1
        held.picture.removeFromSuperview()
    }

    /// The picture, in the bubble's shape, where it lies.
    private func heldPreview() -> UITargetedPreview? {
        guard let picture = heldBubble?.picture, picture.window != nil else { return nil }
        let parameters = UIPreviewParameters()
        parameters.visiblePath = UIBezierPath(cgPath: Bubble.userShape.path(in: picture.bounds).cgPath)
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: picture, parameters: parameters)
    }

    /// A message's bubble's centre in the list.
    private func bubbleCenter(_ id: UUID) -> CGPoint? {
        guard let indexPath = dataSource.indexPath(for: .message(id)),
              let cell = collectionView.cellForItem(at: indexPath),
              let bubble = bubbleRect(id, in: cell) else { return nil }
        return collectionView.convert(CGPoint(x: bubble.midX, y: bubble.midY), from: cell.contentView)
    }

    /// A message's bubble in its cell's content view: the row's content starts inside the row's
    /// side margins.
    private func bubbleRect(_ id: UUID, in cell: UICollectionViewCell) -> CGRect? {
        guard let frame = bubbleFrames[id], frame.width > 0 else { return nil }
        return frame.offsetBy(dx: Spacing.l, dy: 0)
    }
}

extension ChatViewController: UIGestureRecognizerDelegate {
    /// The field's tap: not over the buttons, they take their own taps. The page's: only while
    /// the keyboard is up.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if keyboardTaps.contains(where: { $0 === gestureRecognizer }) { return textView.isFirstResponder }
        guard let view = touch.view else { return true }
        return ![leadingHost.view, stopHost.view, actionHost.view].contains { view.isDescendant(of: $0!) }
    }

    /// The page's tap never stands in another touch's way (a hold to copy, a card's button).
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        keyboardTaps.contains { $0 === gestureRecognizer }
    }
}

/// What every Milu view reads from the app: hosted in UIKit, a SwiftUI view does not inherit it.
private struct MiluEnvironment: ViewModifier {
    let store: FinanceStore

    func body(content: Content) -> some View {
        content
            .font(TextRole.body.font)
            .foregroundStyle(Palette.label)
            .scrollIndicators(.hidden, axes: .vertical)
            .environment(store)
            .environment(\.locale, .vietnam)
    }
}

/// The chat's list, with no safe area of its own: it runs under the top bar, the field and the
/// keyboard, and sets its room for them by hand (`updateInsets`). With one, each row passing under
/// a bar took that bar's height as padding and grew as it went (the date 27 → 143pt under the
/// top bar, logged 2026-11-11), so the chat swam under the finger.
private final class ChatList: UICollectionView {
    override var safeAreaInsets: UIEdgeInsets { .zero }
}

