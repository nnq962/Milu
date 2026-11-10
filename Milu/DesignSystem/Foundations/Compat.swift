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

    /// A 36 capsule with words in it: "Hỏi Milu".
    @ViewBuilder
    func legacyBarPill() -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            padding(.horizontal, Spacing.m)
                .frame(height: LegacyBar.size)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.separator, lineWidth: 0.5))
                .contentShape(Capsule())
        }
    }
}

enum LegacyBar {
    /// Within iOS 17's 44 bar, with room around it.
    static let size: CGFloat = 36
    /// The sheet's ✕ and ✓, as iOS 17's own: smaller, a filled disc.
    static let sheetControl: CGFloat = 30
}
