import SwiftUI

/// "Làm quen với Timi": four first steps, ticked from what is really in the app, shown one at a
/// time (user review 2026-11-02: the list was not lively, and nothing in it could be done from
/// there). The next step's 3D picture (Fluent Emoji), "LÀM QUEN · +5 LƯỢT AI",
/// its name and one line on why, a lime button that does it, and four short bars filling in as
/// the steps are done. It goes away once all four are done.
struct OnboardingCard: View {
    enum Step: CaseIterable {
        case account, transaction, loan, askAI

        var title: String {
            switch self {
            case .account: "Thêm tài khoản đầu tiên"
            case .transaction: "Ghi một khoản thu chi"
            case .loan: "Ghi một khoản cho vay"
            case .askAI: "Hỏi Timi một câu"
            }
        }

        var detail: String {
            switch self {
            case .account: "Ngân hàng, ví hay tiền mặt: Timi cộng lại thành tài sản của bạn."
            case .transaction: "Một ly cà phê cũng được, để Timi bắt đầu hiểu bạn."
            case .loan: "Ai đang nợ bạn? Timi nhắc giúp khi tới hạn."
            case .askAI: "Thử hỏi \"Tháng này tôi tiêu gì nhiều nhất?\""
            }
        }

        var action: String {
            switch self {
            case .account: "Thêm tài khoản"
            case .transaction: "Ghi khoản đầu tiên"
            case .loan: "Ghi khoản cho vay"
            case .askAI: "Hỏi Timi"
            }
        }

        /// The `Fluent3D` picture.
        var picture: String {
            switch self {
            case .account: "fluent-bank"
            case .transaction: "fluent-memo"
            case .loan: "fluent-handshake"
            case .askAI: "fluent-sparkles"
            }
        }
    }

    /// Does a step: opens what it asks for.
    let onStep: (Step) -> Void

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    /// The step's picture; it grows with the words beside it.
    @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = RowMetrics.picture

    /// The steps done, by name; each pays its +5 lượt AI once (`AIQuota.claim`).
    static func completedSteps(_ store: FinanceStore, askedAI: Bool) -> [String] {
        [("account", !store.accounts.isEmpty), ("transaction", !store.transactions.isEmpty),
         ("loan", !store.loans.isEmpty), ("askAI", askedAI)].filter(\.1).map(\.0)
    }

    private func isDone(_ step: Step) -> Bool {
        switch step {
        case .account: !store.accounts.isEmpty
        case .transaction: !store.transactions.isEmpty
        case .loan: !store.loans.isEmpty
        case .askAI: hasAskedAI
        }
    }

    var body: some View {
        let steps = Step.allCases
        let done = steps.map(isDone)
        if let index = done.firstIndex(of: false) {
            let step = steps[index]
            VStack(alignment: .leading, spacing: Spacing.l) {
                // 12 from picture to words, as the insights under it, so the words line up too.
                HStack(alignment: .top, spacing: Spacing.m) {
                    Image(step.picture)
                        .resizable()
                        .scaledToFit()
                        // On nothing, as the insights' pictures (2026-11-03: no pale tiles).
                        .frame(width: tileSize, height: tileSize)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Small capitals, as every label over a title on this page (TIMI PRO, ĂN UỐNG);
                        // no "bước 4/4", the bars under the button say it (user review 2026-11-02).
                        Text("LÀM QUEN · +5 LƯỢT AI")
                            .textRole(.overline)
                            .foregroundStyle(Palette.secondaryLabel)
                        Text(step.title)
                            .textRole(.title)
                            .foregroundStyle(Palette.label)
                        Text(step.detail)
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                TimiButton(step.action, role: .primary, fullWidth: true) { onStep(step) }
                // One short bar a step, ink once done, in the steps' order.
                HStack(spacing: Spacing.xs) {
                    ForEach(done.indices, id: \.self) { i in
                        Capsule()
                            .fill(done[i] ? Palette.progress : Palette.progressTrack)
                            .frame(height: Spacing.xs)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Xong \(done.filter { $0 }.count) trên \(steps.count) bước")
            }
            // 16 inside, as the rows of "Timi nhận thấy" under it, so the two pictures stand on one
            // edge (user report 2026-11-02: the card's 20 set this one 4pt further in).
            .card(padding: RowMetrics.horizontal)
            // The next step comes in as one is done (a moment seen four times at most).
            .id(step)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }
}
