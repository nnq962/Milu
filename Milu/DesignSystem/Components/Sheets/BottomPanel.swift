import SwiftUI
import UIKit

/// A short sheet the app draws itself, for a sheet whose content changes height as one uses it
/// ("Thêm bằng AI"). Put up in a cover iOS shows at once and clear (`presentsPanel`), it slides
/// in over a dimmed page as iOS's own does, with the same ✕, title and corners.
///
/// Why not iOS's sheet (user report 2026-11-19, "Thêm bằng AI": "chiều cao sheet thay đổi rất
/// nhanh chứ không mượt mà", the keyboard "khựng 1 nhịp"): iOS takes a sheet to a new height on
/// its own curve, apart from the content inside, and only between detents it already has, so a
/// small step came at once and a big one out of time with the content; and a sheet taller than the
/// room over the keyboard was stretched to the screen's top in a snap. Here the height is the
/// content's, laid out with it: what animates the content animates the sheet, in the same frame.
/// The keyboard carries it up as it carries any view; past the room left, the content scrolls.
struct BottomPanel<Content: View>: View {
    let title: String
    /// The content held to its foot while it scrolls (a long card with the keyboard up): the
    /// field stays over the keyboard, the top goes under the title.
    var anchorsBottom = false
    @ViewBuilder var content: Content

    @Environment(\.dismiss) private var dismiss
    /// Where its close and its motion are put, for the view it is in (`presentsPanel`).
    @Environment(\.panelControl) private var control
    /// The screen asked for its full rate, while something moves (`moving`).
    @State private var fullRate = false
    /// In: slid up over the dimmed page.
    @State private var shown = false
    /// Pulled down by the title or, when nothing scrolls, by any of it.
    @State private var drag: CGFloat = 0
    @State private var isClosing = false
    /// The content taller than the room it has: it scrolls, and a pull down on it is the scroll's.
    @State private var scrolls = false
    /// Heights read every frame a step moves them, kept out of the view's state: reading them
    /// redraws nothing, and `scrolls` changes only when they cross.
    @State private var sizes = PanelSizes()
    private static var foot: String { "BottomPanel.foot" }

    /// Under the status bar, the least room above the sheet.
    private static var topGap: CGFloat { 8 }

    /// iOS's own sheet, measured frame by frame ("Thêm mới", Simulator 2026-11-19): in and out on
    /// a spring with no bounce, 0.33 s in and 0.3 s out, over its own height and no further.
    private static var opening: Animation { .spring(duration: 0.33, bounce: 0) }
    private static var closingTime: TimeInterval { 0.3 }
    /// Past the screen's foot when out, from the foot of its frame and what is under it: just out
    /// of sight, its corners and all, so the curve ends as it goes (as iOS's).
    private static var past: CGFloat { 8 }

    var body: some View {
        GeometryReader { proxy in
            // The keyboard is the bottom safe area while it is up (the home indicator's is 34).
            let bottomInset = proxy.safeAreaInsets.bottom
            // Out of sight by its own height and what is under it, no more: dropped by a whole
            // screen, it was gone in three frames of its curve (user report 2026-11-19: "đóng
            // sheet quá nhanh không còn giống sheet bình thường ios").
            let below = bottomInset + Self.past
            // Lighter as it is pulled down, as iOS's dimming.
            let pulled = Double(min(max(drag, 0) / max(sizes.panel + below, 1), 1))
            ZStack(alignment: .bottom) {
                Palette.scrim
                    .opacity(shown ? 1 - pulled : 0)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { close() }
                    .accessibilityHidden(true)
                panel(bottomInset: bottomInset)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sizes.panel = $0 }
                    // Moved as it is drawn, by its own height (`below`): the step's height and the
                    // slide in one frame, nothing laid out again for it.
                    .visualEffect { [shown, drag] content, geometry in
                        content.offset(y: shown ? drag : geometry.size.height + below)
                    }
                    .frame(maxHeight: max(proxy.size.height - Self.topGap, 0), alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom + Self.past } action: { sizes.below = $0 }
            .background { FullFrameRate(on: fullRate) }
        }
        .environment(\.isInSheet, true)
        .frameProbe("panel", value: shown ? 1 : 0)
        .onAppear {
            // Its own close and its motion for the view that made it: Huỷ and the close after
            // Lưu went through iOS's dismissal instead, the whole cover dropping at once, dimming
            // and all (Simulator 2026-11-19).
            control?.closeAction = { close() }
            control?.movingAction = { moving() }
            guard !shown else { return }
            moving(0.7)
            withAnimation(Motion.gentle(Self.opening)) { shown = true }
        }
    }

    /// Something moves for the next `seconds`: the screen at its full rate meanwhile
    /// (`FullFrameRate`), and back to iOS's own once all is still.
    private func moving(_ seconds: CFTimeInterval = 0.6) {
        sizes.movingUntil = max(sizes.movingUntil, CACurrentMediaTime() + seconds)
        guard !fullRate else { return }
        fullRate = true
        Task {
            while CACurrentMediaTime() < sizes.movingUntil {
                try? await Task.sleep(for: .milliseconds(100))
            }
            fullRate = false
        }
    }

    // MARK: - Khung

    @ViewBuilder
    private func panel(bottomInset: CGFloat) -> some View {
        let margin = Self.margin
        let shape = Self.shape
        VStack(spacing: 0) {
            // The bar's room; the bar itself over what scrolls (`header`).
            Color.clear.frame(height: Self.barHeight)
            HuggingScroll {
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(spacing: 0) {
                            content
                                .padding(.horizontal, Spacing.page)
                                .padding(.top, Spacing.s)
                                .padding(.bottom, Spacing.xxl)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            // The foot `anchorsBottom` holds at the bottom.
                            Color.clear.frame(height: 0).id(Self.foot)
                        }
                        .keyboardDismissArea()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            sizes.content = height
                            // Every frame of a step, the sheet growing or shrinking with it.
                            moving(0.3)
                            // On a curve, as for the room: held there at once, the content leapt
                            // to its foot in a frame as the keyboard rose (Simulator 2026-11-19).
                            fit(reader)
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.immediately)
                    .scrollIndicators(.hidden, axes: .vertical)
                    // The room shrinking under a long content (the keyboard rising): the foot
                    // scrolled up as the sheet's foot rises, in the same time, rather than left
                    // under it (Simulator 2026-11-19: neither `defaultScrollAnchor` nor
                    // `scrollPosition` kept it there as the scroll view shrank).
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                        sizes.scroll = height
                        moving(0.5)
                        fit(reader)
                    }
                    .onChange(of: anchorsBottom) { fit(reader) }
                }
            }
            // Any of it pulls the sheet down while nothing scrolls; the scroll's own when it does.
            .simultaneousGesture(pull, including: scrolls ? .subviews : .all)
        }
        // Drawn over the content, as iOS's bar is: the ✕'s glass and its soft shadow lie over
        // a card scrolled up under it. Above it in a stack, the card was drawn over the shadow's
        // foot, cut there in a straight light line (user report 2026-11-19, the keyboard up while
        // a card was changed: "một vệt sáng ở tiêu đề sheet").
        .overlay(alignment: .top) { header }
        .foregroundStyle(Palette.label)
        .background {
            // Down to the screen's foot always, round the home indicator and under the keyboard
            // alike, as iOS's sheet: the keyboard is laid over its lower part, its corners those
            // of the screen whatever the keyboard does. It stopped over the keyboard before, its
            // corners rounded there and changing as the keyboard went (user report 2026-11-19:
            // "chuyển từ trạng thái bo tròn chưa đúng về bo tròn đúng"; iOS's own sheet,
            // Simulator the same day, goes on under the keyboard).
            shape
                .fill(Palette.surface)
                .padding(.bottom, -max(bottomInset - margin, 0))
        }
        .padding(.horizontal, margin)
        .accessibilityAction(.escape) { close() }
    }

    /// Whether the content scrolls, from the heights just read; while `anchorsBottom` and it does,
    /// its foot at the bottom, moved there on the sheet's curve as the room or the content changes.
    private func fit(_ reader: ScrollViewProxy) {
        let now = sizes.content > sizes.scroll + 1
        if now != scrolls { scrolls = now }
        guard anchorsBottom, now else { return }
        withAnimation(Motion.gentle(.smooth(duration: 0.35))) {
            reader.scrollTo(Self.foot, anchor: .bottom)
        }
    }

    /// ✕ on the left and the title in the middle, as iOS's sheet bar.
    private var header: some View {
        ZStack {
            // As every sheet's bar title: Nunito SemiBold 17 in iOS's own label colour
            // (`Typography`'s navigation bar appearance).
            Text(title)
                .font(.custom(Typography.instance(for: .semibold), fixedSize: 17))
                .foregroundStyle(Color(uiColor: .label))
                .lineLimit(1)
                .padding(.horizontal, 56)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PanelCloseButton { close() }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Spacing.m)
        .frame(height: Self.barHeight - Spacing.m - Spacing.s)
        .padding(.top, Spacing.m)
        .padding(.bottom, Spacing.s)
        // Under the bar, what scrolls up fades into it, as under iOS's, rather than cut by a line:
        // there always, over the content's own top room (`Spacing.s`), unseen until something
        // scrolls into it. It came and went with the scroll before, and coming as the keyboard
        // rose it was drawn at once where the sheet was going, a light band over the sheet still
        // on its way up (user video 2026-11-19, a card being changed).
        .background(alignment: .bottom) {
            LinearGradient(colors: [Palette.surface, Palette.surface.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: Spacing.s)
                .offset(y: Spacing.s)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        // The bar always pulls it down, scrolling or not.
        .gesture(pull)
    }

    /// The bar: the ✕'s 44 and the room over and under it.
    private static var barHeight: CGFloat { Spacing.m + 44 + Spacing.s }

    // MARK: - Kéo xuống, đóng

    /// Down as far as the finger goes, up only a little; let go past half its height, or thrown
    /// down, it goes on down at the finger's speed, as iOS's sheet; else back on the same curve.
    private var pull: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                guard !isClosing else { return }
                moving(0.3)
                let down = value.translation.height
                drag = down > 0 ? down : down / 8
            }
            .onEnded { value in
                guard !isClosing else { return }
                moving(0.6)
                let speed = value.velocity.height
                // Where the throw would take it, as UIKit reckons a sheet's (a scroll view's
                // deceleration, half a second of the speed): past half its height, it goes.
                let landing = max(value.translation.height + speed * 0.5, value.predictedEndTranslation.height)
                if landing > sizes.panel / 2 {
                    close(speed: speed)
                } else {
                    let back = drag > 1 ? Double(-speed / drag) : 0
                    withAnimation(Motion.gentle(.interpolatingSpring(duration: Self.closingTime, bounce: 0,
                                                                     initialVelocity: back))) { drag = 0 }
                }
            }
    }

    /// Slides down as the page brightens, the keyboard going with it, at the finger's `speed` when
    /// let go; then the cover goes without iOS's own slide.
    private func close(speed: CGFloat = 0) {
        guard !isClosing else { return }
        isClosing = true
        moving(0.6)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let finish = {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { dismiss() }
        }
        guard Motion.gentle(Self.opening) != nil else {
            finish()
            return
        }
        // The spring's speed is a share of the way left to go, per second.
        let left = max(sizes.panel + sizes.below - drag, 1)
        let curve = Animation.interpolatingSpring(duration: Self.closingTime, bounce: 0,
                                                  initialVelocity: Double(max(speed, 0) / left))
        withAnimation(curve, completionCriteria: .logicallyComplete) {
            shown = false
        } completion: {
            finish()
        }
    }

    // MARK: - Dáng

    private static var topRadius: CGFloat {
        #if DEBUG
        if let tuned = ProcessInfo.processInfo.environment["MILU_TOP_RADIUS"].flatMap(Double.init) { return tuned }
        #endif
        return 36
    }

    /// iOS 26's sheet floats inside the screen's edges; before it, it meets them.
    private static var margin: CGFloat {
        if #available(iOS 26.0, *) { 8 } else { 0 }
    }

    /// iOS 26's sheet, measured on "Thêm mới" (Simulator 2026-11-19): its top corners 36, its
    /// foot's concentric with the screen's corners, as it floats 8 inside them. One 42 all round
    /// was too round at the top and too tight at the foot, the screen's own curve unmatched there
    /// (user report 2026-11-19: "hình dạng sheet AI rất lạ … ở top và bottom"). Over the
    /// keyboard, its foot goes on under it, to the screen's corners still.
    private static var shape: AnyShape {
        if #available(iOS 26.0, *) {
            AnyShape(ConcentricRectangle(uniformTopCorners: .fixed(Self.topRadius),
                                         uniformBottomCorners: .concentric(minimum: .fixed(Self.topRadius))))
        } else {
            AnyShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12, style: .continuous))
        }
    }
}

/// The heights a `BottomPanel` reads as they change: a box, so writing them redraws nothing.
private final class PanelSizes {
    /// The sheet, the content in its scroll view, and the scroll view.
    var panel: CGFloat = 0
    var content: CGFloat = 0
    var scroll: CGFloat = 0
    /// From its foot to below the screen's (`BottomPanel.body`).
    var below: CGFloat = 42
    /// Till when something moves (`BottomPanel.moving`).
    var movingUntil: CFTimeInterval = 0
}

/// SwiftUI draws its animations at 60 frames a second on a 120 Hz iPhone unless something on the
/// screen asks for more (iPhone 16 Pro, 2026-11-19, `FrameLog`: the sheet's slide at 60/s with the
/// main thread all but idle; its steps at 112/s only while the mic's wave, a `TimelineView` of
/// its own, was still there). While `on`, this asks for it, as the wave does; off, the screen
/// goes back to iOS's own rate, slower when nothing moves.
private struct FullFrameRate: View {
    let on: Bool

    var body: some View {
        #if DEBUG
        if FrameRateBoost.method == "off" {
            EmptyView()
        } else if FrameRateBoost.method == "link" {
            Color.clear.frame(width: 1, height: 1).onChange(of: on, initial: true) { FrameRateBoost.shared.set(on) }
        } else {
            asking
        }
        #else
        asking
        #endif
    }

    private var asking: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !on)) { _ in
            Color.clear
        }
        .frame(width: 1, height: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
/// `MILU_RATE=off|link` (DEBUG only): how `FullFrameRate` asks, to compare on an iPhone; a
/// display link of the app's own for "link", nothing for "off".
final class FrameRateBoost: NSObject {
    static let method = ProcessInfo.processInfo.environment["MILU_RATE"] ?? "timeline"
    static let shared = FrameRateBoost()
    private var link: CADisplayLink?

    func set(_ on: Bool) {
        if on, link == nil {
            let link = CADisplayLink(target: self, selector: #selector(step))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
            link.add(to: .main, forMode: .common)
            self.link = link
        } else if !on {
            link?.invalidate()
            link = nil
        }
    }

    @objc private func step(_ link: CADisplayLink) {}
}
#endif

/// A scroll view as tall as its content, and no taller than the room it is given: so the sheet
/// around it is as tall as what it shows, and only a content longer than the screen scrolls. A
/// layout rather than a measured height, so its height moves in the same frame as the content.
private struct HuggingScroll: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let scroll = subviews.first else { return .zero }
        let ideal = scroll.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: proposal.width ?? ideal.width, height: min(ideal.height, proposal.height ?? ideal.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}

/// ✕ of a `BottomPanel`: iOS 26's glass circle, or iOS 17's small grey disc (`SheetCloseButton`).
private struct PanelCloseButton: View {
    let action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Palette.primary)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(width: LegacyBar.sheetControl, height: LegacyBar.sheetControl)
                        .background(Palette.fill, in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel("Đóng")
    }
}

/// The `BottomPanel` in a cover, for the view that makes it as well as what is in it: given at
/// the cover's root (`presentsPanel`), the panel putting its own in once it is up. Nil outside
/// one.
final class PanelControl {
    fileprivate var closeAction: (() -> Void)?
    fileprivate var movingAction: (() -> Void)?

    /// Slides it away, the page brightening (`dismiss` would drop the whole cover at once).
    func close() { closeAction?() }

    /// Something in it is about to move: the screen at its full rate for that (`FullFrameRate`).
    func moving() { movingAction?() }
}

extension EnvironmentValues {
    @Entry var panelControl: PanelControl? = nil
}

/// The cover's root: the one `PanelControl` for the panel and the view around it.
private struct PanelHost<Panel: View>: View {
    @State private var control = PanelControl()
    @ViewBuilder var panel: Panel

    var body: some View {
        panel.environment(\.panelControl, control)
    }
}

extension View {
    /// Puts up a `BottomPanel` view: in a clear cover iOS shows at once, the panel sliding in by
    /// itself (`BottomPanel`); `isPresented` should be set inside `withTransaction` with
    /// `disablesAnimations`, or iOS slides the clear cover up too. Close it with `panelControl`, not
    /// `dismiss`, or iOS drops the whole cover at once.
    func presentsPanel<Panel: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
                                    @ViewBuilder panel: @escaping () -> Panel) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            PanelHost { panel() }
                .presentationBackground(.clear)
        }
    }
}
