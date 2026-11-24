import SwiftUI
import UIKit

/// "Thêm bằng AI" in iOS's sheet, built with UIKit (user request 2026-11-20: SwiftUI could not
/// move the sheet, the field and what is over it as one; "sửa mãi mà vẫn chưa đúng ý").
/// `QuickRecordSheet` keeps the steps, Milu and the words; this lays them out:
///
/// - the field, the chat's own (`ChatViewController.buildBar`): the words in a `UITextView`
///   growing a line at a time up to four, ✕ and ■ coming in while one speaks, the wave or the
///   voice turning into words in the words' place, the field lit up while Milu works;
/// - over it, what `QuickRecordSheet` gives (`QuickSheetState.upper`, SwiftUI), scrolling when
///   it is longer than the screen;
/// - the sheet's height, theirs together, changed in the same animation as what is in it
///   (`fitSheet`), so nothing in the sheet waits for the sheet nor the sheet for it;
/// - a sentence sent rising from the field into its bubble as the chat's question does
///   (`fly`), what was over the field before going as it leaves.
///
/// Put up by UIKit (`present`), the root of its sheet in a navigation controller for its bar:
/// put up by SwiftUI, the sheet took the height this page set, but SwiftUI went on laying the
/// page out at the last height it knew (log 2026-11-20: the sheet 372, this page 242, the field
/// half-way up). `QuickRecordSheet` runs unseen in it (`logic`) and sends it each step
/// (`QuickSheetBridge`).
final class QuickRecordController: UIViewController {
    var onDraftChange: (String) -> Void = { _ in }
    var onSend: () -> Void = {}
    var onFocus: (Bool) -> Void = { _ in }
    var onTapField: () -> Void = {}

    private let store: FinanceStore
    private var state: QuickSheetState?
    /// The steps, Milu and the words (`QuickRecordSheet`), unseen.
    private var logic: UIHostingController<AnyView>?
    private let link = QuickPageLink()

    // MARK: Parts

    /// What is over the field.
    private let scroll = UIScrollView()
    private let upperHost = UIHostingController(rootView: AnyView(EmptyView()))
    /// The SwiftUI over the field as tall as it says it is (`QuickUpper.height`).
    private var upperHeight: CGFloat = 0
    private var upperHeightConstraint: NSLayoutConstraint!
    private var scrollToFoot: NSLayoutConstraint!
    /// The field's foot (or, with no field, what is over it): the sheet's height from its top,
    /// over the keyboard (iOS's keyboard guide).
    private let footLine = UILayoutGuide()
    private var footFromTop: NSLayoutConstraint!
    private var footOverKeyboard: NSLayoutConstraint!


    /// The field, in the chat's glass (`ChatViewController.glass`): what is over it runs on
    /// under it and shows through it (user request 2026-11-20: "liquid glass giống bên chat để nó
    /// không còn che nội dung").
    private let bar = UIVisualEffectView(effect: QuickRecordController.glassEffect())
    private let fieldRow = UIStackView()
    private let fieldBox = UIView()
    private let textView = UITextView()
    private let placeholder = UILabel()
    /// As the chat's (`ChatViewController.textHeight`): the words' height at once, the box's on
    /// the animation, the words on its foot as it grows and on its top as it shrinks.
    private var textHeight: NSLayoutConstraint!
    private var boxHeight: NSLayoutConstraint!
    private var textOnFoot: NSLayoutConstraint!
    private var textOnTop: NSLayoutConstraint!
    private var fieldLeading: NSLayoutConstraint!
    private var measuredWidth: CGFloat = 0

    private let leadingHost = QuickRecordController.host()
    private let stopHost = QuickRecordController.host()
    private let actionHost = QuickRecordController.host()
    /// Sized by the field, never by itself: the wave redraws every frame (`ChatViewController`).
    private let overlayHost = QuickRecordController.host(sizing: false)
    private let fieldLight = UIView()
    private let fieldRing = UIView()

    /// The sentence just sent: where its words were in the field, and the flyer on its way up.
    private var flightStart: CGPoint?
    private var flyer: UIViewController?
    /// Its bubble over the field hidden until the flyer is on it.
    private var saidHidden = false
    /// Where that bubble is in what is over the field (`QuickUpper.saidFrame`).
    private var saidFrame: CGRect?

    // MARK: Metrics

    private static let buttonSize = ControlHeight.small
    private static let inset = Spacing.s
    private static let radius = buttonSize / 2 + inset
    private static let maxLines: CGFloat = 4
    /// Over the field, and under it to the sheet's foot (or the keyboard).
    private static let gap = Spacing.l
    private static let foot = Spacing.l
    /// The bar's height before it is measured (iOS's inline bar in a sheet).
    private static let firstBar: CGFloat = 70
    /// What is over the field before it is measured: the greeting's two lines.
    private static let firstUpper: CGFloat = 47
    private static let detent = UISheetPresentationController.Detent.Identifier("milu.quickRecord")

    private lazy var font: UIFont = ChatWords.font()

    init(store: FinanceStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Building

    /// Up in iOS's sheet over `presenter`, with its bar; `onNext` once it has gone, as
    /// `QuickRecordSheet`'s, then `onDismiss`.
    @discardableResult
    static func present(over presenter: UIViewController, store: FinanceStore,
                        onNext: @escaping (QuickRecordNext) -> Void,
                        onDismiss: @escaping () -> Void) -> UIViewController {
        let page = QuickRecordController(store: store)
        page.onNext = onNext
        page.navigationItem.title = "Thêm bằng AI"
        let close = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak page] _ in page?.close() })
        // Milu's blue, as every other sheet's ✕ (`SheetCloseButton`): left alone it was black.
        close.tintColor = UIColor(Palette.primary)
        page.navigationItem.leftBarButtonItem = close
        let navigation = UINavigationController(rootViewController: page)
        // Surface/Card over iOS's glass, which still swells under a touch (`sheetGround`).
        navigation.view.backgroundColor = UIColor(Palette.surface)
        navigation.modalPresentationStyle = .pageSheet
        if let sheet = navigation.sheetPresentationController {
            sheet.detents = [.custom(identifier: detent) { [weak page] context in
                min(page?.detentHeight ?? firstHeight, context.maximumDetentValue)
            }]
            sheet.selectedDetentIdentifier = detent
            sheet.prefersGrabberVisible = false
            sheet.delegate = page
        }
        page.onGone = onDismiss
        page.fitted = firstHeight
        presenter.present(navigation, animated: true)
        return navigation
    }

    /// The sheet's height before anything is measured: its bar, the greeting and the field.
    private static let firstHeight: CGFloat = 209

    private var onNext: (QuickRecordNext) -> Void = { _ in }
    private var onGone: () -> Void = {}

    /// Away, by ✕, by "Lưu" a moment later, or by the step asking for a form or the chat.
    func close() {
        presented.dismiss(animated: true) { [weak self] in self?.gone() }
    }

    private var isGone = false

    private func gone() {
        guard !isGone else { return }
        isGone = true
        onGone()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        link.page = self
        buildUpper()
        buildBar()
        buildLogic()
        // The guide of the keyboard at the screen's foot alone (an iPad's undocked one aside):
        // following it, the field stood still as the sheet was pulled down.
        view.keyboardLayoutGuide.followsUndockedKeyboard = false
        // A tap over the field puts the keyboard away, every other touch going on as before.
        let tap = UITapGestureRecognizer(target: self, action: #selector(putKeyboardAway))
        tap.cancelsTouchesInView = false
        scroll.addGestureRecognizer(tap)
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardComes), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardGoes), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// In the keyboard's own animation, the sheet's height with it (`detentHeight`).
    @objc private func keyboardComes(_ note: Notification) { setKeyboard(up: true, note) }
    @objc private func keyboardGoes(_ note: Notification) { setKeyboard(up: false, note) }

    /// The sheet's height for the keyboard, and what is over the field scrolled for its room,
    /// on the keyboard's own curve: at once, the sheet stepped down by the home indicator's room
    /// before the keyboard rose, the field with it (iPhone 2026-11-20), and a card over the
    /// field stood scrolled to its foot before the sheet had begun to move.
    private func setKeyboard(up: Bool, _ note: Notification) {
        guard keyboardUp != up else { return }
        keyboardUp = up
        let info = note.userInfo
        let duration = (info?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curve = (info?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7
        keyboardMoves = CACurrentMediaTime() + duration
        // Kept over the keyboard while it is up; what is over the field scrolled for its room,
        // on the keyboard's own curve.
        footOverKeyboard.isActive = up
        UIView.animate(withDuration: duration, delay: 0,
                       options: [UIView.AnimationOptions(rawValue: curve << 16), .beginFromCurrentState,
                                 .allowUserInteraction]) {
            self.layoutSheet()
            self.keepFootInView(always: true)
        }

    }

    /// Until when the keyboard is on its way: no scrolling at once meanwhile (`setKeyboard`).
    private var keyboardMoves: CFTimeInterval = 0

    private func buildUpper() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = false
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.clipsToBounds = true
        view.addSubview(scroll)

        addChild(upperHost)
        upperHost.view.backgroundColor = .clear
        upperHost.safeAreaRegions = []
        upperHost.sizingOptions = []
        upperHost.view.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(upperHost.view)
        upperHost.didMove(toParent: self)

        upperHeightConstraint = upperHost.view.heightAnchor.constraint(equalToConstant: 0)
        // On iOS's keyboard guide, as the chat's field (user choice 2026-11-20, after the sheet's
        // own sums: the sheet's height less the home indicator's room left the field dropping as
        // the keyboard went). With none, the guide is the safe area's foot.
        // From the sheet's top by what is in it, with or without the keyboard: the field stays by
        // what is over it, the home indicator's room iOS adds over the keyboard under it. The
        // keyboard bounds it only while it is up (a long card): iOS's keyboard guide stays with
        // the screen, and bound to it always, the field stood still as the sheet was pulled
        // down, even with `followsUndockedKeyboard` off (tried 2026-11-20).
        view.addLayoutGuide(footLine)
        footFromTop = footLine.topAnchor.constraint(equalTo: view.topAnchor, constant: fitted - Self.foot)
        footFromTop.priority = .defaultHigh
        footOverKeyboard = footLine.topAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor,
                                                         constant: -Self.foot)
        NSLayoutConstraint.activate([
            footFromTop,
            footLine.heightAnchor.constraint(equalToConstant: 0),
            footLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footLine.widthAnchor.constraint(equalToConstant: 0),
        ])
        // Down to the sheet's foot, under the field (`fieldInset`).
        scrollToFoot = scroll.bottomAnchor.constraint(equalTo: footLine.topAnchor)
        scrollToFoot.isActive = true
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            upperHost.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: Spacing.s),
            upperHost.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            upperHost.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: Spacing.page),
            upperHost.view.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -2 * Spacing.page),
            upperHeightConstraint,
        ])
    }

    private func buildBar() {
        // The words, set as the chat's (`ChatWords`).
        ChatWords.set(textView)
        textView.textColor = Palette.uiLabel
        textView.tintColor = UIColor(Palette.primary)
        textView.isScrollEnabled = false
        let lineGap = max(Spacing.xs, (Self.buttonSize - font.lineHeight) / 2)
        textView.textContainerInset = UIEdgeInsets(top: lineGap, left: 0, bottom: lineGap, right: 0)
        // Sent as typed, as the chat's; ⏎ sends.
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        if #available(iOS 18.0, *) { textView.writingToolsBehavior = .none }
        textView.returnKeyType = .send
        textView.delegate = self

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
        leadingHost.view.isHidden = true
        stopHost.view.isHidden = true

        // The sheet's field: grey, not the chat's glass, which over the sheet's own read as a
        // second sheet.
        bar.layer.cornerRadius = Self.radius
        bar.layer.cornerCurve = .continuous
        bar.clipsToBounds = true
        for part in [fieldLight, fieldRing] {
            part.translatesAutoresizingMaskIntoConstraints = false
            part.isUserInteractionEnabled = false
            part.alpha = 0
            bar.contentView.insertSubview(part, at: 0)
            NSLayoutConstraint.activate([
                part.topAnchor.constraint(equalTo: bar.contentView.topAnchor),
                part.bottomAnchor.constraint(equalTo: bar.contentView.bottomAnchor),
                part.leadingAnchor.constraint(equalTo: bar.contentView.leadingAnchor),
                part.trailingAnchor.constraint(equalTo: bar.contentView.trailingAnchor),
            ])
        }
        fieldLight.backgroundColor = UIColor(Palette.accentSoft)
        fieldRing.layer.cornerRadius = Self.radius
        fieldRing.layer.cornerCurve = .continuous
        fieldRing.layer.borderWidth = 1.5

        fieldRow.translatesAutoresizingMaskIntoConstraints = false
        bar.contentView.addSubview(fieldRow)
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            fieldRow.topAnchor.constraint(equalTo: bar.topAnchor, constant: Self.inset),
            fieldRow.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -Self.inset),
            fieldRow.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: Self.inset),
            fieldRow.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -Self.inset),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.page),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.page),
            bar.bottomAnchor.constraint(equalTo: footLine.topAnchor),
        ])

        // A tap anywhere in the field, not only on the words.
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapField))
        tap.delegate = self
        bar.addGestureRecognizer(tap)
        if #available(iOS 26.0, *) {
            // iOS's soft edge where what is over the field runs under it, as in the chat.
            let edge = UIScrollEdgeElementContainerInteraction()
            edge.scrollView = scroll
            edge.edge = .bottom
            bar.addInteraction(edge)
        }
    }

    /// `QuickRecordSheet`, as small as can be and unseen, but in the window so it runs; its
    /// sheets (a row's form) come up from it.
    private func buildLogic() {
        let host = UIHostingController(rootView: AnyView(
            QuickRecordSheet(onNext: { [weak self] next in self?.onNext(next) })
                .environment(store)
                .environment(\.locale, .vietnam)
                .environment(\.quickPageLink, link)
        ))
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        host.sizingOptions = []
        host.view.isUserInteractionEnabled = false
        host.view.alpha = 0
        host.view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        addChild(host)
        view.insertSubview(host.view, at: 0)
        host.didMove(toParent: self)
        logic = host
    }

    /// The chat's glass (`ChatViewController.glassEffect`).
    private static func glassEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let glass = UIGlassEffect(style: .regular)
            glass.isInteractive = true
            return glass
        }
        return UIBlurEffect(style: .systemMaterial)
    }

    /// The room left at the foot of what is over the field for the field over it: the last
    /// words scroll up out from under it.
    private var fieldInset: CGFloat {
        (state?.showsField ?? true) ? Self.gap + boxHeight.constant + 2 * Self.inset : 0
    }

    private func updateFieldInset() {
        let inset = fieldInset
        if scroll.contentInset.bottom != inset {
            scroll.contentInset.bottom = inset
            scroll.verticalScrollIndicatorInsets.bottom = inset
        }
    }

    private static func host(sizing: Bool = true) -> UIHostingController<AnyView> {
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        if sizing { host.sizingOptions = .intrinsicContentSize }
        return host
    }

    private func addHost(_ host: UIViewController) {
        addChild(host)
        host.didMove(toParent: self)
    }

    // MARK: Updating

    func update(_ new: QuickSheetState) {
        let old = state
        state = new
        let moves = view.window != nil && !UIAccessibility.isReduceMotionEnabled

        leadingHost.rootView = AnyView(new.leading.modifier(QuickEnvironment(store: store)))
        stopHost.rootView = AnyView(new.stop.modifier(QuickEnvironment(store: store)))
        actionHost.rootView = AnyView(new.action.modifier(QuickEnvironment(store: store)))
        overlayHost.rootView = AnyView(new.overlay.modifier(QuickEnvironment(store: store)))

        if placeholder.text != new.placeholder {
            UIView.transition(with: placeholder, duration: moves ? 0.25 : 0,
                              options: .transitionCrossDissolve) { self.placeholder.text = new.placeholder }
        }
        textView.accessibilityLabel = new.fieldLabel

        // A sentence just sent: where its words were, read before the field is cleared below;
        // what was over the field goes as it leaves, unless it stays (a card being changed).
        let sent = old.map { $0.sent != new.sent } ?? false
        if sent {
            endFlight()
            if moves {
                // Where the words are on the screen as they go, for the flyer to rise from as
                // the chat's does (user report 2026-11-20: it rose from the field's place once
                // the keyboard had gone, not from the words).
                flightStart = textView.convert(
                    CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top), to: nil)
                saidHidden = true
                // The new bubble's, once laid out: the last one's would have the flyer land in
                // its place and at its width (video 2026-11-20).
                saidFrame = nil
                if !new.keepsUpper { leaveUpper() }
            }
        }
        // What is over the field laid out now, and the sheet sent to its height in this same
        // update: a turn of the run loop later, a card stood for three frames in the sheet still
        // short, over the field, then the sheet leapt (video 2026-11-20).
        updating = true
        showUpper()
        upperHost.view.setNeedsLayout()
        upperHost.view.layoutIfNeeded()
        updating = false
        if upperHeightConstraint.constant != upperHeight {
            upperHeightConstraint.constant = upperHeight
            fitSheet(animated: installed && old != nil)
        }

        let barChanged = old?.showsLeading != new.showsLeading || old?.isDictating != new.isDictating
            || old?.isLit != new.isLit || old?.showsField != new.showsField
        if barChanged {
            if old != nil, moves {
                // Once SwiftUI is done with this update (`ChatViewController.update`).
                DispatchQueue.main.async { self.animateBar() }
            } else {
                applyBar(new)
            }
        }

        // The words going for the wave or Milu at work: the hint not in their place for a frame.
        if new.isDictating, old?.isDictating == false { placeholder.alpha = 0 }
        if textView.text != new.draft, textView.markedTextRange == nil {
            textView.text = new.draft
            textDidChange(animated: old != nil)
        }
        if new.focused, !textView.isFirstResponder {
            DispatchQueue.main.async {
                guard self.state?.focused == true, self.view.window != nil else { return }
                self.textView.becomeFirstResponder()
            }
        } else if !new.focused, textView.isFirstResponder {
            DispatchQueue.main.async {
                if self.state?.focused == false { self.textView.resignFirstResponder() }
            }
        }

        if sent, flightStart != nil {
            // Once the bubble is laid out where it lands (`saidFrame`).
            DispatchQueue.main.async { self.fly(new.sentWords) }
        }
    }

    /// What is over the field, as `state` has it, the said bubble hidden while its flyer is on
    /// its way, the words as wide as the field's so they break where they did as they were typed.
    private func showUpper() {
        guard let state else { return }
        upperHost.rootView = AnyView(
            TopAnchored {
                state.upper
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { [weak self] height in
                        self?.upperResized(height)
                    }
            }
                .modifier(QuickEnvironment(store: store))
                .environment(\.quickSaidHidden, saidHidden)
                .environment(\.quickSaidFrame) { [weak self] frame in self?.saidFrame = frame }
                .environment(\.questionWordsWidth, wordsWidth)
                .coordinateSpace(.named(QuickUpper.space))
        )
    }

    /// How wide the field's words are at rest (`ChatViewController.questionWordsWidth`).
    private var wordsWidth: CGFloat {
        let row = (view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width) - 2 * Spacing.page
        return row - (2 * Self.inset + Spacing.s + Self.buttonSize + Spacing.s)
    }

    /// ✕ and ■ grow in as the field makes room for them, or shrink away as it takes it back, on
    /// one spring; what is in the field goes first, quickly, then the other comes (the chat's).
    private func animateBar() {
        guard let state else { return }
        // What else waits to be laid out (what is over the field at its new height) at once,
        // outside the field's spring: inside it, the SwiftUI over the field went from its old
        // frame to its new one, the bubble dropping to the field and rising back as an answer
        // came (video 2026-11-20).
        UIView.performWithoutAnimation { self.view.layoutIfNeeded() }
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
        if state.showsField == bar.isUserInteractionEnabled { fitSheet(animated: true) }
    }

    private func applyBar(_ state: QuickSheetState, fades: Bool = true) {
        for button in [leadingHost.view!, stopHost.view!] {
            if button.isHidden == state.showsLeading { button.isHidden = !state.showsLeading }
            button.alpha = state.showsLeading ? 1 : 0
            button.transform = state.showsLeading ? .identity : CGAffineTransform(scaleX: 0.4, y: 0.4)
        }
        fieldRing.layer.borderColor = UIColor(Palette.primary).resolvedColor(with: traitCollection).cgColor
        fieldLight.alpha = state.isLit ? 1 : 0
        fieldRing.alpha = state.isLit ? 1 : 0
        if fades {
            textView.alpha = state.isDictating ? 0 : 1
            placeholder.alpha = state.isDictating ? 0 : 1
            overlayHost.view.alpha = state.isDictating ? 1 : 0
        }
        fieldLeading.constant = state.isDictating ? 0 : Spacing.s
        // "Đã lưu": no field, what is over it down to the sheet's foot.
        bar.alpha = state.showsField ? 1 : 0
        bar.isUserInteractionEnabled = state.showsField
        updateFieldInset()
    }

    // MARK: The sheet's height

    /// The sheet as tall as its bar, what is over the field and the field, up to the screen's
    /// top (what is over the field then scrolls).
    private var targetHeight: CGFloat {
        let top = view.safeAreaInsets.top > 0 ? view.safeAreaInsets.top : Self.firstBar
        let upperHeight = self.upperHeight > 0 ? self.upperHeight : Self.firstUpper
        let field = (state?.showsField ?? true) ? Self.gap + boxHeight.constant + 2 * Self.inset : 0
        return (top + Spacing.s + upperHeight + field + Self.foot).rounded()
    }

    /// The height the sheet's detent says (`fitSheet`).
    fileprivate var fitted: CGFloat = 0
    /// The keyboard up (`setKeyboard`).
    private var keyboardUp = false
    /// The sheet's height, the same with or without the keyboard: iOS adds the home indicator's
    /// room under it, and lifts it over the keyboard.
    fileprivate var detentHeight: CGFloat { fitted }
    private var installed = false

    /// The presented controller this one is in, and its sheet.
    private var presented: UIViewController {
        var controller: UIViewController = self
        while let parent = controller.parent { controller = parent }
        return controller
    }

    private var sheet: UISheetPresentationController? { presented.sheetPresentationController }

    /// What is over the field at its frame for the sheet's new height, its words where they go.
    private func settleUpper() {
        // The room it is cut to goes with the sheet, so nothing comes down over the field.
        upperHost.view.frame = CGRect(x: Spacing.page, y: Spacing.s,
                                      width: scroll.bounds.width - 2 * Spacing.page,
                                      height: upperHeightConstraint.constant)
        upperHost.view.layoutIfNeeded()
    }

    /// The sheet's whole content laid out for its height, SwiftUI's bar and frames too: told
    /// nothing, SwiftUI left this page at the sheet's last height, the field half-way up a
    /// sheet grown for a card (log 2026-11-20: the sheet 372, this page 242).
    private func layoutSheet() {
        let root = presented.view!
        root.setNeedsLayout()
        root.layoutIfNeeded()
        view.layoutIfNeeded()
    }

    /// The sheet to `targetHeight`, in the same animation as the layout of what is in it: the
    /// field's foot on the keyboard or the sheet's, what is over it hanging from the bar, so
    /// neither moves on the screen but by the sheet's own top.
    private func fitSheet(animated: Bool) {
        let target = targetHeight
        let changed = abs(target - fitted) >= 0.5
        fitted = target
        footFromTop?.constant = target - Self.foot
        guard let sheet else {
            view.layoutIfNeeded()
            return
        }
        if !installed {
            // In place of SwiftUI's first one (`QuickRecordSheet.firstHeight`), on the way up.
            installed = true
            trace("install \(target) safe \(view.safeAreaInsets.top) upper \(upperHeight)")
            let install = {
                sheet.detents = [.custom(identifier: Self.detent) { [weak self] context in
                    min(self?.detentHeight ?? Self.firstHeight, context.maximumDetentValue)
                }]
                sheet.selectedDetentIdentifier = Self.detent
                self.view.layoutIfNeeded()
            }
            if view.window != nil { sheet.animateChanges(install) } else { install() }
            return
        }
        guard animated, view.window != nil, !UIAccessibility.isReduceMotionEnabled else {
            if changed { sheet.invalidateDetents() }
            layoutSheet()
            return
        }
        if changed {
            // What is over the field at its new size at once, hanging from the bar: in the
            // sheet's animation its frame went from the old size to the new one with the SwiftUI
            // in it laid out for the new, and the bubble dropped to the field and rose back as an
            // answer came (video 2026-11-20). Only the sheet and the field move.
            UIView.performWithoutAnimation { self.settleUpper() }
            sheet.animateChanges {
                sheet.invalidateDetents()
                self.layoutSheet()
            }
        } else {
            UIView.animate(springDuration: 0.35, bounce: 0, initialSpringVelocity: 0, delay: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.view.layoutIfNeeded()
            }
        }
    }

    /// What is over the field changed its height: the sheet with it, the steps of one change
    /// (a card comes to its height in two or three layouts, ms apart) as one.
    private func upperResized(_ height: CGFloat) {
        guard abs(height - upperHeight) >= 0.5 else { return }
        upperHeight = height
        // In `update`, taken there at once.
        guard !updating, !resizePending else { return }
        resizePending = true
        DispatchQueue.main.async {
            self.resizePending = false
            self.applyUpperHeight()
        }
    }

    /// The height measured last, to what is over the field and the sheet.
    private func applyUpperHeight() {
        guard upperHeightConstraint.constant != upperHeight else { return }
        upperHeightConstraint.constant = upperHeight
        fitSheet(animated: installed)
    }

    private var resizePending = false
    private var updating = false

    /// Longer than its room (a long card over the keyboard): its foot, the buttons, in view;
    /// else from its top. Read at each layout, the room as it now is: read as the sheet began to
    /// grow, the room was the short one's, and a card that fitted stood scrolled to its foot,
    /// its top hidden (video 2026-11-20).
    private func keepFootInView(always: Bool = false) {
        // While the keyboard moves, only in its animation (`setKeyboard`).
        guard always || CACurrentMediaTime() >= keyboardMoves else { return }
        var room = scroll.bounds.height
        // With no keyboard, the room the sheet is going to, not the one it has on its way there:
        // as an answer came, the sheet still short, the bubble was scrolled out under the bar
        // and back as the sheet grew, a blink (video 2026-11-20).
        if !keyboardUp {
            room = max(room, fitted - Self.foot - scroll.frame.minY)
        }
        // Less the field over its foot.
        updateFieldInset()
        room -= fieldInset
        guard room > 0, !scroll.isTracking, !scroll.isDecelerating else { return }
        // By the height just measured, not the scroll's content size, which trails it by a
        // layout: read off that, the room cut as the keyboard went and the answer just gone
        // scrolled the new bubble out under the bar, and its flyer landed there (log 2026-11-20).
        let wanted = max(0, Spacing.s + upperHeightConstraint.constant - room)
        if abs(scroll.contentOffset.y - wanted) > 0.5 {
            scroll.contentOffset = CGPoint(x: 0, y: wanted)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if textView.bounds.width != measuredWidth {
            measuredWidth = textView.bounds.width
            textDidChange()
        }
        if !installed, upperHeight > 0 { fitSheet(animated: false) }
        keepFootInView()
    }

    /// The sheet's height set before it comes up: with iOS's own first, it rose to the screen's
    /// top and dropped back (video 2026-11-20).
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !installed {
            view.layoutIfNeeded()
            fitSheet(animated: false)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if installed { fitSheet(animated: false) }
    }

    // MARK: The sentence's flight

    private func trace(_ words: @autoclosure () -> String) {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["MILU_DEMO"] != nil else { return }
        let line = String(format: "%.3f ", CACurrentMediaTime()) + "ctl " + words() + "\n"
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

    /// What was over the field, as it was, going up a little and fading as the sentence leaves
    /// the field; its place taken at once by what comes.
    private func leaveUpper() {
        guard let picture = scroll.snapshotView(afterScreenUpdates: false) else { return }
        // In the room over the field, cut by it as the sheet closes over it: laid over the page,
        // it slid down behind the field as the sheet shrank (video 2026-11-20).
        picture.frame = CGRect(origin: scroll.bounds.origin, size: scroll.bounds.size)
        picture.isUserInteractionEnabled = false
        scroll.addSubview(picture)
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn]) {
            picture.transform = CGAffineTransform(translationX: 0, y: -Spacing.l)
            picture.alpha = 0
        } completion: { _ in
            picture.removeFromSuperview()
        }
    }

    /// The bubble rises from where its words were in the field to its place over the field, on
    /// the chat's spring (0.36 s, bounce 0.15, a beat after the tap), fading in as it leaves the
    /// field; the bubble in its place shows as it lands.
    private func fly(_ words: String, tries: Int = 0) {
        guard let windowStart = flightStart, view.window != nil else {
            endFlight()
            return
        }
        guard let frame = saidFrame else {
            // Not laid out yet: a turn of the run loop more, a few at most.
            if tries < 5 {
                DispatchQueue.main.async { self.fly(words, tries: tries + 1) }
            } else {
                endFlight()
            }
            return
        }
        flightStart = nil
        // What is over the field at its new height first, scrolled as it will be: the height
        // waiting its turn, the bubble landed where the last answer's foot had it (log
        // 2026-11-20, the flyer over the sheet's top).
        applyUpperHeight()
        // From where the words were on the screen, in this page as it is drawn now: the sheet
        // may be on its way down with the keyboard, its layout already at the end of the way.
        // Read in the page's own terms, that end, the bubble rose from under the sheet (iPhone
        // 2026-11-20).
        let start = screenPointInPage(windowStart)
        let host = UIHostingController(rootView: AnyView(UserBubble(text: words)
            .modifier(QuickEnvironment(store: store))
            .environment(\.questionWordsWidth, wordsWidth)))
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        // Its own size, as the bubble it lands on sets its words; on that one's foot and end.
        let size = host.sizeThatFits(in: CGSize(width: upperHost.view.bounds.width, height: .greatestFiniteMagnitude))
        let placed = upperHost.view.convert(frame, to: view)
        let landing = CGRect(x: placed.maxX - size.width, y: placed.minY, width: size.width, height: size.height)
        trace("fly from \(start) to \(landing) offset \(scroll.contentOffset.y)")
        let from = CGPoint(x: start.x - Bubble.userInset.leading, y: start.y - Bubble.userInset.top)

        addChild(host)
        host.view.frame = landing
        host.view.transform = CGAffineTransform(translationX: from.x - landing.minX, y: from.y - landing.minY)
        host.view.alpha = 0
        view.insertSubview(host.view, belowSubview: bar)
        host.didMove(toParent: self)
        flyer = host

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

    /// A point of the screen in this page's terms as the page is drawn this frame (its
    /// presentation, mid-animation), so a view put there now shows on that point.
    private func screenPointInPage(_ point: CGPoint) -> CGPoint {
        guard let window = view.window, let shown = view.layer.presentation() else {
            return view.convert(point, from: nil)
        }
        let screen = window.layer.presentation() ?? window.layer
        let origin = shown.convert(CGPoint.zero, to: screen)
        let model = view.convert(CGPoint.zero, to: nil)
        // The model's point, moved by how far the drawn page is from the model's.
        return CGPoint(x: view.convert(point, from: nil).x + (model.x - origin.x),
                       y: view.convert(point, from: nil).y + (model.y - origin.y))
    }

    /// The flyer away and the bubble shown in its place.
    private func endFlight() {
        flightStart = nil
        if saidHidden {
            saidHidden = false
            showUpper()
        }
        guard let flyer else { return }
        self.flyer = nil
        // A frame later: the bubble in its place drawn first, so nothing blinks between them.
        DispatchQueue.main.async {
            flyer.willMove(toParent: nil)
            flyer.view.removeFromSuperview()
            flyer.removeFromParent()
        }
    }

    // MARK: The field

    @objc private func putKeyboardAway() {
        textView.resignFirstResponder()
    }

    @objc private func tapField() {
        if state?.canEdit == true, state?.isDictating == false {
            textView.becomeFirstResponder()
        } else {
            onTapField()
        }
    }

    /// The field grows with its lines up to four, then scrolls inside; the sheet grows with it
    /// (`ChatViewController.textDidChange`).
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

        let grows = height > boxHeight.constant
        textOnTop.isActive = false
        textOnFoot.isActive = false
        (grows ? textOnFoot : textOnTop).isActive = true
        textHeight.constant = height
        UIView.performWithoutAnimation { fieldBox.layoutIfNeeded() }
        boxHeight.constant = height
        fitSheet(animated: animated)
    }
}

extension QuickRecordController: UITextViewDelegate {
    /// The words are typed only while typing: a tap in them otherwise is the step's (`tapField`).
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard state?.canEdit == true, state?.isDictating == false else {
            onTapField()
            return false
        }
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text != "\n" else {
            onSend()
            return false
        }
        return state?.isDictating != true
    }

    func textViewDidChange(_ textView: UITextView) {
        textDidChange(animated: true)
        onDraftChange(textView.text)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if state?.focused != true { onFocus(true) }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if state?.focused != false { onFocus(false) }
    }
}

extension QuickRecordController: UISheetPresentationControllerDelegate {
    /// Pulled down by a finger.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        gone()
    }
}

extension QuickRecordController: UIGestureRecognizerDelegate {
    /// The field's buttons take their own taps.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touched = touch.view else { return true }
        return ![leadingHost.view, stopHost.view, actionHost.view].contains { touched.isDescendant(of: $0) }
    }
}

/// What `QuickRecordController` lays out, as `QuickRecordSheet` has it now.
struct QuickSheetState {
    /// Over the field (SwiftUI): the greeting, the bubble said and Milu's answer, a card.
    var upper: AnyView
    /// Sentences sent so far: a new one rises from the field into its bubble.
    var sent: Int
    var sentWords: String
    /// What is over the field stays as the sentence leaves (a card being changed, its words
    /// landing under it); else it goes.
    var keepsUpper: Bool
    var draft: String
    var placeholder: String
    var fieldLabel: String
    /// The keyboard on the words.
    var focused: Bool
    /// Words can be typed in this step; a tap otherwise is the step's (`onTapField`).
    var canEdit: Bool
    /// The overlay in the words' place: the wave, or the voice turning into words, Milu at work.
    var isDictating: Bool
    /// ✕ and ■, while listening.
    var showsLeading: Bool
    /// The field lit up: the voice turning into words, Milu at work.
    var isLit: Bool
    var showsField: Bool
    var leading: AnyView
    var stop: AnyView
    var action: AnyView
    var overlay: AnyView
}

/// Where `QuickRecordSheet` sends each step: the page it runs in.
final class QuickPageLink {
    weak var page: QuickRecordController?
}

/// `QuickRecordSheet`'s steps to its page (`QuickRecordController`), at each of its updates.
struct QuickSheetBridge: UIViewRepresentable {
    let state: QuickSheetState
    let onDraftChange: (String) -> Void
    let onSend: () -> Void
    let onFocus: (Bool) -> Void
    let onTapField: () -> Void

    @Environment(\.quickPageLink) private var link

    func makeUIView(context: Context) -> UIView { UIView() }

    func updateUIView(_ view: UIView, context: Context) {
        guard let page = link?.page else { return }
        page.onDraftChange = onDraftChange
        page.onSend = onSend
        page.onFocus = onFocus
        page.onTapField = onTapField
        page.update(state)
    }
}

/// What is over the quick sheet's field tells its page where the bubble said is, and hides it
/// while its flyer is on the way (`QuickRecordController.fly`).
enum QuickUpper {
    static let space = "quickUpper"
}

extension EnvironmentValues {
    @Entry var quickPageLink: QuickPageLink? = nil
    @Entry var quickSaidHidden = false
    @Entry var quickSaidFrame: ((CGRect) -> Void)? = nil
}

/// As the quick sheet's SwiftUI had it, each hosted part.
private struct QuickEnvironment: ViewModifier {
    let store: FinanceStore

    func body(content: Content) -> some View {
        content
            .miluFont(.body)
            .foregroundStyle(Palette.label)
            .environment(store)
            .environment(\.locale, .vietnam)
            .environment(\.isInSheet, true)
            .environment(\.isInHeaderCard, false)
    }
}

/// Puts "Thêm bằng AI" up in iOS's sheet by UIKit (`QuickRecordController.present`) while
/// `isPresented`, from wherever is on top; down again once it is false.
struct QuickRecordPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let store: FinanceStore
    let onNext: (QuickRecordNext) -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        weak var shown: UIViewController?
    }

    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ anchor: UIViewController, context: Context) {
        let coordinator = context.coordinator
        if isPresented, coordinator.shown == nil {
            guard var top = anchor.view.window?.rootViewController else { return }
            while let next = top.presentedViewController, !next.isBeingDismissed { top = next }
            let binding = $isPresented
            let onDismiss = onDismiss
            coordinator.shown = QuickRecordController.present(over: top, store: store, onNext: onNext) {
                coordinator.shown = nil
                if binding.wrappedValue { binding.wrappedValue = false }
                onDismiss()
            }
        } else if !isPresented, let shown = coordinator.shown, !shown.isBeingDismissed {
            shown.dismiss(animated: true)
        }
    }
}

/// Its one subview at its own height from the top, whatever height it is given: what is over the
/// quick sheet's field. With a frame aligned to the top it stood in the middle of the host for a
/// moment as the host took the answer's height before SwiftUI did, and slid up from there, the
/// bubble dropping to the field and rising back (video 2026-11-20).
private struct TopAnchored: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = subviews.first?.sizeThatFits(ProposedViewSize(width: width, height: nil)).height ?? 0
        return CGSize(width: width, height: proposal.height ?? height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let view = subviews.first else { return }
        let size = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
        view.place(at: CGPoint(x: bounds.minX, y: bounds.minY), anchor: .topLeading,
                   proposal: ProposedViewSize(width: bounds.width, height: size.height))
    }
}
