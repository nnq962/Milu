import SwiftUI

/// iOS 17 to 25 stand-ins for what Milu draws with iOS 26 (user request 2026-11-02: the app runs
/// from iOS 17 again, for an iPhone on 17.6). On iOS 26 each one is the real thing; before it, the
/// nearest plain look: no Liquid Glass, no scroll-edge effect, no subtitle under a bar title.
extension View {
    /// No Writing Tools (Apple Intelligence's rewrite and proofread) over the keyboard, where iOS
    /// has them (18); nothing to turn off before.
    @ViewBuilder
    func writingToolsDisabledIfAvailable() -> some View {
        if #available(iOS 18.0, *) {
            writingToolsBehavior(.disabled)
        } else {
            self
        }
    }

    /// `scrollEdgeEffectHidden` where iOS has the scroll-edge effect (26); nothing to hide before.
    @ViewBuilder
    func scrollEdgeEffectHiddenIfAvailable(_ hidden: Bool = true) -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(hidden, for: .all)
        } else {
            self
        }
    }

    /// iOS 26's soft scroll edge under the top bar once `scrolled`: what scrolls up blurs and
    /// fades as it nears the bar, as in Notes (user request 2026-11-07, over the hard band of the
    /// review the same day), so big words never sit sharp under the bar's buttons. At the top no
    /// edge at all, so the page's sky runs on under the bar. The system's own effect, no blur of
    /// our own.
    @ViewBuilder
    func topScrollEdgeIfAvailable(scrolled: Bool) -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectHidden(!scrolled, for: .top)
        } else {
            self
        }
    }

    /// Whether the scroll view has left its top by more than a few points: a yes or no, written
    /// only when it flips, so scrolling does not rebuild the page (user report 2026-11-07).
    @ViewBuilder
    func onScrolledFromTop(_ action: @escaping (Bool) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 4 } action: { _, new in action(new) }
        } else {
            self
        }
    }

    /// Calls `action` as the page scrolls, about every 24 points (Than wakes on it, 2026-11-13);
    /// before iOS 18, never.
    @ViewBuilder
    func onScrollMoved(_ action: @escaping () -> Void) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: Int.self) { Int($0.contentOffset.y / 24) } action: { _, _ in action() }
        } else {
            self
        }
    }

    /// The line under a bar's title (Trợ lý AI); before iOS 26 the bar has no room for one.
    @ViewBuilder
    func navigationSubtitleIfAvailable(_ subtitle: String) -> some View {
        if #available(iOS 26.0, *) {
            navigationSubtitle(subtitle)
        } else {
            self
        }
    }

    /// Interactive Liquid Glass in `shape` (the chat's field, its jump-to-bottom button); a blurred
    /// material in the same shape before iOS 26.
    @ViewBuilder
    func interactiveGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    /// A bar at the foot that the content scrolls under (the chat's field): iOS's own on 26, a
    /// plain inset before it.
    @ViewBuilder
    func bottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom, content: bar)
        } else {
            safeAreaInset(edge: .bottom, content: bar)
        }
    }

    /// Calls `action` with whether a scroll view is more than `distance` above its end (iOS 18);
    /// before it, never: the jump-to-bottom button just does not show.
    @ViewBuilder
    func onAwayFromEnd(by distance: CGFloat, _ action: @escaping (Bool) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentSize.height + geometry.contentInsets.bottom - geometry.visibleRect.maxY > distance
            } action: { _, away in
                action(away)
            }
        } else {
            self
        }
    }
}

extension View {
    /// An iOS alert in iOS's own colours (user request 2026-11-05): no tint of ours, so iOS draws
    /// its buttons as it does in Settings (on iOS 26 ink on grey glass, red for a destructive
    /// one), not in the app's accent. An alert takes the tint of the view it hangs on, so it hangs
    /// on a clear one with the tint cleared behind this view, and the view itself keeps its
    /// colours. (Forcing `.blue` was taken back the same day: iOS 26's own alerts are not blue.)
    func systemAlert<Actions: View, Message: View>(
        _ title: String, isPresented: Binding<Bool>,
        @ViewBuilder actions: () -> Actions, @ViewBuilder message: () -> Message
    ) -> some View {
        let actions = actions(), message = message()
        return background {
            Color.clear
                .alert(title, isPresented: isPresented, actions: { actions }, message: { message })
                .tint(nil as Color?)
        }
    }

    func systemAlert<Actions: View>(
        _ title: String, isPresented: Binding<Bool>, @ViewBuilder actions: () -> Actions
    ) -> some View {
        let actions = actions()
        return background {
            Color.clear
                .alert(title, isPresented: isPresented, actions: { actions })
                .tint(nil as Color?)
        }
    }
}

/// The app's animations under Reduce Motion: none (the change shows at once), as iOS does for
/// movement it would otherwise slide, grow or fade in place (HIG; review 2026-11-07: forms, the
/// filters and the search ignored the setting). Read where the animation starts, so it works in
/// `withAnimation` and in `Binding.animation` as well as in `.animation(_:value:)`.
enum Motion {
    static func gentle(_ animation: Animation) -> Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : animation
    }
}

/// A bar button's body before iOS 26, where there is no glass: a thick material, nearly solid,
/// as the floating buttons of Photos and Maps on iOS 17 (user choice 2026-11-09: bare glyphs on
/// the sky read as no button at all). On iOS 26 the bar draws its glass and these do nothing.
extension View {
    /// A 36 circle: Q, ✎, +, the bell, search.
    @ViewBuilder
    func legacyBarCircle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            frame(width: LegacyBar.size, height: LegacyBar.size)
                .background {
                    if prominent {
                        Circle().fill(Palette.primary)
                    } else {
                        Circle().fill(.regularMaterial)
                            .overlay(Circle().strokeBorder(Palette.separator, lineWidth: 0.5))
                    }
                }
                .contentShape(Circle())
        }
    }
}

enum LegacyBar {
    /// Within iOS 17's 44 bar, with room around it.
    static let size: CGFloat = 36
    /// The sheet's ✕ and ✓, as iOS 17's own: smaller, a filled disc.
    static let sheetControl: CGFloat = 30
}

// MARK: - Vuốt ngang trong danh sách cuộn

extension View {
    /// A sideways drag on a row of a list that scrolls up and down (a row slid open on its "Xoá",
    /// `SwipeToDeleteRow`): `onChanged` with how far it has gone since it began, `onEnded` with
    /// that and its speed (points a second), also when it is cut short (speed 0).
    ///
    /// From iOS 18 it is UIKit's own pan, as iOS's rows use: it begins only when the finger moves
    /// more sideways than up or down, and once it has, the list does not take it over (user report
    /// 2026-11-17: with SwiftUI's drag the list took the touch as the finger drifted and the row
    /// jumped back). Before iOS 18, SwiftUI's drag alongside the scrolling.
    func sidewaysDrag(onChanged: @escaping (CGFloat) -> Void,
                      onEnded: @escaping (_ distance: CGFloat, _ speed: CGFloat) -> Void) -> some View {
        modifier(SidewaysDrag(onChanged: onChanged, onEnded: onEnded))
    }
}

private struct SidewaysDrag: ViewModifier {
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat, CGFloat) -> Void

    /// iOS 17: the drag under way, so one taken over by the list still ends.
    @GestureState private var dragging = false
    /// iOS 17: where a sideways drag began and how far it has gone; nil when it is not one.
    @State private var start: CGFloat?
    @State private var distance: CGFloat = 0

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(SidewaysPan(onChanged: onChanged, onEnded: onEnded))
        } else {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .updating($dragging) { _, state, _ in state = true }
                        .onChanged { value in
                            let width = value.translation.width
                            if start == nil {
                                guard abs(width) > abs(value.translation.height) else { return }
                                start = width
                            }
                            distance = width - (start ?? 0)
                            onChanged(distance)
                        }
                        .onEnded { value in
                            guard start != nil else { return }
                            start = nil
                            onEnded(distance, value.velocity.width)
                        }
                )
                .onChange(of: dragging) { _, isDragging in
                    guard !isDragging, start != nil else { return }
                    start = nil
                    onEnded(distance, 0)
                }
        }
    }
}

/// UIKit's pan for `sidewaysDrag`: it begins only on a sideways move, and counts from where it
/// began, so the row does not jump by the few points the finger moved before it did.
@available(iOS 18.0, *)
private struct SidewaysPan: UIGestureRecognizerRepresentable {
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat, CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        pan.maximumNumberOfTouches = 1
        return pan
    }

    func handleUIGestureRecognizerAction(_ pan: UIPanGestureRecognizer, context: Context) {
        let coordinator = context.coordinator
        let x = pan.translation(in: pan.view).x
        switch pan.state {
        case .began:
            coordinator.start = x
            onChanged(0)
        case .changed:
            onChanged(x - coordinator.start)
        case .ended:
            onEnded(x - coordinator.start, pan.velocity(in: pan.view).x)
        case .cancelled, .failed:
            onEnded(x - coordinator.start, 0)
        default:
            break
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var start: CGFloat = 0

        /// Sideways only: up and down stays the list's.
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return false }
            let speed = pan.velocity(in: pan.view)
            return abs(speed.x) > abs(speed.y)
        }
    }
}
