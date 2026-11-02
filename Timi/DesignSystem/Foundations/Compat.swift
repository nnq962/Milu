import SwiftUI

/// iOS 17 to 25 stand-ins for what Timi draws with iOS 26 (user request 2026-11-02: the app runs
/// from iOS 17 again, for an iPhone on 17.6). On iOS 26 each one is the real thing; before it, the
/// nearest plain look: no Liquid Glass, no scroll-edge effect, no subtitle under a bar title.
extension View {
    /// `scrollEdgeEffectHidden` where iOS has the scroll-edge effect (26); nothing to hide before.
    @ViewBuilder
    func scrollEdgeEffectHiddenIfAvailable(_ hidden: Bool = true) -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(hidden, for: .all)
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
