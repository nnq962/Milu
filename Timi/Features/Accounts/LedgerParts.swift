import SwiftUI

/// One wallet or bank in Sổ ví (Milu "Sổ ví / Dòng tài khoản", Figma 58:828): its logo or kind
/// in a 32pt tile, the name over its kind, the balance on the right, then ›. 54 tall at least; at
/// accessibility text sizes the balance goes under the name, whole, never shortened (Milu: no
/// "tr"/"k" in money labels).
struct WalletRow: View {
    let account: Account

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Where the hairline between rows starts: the column of the names (12 + 32 + 10).
    static let textColumn: CGFloat = 54
    static let logo: CGFloat = 32

    var body: some View {
        HStack(spacing: 10) {
            WalletMark(account: account)
            // Name and balance side by side while the name fits whole; else the balance under the
            // name (HIG review 2026-11-05: at XXXL "Vietcombank" broke as "Vietcomban / k"). From
            // XXXL every row stacks, so one list never mixes the two (second review 2026-11-05).
            if typeSize >= .xxxLarge {
                stacked
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.s) {
                        names
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        balance
                            .fixedSize()
                    }
                    stacked
                }
            }
            // 12 at the default size, growing with the text (it stood 12 beside AX5 names).
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.tertiaryLabel)
                .accessibilityHidden(true)
        }
        .padding(.leading, Spacing.m)
        .padding(.trailing, 14)
        .padding(.vertical, Spacing.s)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityHint("Xem ví")
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            names
            balance
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var names: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(account.name)
                .textRole(.bodyStrong)
                .foregroundStyle(Palette.label)
            Text(account.isLocked ? "\(account.type.title) · Đã khoá" : account.type.title)
                .textRole(.footnote)
                .foregroundStyle(Palette.secondaryLabel)
        }
    }

    private var balance: some View {
        // Whole, in ink (red with "−" below zero); grey once locked, as it no longer counts.
        Text(signed(account.balance))
            .textRole(.amount)
            .tracking(-0.25)
            .foregroundStyle(account.isLocked ? Palette.secondaryLabel
                             : account.balance < 0 ? Palette.expense : Palette.label)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private func signed(_ amount: Double) -> String {
        (amount < 0 ? "\u{2212}" : "") + abs(amount).vnd
    }

    /// "Ví tiền mặt, số dư hai triệu ba trăm năm mươi nghìn đồng" (Milu's own example).
    private var spoken: String {
        let figure = (account.balance < 0 ? "trừ " : "") + MoneyText.spoken(abs(account.balance))
        return [account.name, "số dư \(figure)", account.isLocked ? "đã khoá" : nil]
            .compactMap { $0 }.joined(separator: ", ")
    }
}

/// A wallet's mark in Sổ ví: the bank's or e-wallet's own logo on a white tile, or the kind's
/// Fluent Flat picture on nothing (Milu "Emoji · Tiền mặt" 💵, Figma 2026-11-05; 🏦 and 📱 for a
/// bank or e-wallet with no logo), 32 square.
struct WalletMark: View {
    let account: Account

    @ScaledMetric(relativeTo: .body) private var scaled = WalletRow.logo

    var body: some View {
        let size = RowMetrics.capped(scaled, base: WalletRow.logo)
        Group {
            if let logo = account.institution?.logoImage {
                InstitutionLogo(image: logo, size: size)
            } else {
                Image(IconCatalog.emojiName(emoji))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if account.isLocked {
                LockBadge().offset(x: AccountRow.lockOverhang, y: AccountRow.lockOverhang)
            }
        }
        .accessibilityHidden(true)
    }

    private var emoji: String {
        switch account.type {
        case .cash: "💵"
        case .bank: "🏦"
        case .eWallet: "📱"
        case .credit: "💳"
        }
    }
}

/// A savings goal as a glass jar in Sổ ví (Milu "Hũ theo mục tiêu", Figma 79:1401, 2026-11-05):
/// the jar filled to the share saved, the goal's picture in the water, then centred the name on
/// two lines, the percent in deep blue, what is saved and, under it, the target. The water takes
/// turns: mint, sky, honey. Once reached the jar is full to its neck and "100%" is green; past its date
/// the percent is red. Where the figures do not fit, the jar keeps name and percent; the goal's
/// sheet has them whole.
struct GoalJar: View {
    let goal: SavingsGoal
    let water: Color

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var jarWidth: CGFloat = 94
    /// Two lines of the name (14 on a 17 line).
    @ScaledMetric(relativeTo: .subheadline) private var nameHeight: CGFloat = 34

    private static let radius: CGFloat = 15

    var body: some View {
        let done = goal.isReached || goal.isClosed
        let width = RowMetrics.capped(jarWidth, base: 94)
        let oneColumn = typeSize >= .accessibility3
        VStack(spacing: 0) {
            // As wide as Figma's 94, growing with the text, but never past its column: at XXXL the
            // grown jar pushed the stamps over the page's margins (HIG review 2026-11-05).
            GlassJar(level: done ? 1 : goal.progress, water: water, picture: GoalArtwork.name(for: goal.icon))
                .aspectRatio(1 / GlassJar.aspect, contentMode: .fit)
                .frame(maxWidth: width)
                .accessibilityHidden(true)
            // Two lines of 17 whatever the name, so the percents of a row line up (Figma: 34 tall).
            Text(goal.name)
                .font(Typography.font(.subheadline, size: 14, weight: .heavy))
                .designLineHeight(17, relativeTo: .subheadline)
                .foregroundStyle(Palette.label)
                .multilineTextAlignment(.center)
                .lineLimit(oneColumn ? nil : 2)
                .frame(minHeight: oneColumn ? nil : nameHeight)
                .fixedSize(horizontal: false, vertical: true)
            Group {
                // Reached: the percent itself, in green (user 2026-11-05: "✓ Đã đạt" read too large).
                if done {
                    Text(goal.isReached ? "100%" : goal.progressText)
                        .foregroundStyle(Palette.progressDone)
                } else {
                    Text(goal.progressText)
                        .foregroundStyle(goal.isOverdue ? Palette.negative : Palette.deep)
                }
            }
            .textRole(.heading)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            ViewThatFits(in: .horizontal) {
                VStack(spacing: 1) {
                    Text(goal.saved.vnd)
                        .font(Typography.font(.footnote, size: 13, weight: .bold))
                        .foregroundStyle(Palette.label)
                    Text("/ \(goal.target.vnd)")
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                .monospacedDigit()
                .fixedSize()
                EmptyView()
            }
            .padding(.top, Spacing.xxs)
            Spacer(minLength: 0)
        }
        .padding(.top, Spacing.s)
        .padding(.bottom, 10)
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity)
        .cardSurface(radius: Self.radius)
        .contentShape(RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken(done: done))
        .accessibilityHint("Xem hũ")
    }

    /// "Du lịch Đà Nẵng, đã góp tám triệu đồng trên hai mươi triệu đồng, 40 phần trăm".
    private func spoken(done: Bool) -> String {
        let percent = Int((goal.progress * 100).rounded(.down))
        return [goal.name,
                "đã góp \(MoneyText.spoken(goal.saved)) trên \(MoneyText.spoken(goal.target))",
                done ? "đã đạt" : "\(percent) phần trăm",
                goal.isOverdue && !done ? "quá hạn" : nil]
            .compactMap { $0 }.joined(separator: ", ")
    }
}

/// Milu's glass jar, drawn on its 94 × 70 frame and scaled: the glass, the water from the bottom
/// up to `level` (65 empty, 48 a whole, as Figma's 70% at 31.4), the picture in it, the outline
/// and the lid. A full jar fills on up the neck to the lid (`full`, user 2026-11-05: at 17 the full
/// jar read short of full). The water's rise is animated once as the jar shows (none with Reduce Motion).
struct GlassJar: View {
    let level: Double
    let water: Color
    let picture: String

    static let aspect: CGFloat = 70 / 94
    private static let size = CGSize(width: 94, height: 70)
    /// The level a full jar's water rises to: 65 − 48 × 1.15 ≈ 10, the top of the neck.
    private static let full: Double = 1.15
    /// What the water rises to: the share saved, or to the neck once full.
    private var target: Double { level >= 1 ? Self.full : level }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / Self.size.width
            let sy = proxy.size.height / Self.size.height
            let fill = min(max(shown, 0), Self.full)
            let waterTop = 65 - 48 * fill
            ZStack(alignment: .topLeading) {
                JarBody().fill(Palette.jarGlass)
                // The water fills the jar's whole frame from `waterTop` down, then the glass cuts it,
                // so its shoulders and round foot follow the jar.
                VStack(spacing: 0) {
                    Color.clear.frame(height: waterTop * sy)
                    water
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(JarBody())
                Image(picture)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30 * sx, height: 30 * sx)
                    .offset(x: 32 * sx, y: 25 * sy)
                JarBody().stroke(Palette.jarOutline, style: StrokeStyle(lineWidth: 1.35, lineJoin: .round))
                Capsule()
                    .fill(Palette.jarLid)
                    .overlay(Capsule().stroke(Palette.jarOutline, lineWidth: 1.3))
                    .frame(width: 43 * sx, height: 7 * sy)
                    .offset(x: 25.5 * sx, y: 4 * sy)
            }
        }
        .onAppear {
            guard shown != target else { return }
            if reduceMotion { shown = target } else {
                withAnimation(.easeOut(duration: 0.7).delay(0.1)) { shown = target }
            }
        }
        .onChange(of: level) {
            withAnimation(reduceMotion ? nil : .smooth) { shown = target }
        }
    }
}

/// The jar's glass: a neck from 28 to 66, shoulders out to 17 and 77, a round foot at 66 (Figma's
/// "Thủy tinh" path on 94 × 70).
private struct JarBody: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 94, sy = rect.height / 70
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var path = Path()
        path.move(to: p(28, 10))
        path.addLine(to: p(66, 10))
        path.addLine(to: p(66, 15))
        path.addCurve(to: p(71, 21), control1: p(66, 18), control2: p(68, 19))
        path.addCurve(to: p(77, 33), control1: p(75, 24), control2: p(77, 28))
        path.addLine(to: p(77, 56))
        path.addCurve(to: p(67, 66), control1: p(77, 62), control2: p(73, 66))
        path.addLine(to: p(27, 66))
        path.addCurve(to: p(17, 56), control1: p(21, 66), control2: p(17, 62))
        path.addLine(to: p(17, 33))
        path.addCurve(to: p(23, 21), control1: p(17, 28), control2: p(19, 24))
        path.addCurve(to: p(28, 15), control1: p(26, 19), control2: p(28, 18))
        path.closeSubpath()
        return path
    }
}
