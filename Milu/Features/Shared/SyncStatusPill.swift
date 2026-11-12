import SwiftUI

/// A small pill above the tab bar while data comes down from iCloud (user request 2026-11-12:
/// opening the app said nothing about syncing, and after a reinstall the app looked empty for
/// half a minute while the data came back). It waits a moment before showing, so a quick sync
/// shows nothing, and once one it showed is done it says so briefly. Sending changes up is not
/// shown. Cài đặt → Đồng bộ iCloud has the full state.
struct SyncStatusPill: ViewModifier {
    @Environment(CloudSyncMonitor.self) private var sync
    @Environment(FinanceStore.self) private var store

    @State private var timeline = SyncPillTimeline()
    @State private var timer: Task<Void, Never>?

    /// Nothing recorded yet: the data is on its way back (a reinstall, a new iPhone).
    private var isRestoring: Bool {
        store.accounts.isEmpty && store.archivedAccounts.isEmpty && store.savingsGoals.isEmpty && store.transactions.isEmpty
    }

    /// The words while receiving, chosen before the pill appears and kept: data arriving would
    /// otherwise turn "Đang lấy dữ liệu…" into "Đang đồng bộ…" halfway.
    @State private var receivingText = "Đang đồng bộ với iCloud…"

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                // Drawn and moved by UIKit, so the main thread being busy with the sync does not
                // stall it (`SyncPillUIView`). Always there, so it can play its way out.
                SyncPillRepresentable(shown: timeline.shown, text: label)
                    .frame(height: 64)
                    .padding(.bottom, Self.aboveTabBar)
                    .allowsHitTesting(false)
                    .accessibilityHidden(timeline.shown == nil)
            }
            .onChange(of: sync.isReceiving, initial: true) { _, receiving in
                if receiving, timeline.shown == nil {
                    receivingText = isRestoring ? "Đang lấy dữ liệu từ iCloud…" : "Đang đồng bộ với iCloud…"
                }
                run(timeline.receivingChanged(receiving))
            }
    }

    /// Waits for the step `timeline` asked for, then tells it; a newer step replaces it.
    private func run(_ step: SyncPillTimeline.Step) {
        timer?.cancel()
        guard let delay = step.delay else { return }
        timer = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            run(timeline.fired(step, receiving: sync.isReceiving))
        }
    }

    /// Clear of the tab bar and the + beside it (the pill sits at the bottom of its 64-point band).
    private static let aboveTabBar: CGFloat = 76

    private var label: String {
        timeline.shown == .done ? "Đã đồng bộ" : receivingText
    }
}

/// When the pill shows and goes, apart from the screen so it can be tested. Every change of
/// "receiving" either schedules the next step or ends what is shown; nothing can be left on screen
/// (iPhone test 2026-11-12: bursts of syncs left "Đã đồng bộ" up for good), and the spinner gives
/// up after `longest` should the end of a sync never be heard (the app was suspended mid-sync).
/// A restore comes down in several rounds with short gaps between: "Đã đồng bộ" waits until no
/// round has started for `settle`, so the pill does not flip between the two (iPhone test
/// 2026-11-12, after a reinstall).
struct SyncPillTimeline {
    enum Shown: Hashable { case receiving, done }

    enum Step: Equatable {
        case none, show, settle, hide, giveUp

        var delay: Duration? {
            switch self {
            case .none: nil
            case .show: SyncPillTimeline.wait
            case .settle: SyncPillTimeline.settle
            case .hide: SyncPillTimeline.linger
            case .giveUp: SyncPillTimeline.longest
            }
        }
    }

    /// A sync done within this shows nothing.
    static let wait = Duration.milliseconds(800)
    /// Quiet this long after a round before "Đã đồng bộ".
    static let settle = Duration.seconds(2)
    /// How long "Đã đồng bộ" stays.
    static let linger = Duration.seconds(1.6)
    static let longest = Duration.seconds(20)

    private(set) var shown: Shown?

    mutating func receivingChanged(_ receiving: Bool) -> Step {
        if receiving {
            guard shown != nil else { return .show }
            shown = .receiving
            return .giveUp
        }
        switch shown {
        case nil: return .none
        case .receiving: return .settle
        case .done: return .hide
        }
    }

    mutating func fired(_ step: Step, receiving: Bool) -> Step {
        switch step {
        case .show:
            guard receiving else { return .none }
            shown = .receiving
            return .giveUp
        case .settle:
            guard !receiving else { return .giveUp }
            shown = .done
            return .hide
        case .hide, .giveUp:
            shown = nil
            return .none
        case .none:
            return .none
        }
    }
}

extension View {
    func syncStatusPill() -> some View { modifier(SyncStatusPill()) }
}
