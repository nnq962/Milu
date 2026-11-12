import SwiftUI
import UIKit

/// The sync pill, drawn and moved by UIKit (user request 2026-11-12: the SwiftUI one stuttered).
/// While a sync comes down the main thread is busy (the data arriving, the screens redrawn with
/// it: hitches of 48–68 ms measured on an iPhone 16 Pro); SwiftUI works out each frame of an
/// animation on the main thread, so the pill stalled with it. Core Animation hands the movement to
/// the render server, which keeps it smooth whatever the main thread is doing.
///
/// `SyncStatusPill` still decides what shows and when (`SyncPillTimeline`); this only shows it.
struct SyncPillRepresentable: UIViewRepresentable {
    let shown: SyncPillTimeline.Shown?
    let text: String

    func makeUIView(context: Context) -> SyncPillUIView { SyncPillUIView() }

    func updateUIView(_ view: SyncPillUIView, context: Context) {
        view.show(shown, text: text)
    }
}

final class SyncPillUIView: UIView {
    /// Everything moves together: the shadow lives here, outside the clipped capsule.
    private let wrapper = UIView()
    private let capsule = UIView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let tick = UIImageView(image: UIImage(systemName: "checkmark.icloud.fill"))
    private var label = UILabel()

    private var shown: SyncPillTimeline.Shown?
    private var text = ""

    private static let height: CGFloat = 38
    private static let side: CGFloat = 16
    private static let iconSize: CGFloat = 20
    private static let gap: CGFloat = 8

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        wrapper.layer.shadowColor = UIColor.black.cgColor
        wrapper.layer.shadowOpacity = 0.08
        wrapper.layer.shadowRadius = 10
        wrapper.layer.shadowOffset = CGSize(width: 0, height: 4)
        wrapper.alpha = 0
        wrapper.isAccessibilityElement = true
        addSubview(wrapper)

        capsule.backgroundColor = UIColor(Palette.surface)
        capsule.layer.borderWidth = 1
        capsule.layer.cornerCurve = .continuous
        capsule.clipsToBounds = true
        wrapper.addSubview(capsule)

        spinner.color = UIColor(Palette.primary)
        tick.tintColor = UIColor(Palette.positive)
        tick.contentMode = .scaleAspectFit
        tick.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        tick.alpha = 0
        capsule.addSubview(spinner)
        capsule.addSubview(tick)
        styleLabel(label)
        capsule.addSubview(label)
        updateColors()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: SyncPillUIView, _) in
            view.updateColors()
        }
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: SyncPillUIView, _) in
            view.styleLabel(view.label)
            view.setNeedsLayout()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private func updateColors() {
        // A CGColor does not follow dark mode by itself.
        capsule.layer.borderColor = UIColor(Palette.separator).resolvedColor(with: traitCollection).cgColor
    }

    private func styleLabel(_ label: UILabel) {
        let role = TextRole.captionStrong
        let base = UIFont(name: Typography.instance(for: role.weight), size: role.size)
            ?? .systemFont(ofSize: role.size, weight: .bold)
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: base, compatibleWith: traitCollection)
        label.textColor = UIColor(Palette.label)
        label.numberOfLines = 1
    }

    // MARK: Layout

    /// The capsule for `labelWidth`, centred at the bottom of this view.
    private func capsuleFrame(labelWidth: CGFloat) -> CGRect {
        let width = Self.side * 2 + Self.iconSize + Self.gap + labelWidth
        return CGRect(x: (bounds.width - width) / 2, y: bounds.height - Self.height, width: width, height: Self.height)
    }

    /// By bounds and centre, not frame: the label may be mid-move (a transform), and a frame set
    /// then lands in the wrong place (it sat high, 2026-11-12).
    private func place(_ label: UILabel, in frame: CGRect) {
        let size = label.intrinsicContentSize
        label.bounds = CGRect(origin: .zero, size: size)
        label.center = CGPoint(x: Self.side + Self.iconSize + Self.gap + size.width / 2, y: frame.height / 2)
    }

    private func layoutPill() {
        let frame = capsuleFrame(labelWidth: label.intrinsicContentSize.width)
        wrapper.bounds = CGRect(origin: .zero, size: frame.size)
        wrapper.center = CGPoint(x: frame.midX, y: frame.midY)
        capsule.frame = wrapper.bounds
        capsule.layer.cornerRadius = Self.height / 2
        wrapper.layer.shadowPath = UIBezierPath(roundedRect: wrapper.bounds, cornerRadius: Self.height / 2).cgPath
        let icon = CGRect(x: Self.side, y: (Self.height - Self.iconSize) / 2, width: Self.iconSize, height: Self.iconSize)
        spinner.center = CGPoint(x: icon.midX, y: icon.midY)
        tick.frame = icon
        place(label, in: frame)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Not while a move is running: the animation owns the frames then.
        guard wrapper.layer.animationKeys()?.isEmpty ?? true else { return }
        layoutPill()
    }

    // MARK: States

    func show(_ new: SyncPillTimeline.Shown?, text newText: String) {
        guard new != shown || (new != nil && newText != text) else { return }
        let old = shown
        shown = new
        wrapper.accessibilityLabel = newText
        switch (old, new) {
        case (nil, let state?):
            text = newText
            label.text = newText
            setIcon(state, animated: false)
            appear()
        case (_?, nil):
            disappear()
        case (_?, let state?):
            change(to: state, text: newText)
        case (nil, nil):
            break
        }
    }

    private func appear() {
        layoutPill()
        wrapper.layer.removeAllAnimations()
        if reduceMotion {
            wrapper.transform = .identity
            UIView.animate(withDuration: 0.2) { self.wrapper.alpha = 1 }
            return
        }
        wrapper.transform = CGAffineTransform(translationX: 0, y: 24).scaledBy(x: 0.85, y: 0.85)
        wrapper.alpha = 0
        UIView.animate(springDuration: 0.5, bounce: 0.25) {
            self.wrapper.transform = .identity
            self.wrapper.alpha = 1
        }
    }

    private func disappear() {
        if reduceMotion {
            UIView.animate(withDuration: 0.2) { self.wrapper.alpha = 0 }
            return
        }
        UIView.animate(springDuration: 0.45, bounce: 0) {
            self.wrapper.transform = CGAffineTransform(translationX: 0, y: 24).scaledBy(x: 0.85, y: 0.85)
            self.wrapper.alpha = 0
        }
    }

    /// The words swap in place (the old ones fade up and away, the new ones rise into place) while
    /// the capsule eases to the new width; the icon turns from spinner to tick. The capsule clips
    /// the old words as it narrows, so they never run past its edge.
    private func change(to state: SyncPillTimeline.Shown, text newText: String) {
        let oldLabel = label
        if newText != text {
            text = newText
            let newLabel = UILabel()
            styleLabel(newLabel)
            newLabel.text = newText
            capsule.addSubview(newLabel)
            label = newLabel
            let target = capsuleFrame(labelWidth: newLabel.intrinsicContentSize.width)
            place(newLabel, in: target)
            if !reduceMotion {
                newLabel.transform = CGAffineTransform(translationX: 0, y: 10)
            }
            newLabel.alpha = 0
        }
        setIcon(state, animated: true)

        let swapped = oldLabel !== label
        // The old words leave quickly, the new ones come in just after: the two barely overlap.
        if swapped {
            UIView.animate(withDuration: reduceMotion ? 0.15 : 0.18, delay: 0, options: [.curveEaseIn]) {
                oldLabel.alpha = 0
                if !self.reduceMotion { oldLabel.transform = CGAffineTransform(translationX: 0, y: -10) }
            } completion: { _ in oldLabel.removeFromSuperview() }
        }
        if reduceMotion {
            UIView.animate(withDuration: 0.25) {
                self.layoutPill()
                self.label.alpha = 1
            }
            return
        }
        UIView.animate(springDuration: 0.5, bounce: 0.25) { self.layoutPill() }
        UIView.animate(springDuration: 0.45, bounce: 0.2, delay: swapped ? 0.08 : 0, options: []) {
            self.label.alpha = 1
            self.label.transform = .identity
        }
    }

    private func setIcon(_ state: SyncPillTimeline.Shown, animated: Bool) {
        let receiving = state == .receiving
        if receiving { spinner.startAnimating() }
        let apply = {
            self.spinner.alpha = receiving ? 1 : 0
            self.spinner.transform = receiving || self.reduceMotion ? .identity : CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.tick.alpha = receiving ? 0 : 1
            self.tick.transform = !receiving || self.reduceMotion ? .identity : CGAffineTransform(scaleX: 0.4, y: 0.4)
        }
        guard animated else {
            apply()
            return
        }
        if !receiving, !reduceMotion { tick.transform = CGAffineTransform(scaleX: 0.4, y: 0.4) }
        UIView.animate(springDuration: 0.45, bounce: 0.35, animations: apply) { _ in
            if !receiving { self.spinner.stopAnimating() }
        }
        if !receiving, !reduceMotion {
            tick.addSymbolEffect(.bounce, options: .nonRepeating)
        }
    }
}
