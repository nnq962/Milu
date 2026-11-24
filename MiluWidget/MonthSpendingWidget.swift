import SwiftUI
import UIKit
import WidgetKit

/// "Chi tiêu tháng này": what this month has spent against its limit, and what can still go out
/// each day (Figma "13 · Milu · Widget", 2026-11-19). Small, and medium with the three latest
/// spendings. Milu's face follows how the month goes. Its words are the app's: "hạn mức", as on
/// Tổng quan and Hạn mức chi tiêu (the Figma draft said "ngân sách").
struct MonthSpendingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetShared.monthKind, provider: MonthSpendingProvider()) { entry in
            MonthSpendingView(entry: entry)
        }
        .configurationDisplayName("Chi tiêu tháng này")
        .description("Đã chi bao nhiêu so với hạn mức tháng, còn tiêu được bao nhiêu mỗi ngày.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        // Milu sits on the widget's own bottom edge, so the margins are this view's.
        .contentMarginsDisabled()
    }
}

struct MonthSpendingEntry: TimelineEntry {
    let date: Date
    /// Nil while amounts are hidden ("Khoá bằng Face ID").
    let figures: Figures?

    struct Figures {
        var spent: Double
        /// "Hạn mức tháng"; 0 when none is set.
        var budget: Double
        var recent: [WidgetSnapshot.Spending]
    }
}

struct MonthSpendingProvider: TimelineProvider {
    /// What the widget gallery shows: the Figma example.
    static let sample = MonthSpendingEntry(date: .now, figures: .init(spent: 4_200_000, budget: 8_000_000, recent: [
        .init(title: "Cà phê", amount: 55_000, icon: nil, iconIsTemplate: false),
        .init(title: "Ăn trưa", amount: 65_000, icon: nil, iconIsTemplate: false),
        .init(title: "Grab", amount: 32_000, icon: nil, iconIsTemplate: false),
    ]))

    func placeholder(in context: Context) -> MonthSpendingEntry { Self.sample }

    func getSnapshot(in context: Context, completion: @escaping (MonthSpendingEntry) -> Void) {
        completion(context.isPreview && WidgetShared.read() == nil ? Self.sample : entry(at: .now))
    }

    /// Now, and again at midnight: "mỗi ngày" changes with the day, and the first of a month
    /// starts from nothing. The app asks for a new timeline whenever a figure changes.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthSpendingEntry>) -> Void) {
        let now = Date.now
        let calendar = Calendar.current
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        completion(Timeline(entries: [entry(at: now), entry(at: midnight)], policy: .atEnd))
    }

    private func entry(at date: Date) -> MonthSpendingEntry {
        guard let snapshot = WidgetShared.read() else {
            return MonthSpendingEntry(date: date, figures: .init(spent: 0, budget: 0, recent: []))
        }
        guard !snapshot.hidesAmounts else { return MonthSpendingEntry(date: date, figures: nil) }
        return MonthSpendingEntry(date: date, figures: .init(spent: snapshot.spentThisMonth(on: date),
                                                             budget: snapshot.monthlyBudget,
                                                             recent: snapshot.recent(on: date)))
    }
}

/// How the month stands, as the widget words and colours it.
struct MonthStanding {
    let date: Date
    let figures: MonthSpendingEntry.Figures?

    enum State { case hidden, noLimit, within, nearing, over }

    var progress: BudgetProgress? {
        guard let figures, figures.budget > 0 else { return nil }
        return BudgetProgress(limit: figures.budget, spent: figures.spent)
    }

    var state: State {
        guard figures != nil else { return .hidden }
        guard let progress else { return .noLimit }
        return progress.isOver ? .over : progress.isNearing ? .nearing : .within
    }

    /// "ĐÃ CHI THÁNG 11".
    var heading: String { "ĐÃ CHI THÁNG \(Calendar.current.component(.month, from: date))" }

    var spentText: String { figures.map { $0.spent.vndCompact } ?? "•••" }

    var limitText: String? { progress.map { "/ \($0.limit.vndCompact)" } }

    /// The state's colour: the bar, the first line and the percent (amber from 80%, red over, as
    /// Hạn mức chi tiêu).
    var ink: Color {
        switch state {
        case .nearing: Palette.warning
        case .over: Palette.negative
        default: Palette.progress
        }
    }

    var firstLine: String {
        switch state {
        case .hidden: "Đang ẩn số tiền"
        case .noLimit: "Chưa đặt hạn mức"
        case .over: "Vượt \((-(progress?.left ?? 0)).vndCompact)"
        case .within, .nearing: "Còn \((progress?.left ?? 0).vndCompact)"
        }
    }

    var firstLineInk: Color {
        switch state {
        case .nearing: Palette.warning
        case .over: Palette.negative
        default: Palette.label
        }
    }

    var secondLine: String {
        switch state {
        case .hidden: return "Chạm để mở Milu"
        case .noLimit: return "Chạm để đặt"
        case .over: return "Đã quá hạn mức tháng"
        case .within, .nearing:
            guard let daily = progress?.dailyAllowance(in: date, today: date) else { return "Đã dùng hết hạn mức" }
            return "~\(daily.vndCompact) mỗi ngày"
        }
    }

    var secondLineInk: Color { state == .noLimit ? Palette.primary : Palette.secondaryLabel }

    /// Milu's face for the month (Figma board 3).
    var face: String {
        switch state {
        case .hidden: "MiluWink"
        case .noLimit: "MiluCurious"
        case .within: "MiluHappy"
        case .nearing: "MiluFlustered"
        case .over: "MiluSad"
        }
    }

    /// Where a tap goes: Hạn mức chi tiêu to set a limit, Tổng quan otherwise.
    var link: WidgetShared.Link { state == .noLimit ? .budget : .overview }
}

struct MonthSpendingView: View {
    let entry: MonthSpendingEntry
    @Environment(\.widgetFamily) private var family

    /// Milu's width; its height follows the drawing (320 × 140). 64, not Figma's 70: on a 164pt
    /// widget (iPhone 17 Pro) 70 left its ears 2pt under "Đã quá hạn mức tháng".
    private static let faceWidth: CGFloat = 64
    /// The widget's padding, and Milu's distance from the right edge: clear of the rounded corner.
    private static let padding: CGFloat = 16
    private static let faceInset: CGFloat = 26
    /// The medium widget's left column.
    private static let columnWidth: CGFloat = 150

    var body: some View {
        let standing = MonthStanding(date: entry.date, figures: entry.figures)
        switch family {
        case .accessoryCircular:
            LockMonthRing(standing: standing)
                .containerBackground(for: .widget) { AccessoryWidgetBackground() }
                .widgetURL(standing.link.url)
        case .accessoryRectangular:
            LockMonthLines(standing: standing)
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(standing.link.url)
        default:
            homeScreen(standing)
        }
    }

    private func homeScreen(_ standing: MonthStanding) -> some View {
        Group {
            if family == .systemMedium {
                HStack(alignment: .top, spacing: Self.padding) {
                    MonthFigures(standing: standing).frame(width: Self.columnWidth, alignment: .leading)
                    Rectangle().fill(Palette.separator).frame(width: 1)
                    RecentSpending(standing: standing)
                }
                .padding(Self.padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                // Under the left column, its right side lined up with the column's.
                .overlay(alignment: .bottomLeading) {
                    face(standing).padding(.leading, Self.padding + Self.columnWidth - Self.faceWidth)
                }
            } else {
                MonthFigures(standing: standing)
                    .padding(Self.padding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .overlay(alignment: .bottomTrailing) {
                        face(standing).padding(.trailing, Self.faceInset)
                    }
            }
        }
        .containerBackground(Palette.surface, for: .widget)
        .widgetURL(standing.link.url)
    }

    /// Milu with its flat bottom on the widget's bottom edge: a head with no body never floats
    /// (user note 2026-11-19).
    private func face(_ standing: MonthStanding) -> some View {
        Image(standing.face)
            .miluFullColor()
            .scaledToFit()
            .frame(width: Self.faceWidth)
            .accessibilityHidden(true)
    }
}

/// The month's figures: spent against the limit, the bar, what is left.
private struct MonthFigures: View {
    let standing: MonthStanding

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(standing.heading)
                    .font(WidgetFont.rounded(11, .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Palette.secondaryLabel)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(standing.spentText)
                        .font(WidgetFont.rounded(32, .heavy))
                        .foregroundStyle(standing.state == .hidden ? Palette.tertiaryLabel : Palette.label)
                        .widgetAccentable()
                    if let limit = standing.limitText {
                        Text(limit)
                            .font(WidgetFont.rounded(13, .semibold))
                            .foregroundStyle(Palette.tertiaryLabel)
                    }
                }
                .privacySensitive()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            VStack(alignment: .leading, spacing: 5) {
                if standing.state != .noLimit { bar }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        if standing.state == .hidden {
                            Image("hugeicons-square-lock-02")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundStyle(Palette.label)
                        }
                        Text(standing.firstLine)
                            .font(WidgetFont.rounded(15, .heavy))
                            .foregroundStyle(standing.firstLineInk)
                            .privacySensitive()
                        Spacer(minLength: 4)
                        if let progress = standing.progress {
                            Text(progress.percentText)
                                .font(WidgetFont.rounded(13, .bold))
                                .foregroundStyle(standing.state == .within ? Palette.secondaryLabel : standing.ink)
                                .privacySensitive()
                        }
                    }
                    Text(standing.secondLine)
                        .font(WidgetFont.rounded(12, .semibold))
                        .foregroundStyle(standing.secondLineInk)
                        .privacySensitive()
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
    }

    /// The share of the limit used, full once over; an empty track while amounts are hidden.
    private var bar: some View {
        let used = min(max(standing.progress?.ratio ?? 0, 0), 1)
        return Capsule()
            .fill(Palette.progressTrack)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    if used > 0 {
                        Capsule()
                            .fill(standing.ink)
                            .frame(width: max(6, proxy.size.width * used))
                            .widgetAccentable()
                    }
                }
            }
    }
}

/// "Gần đây": the month's three latest spendings.
private struct RecentSpending: View {
    let standing: MonthStanding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GẦN ĐÂY")
                .font(WidgetFont.rounded(11, .heavy))
                .tracking(1.2)
                .foregroundStyle(Palette.secondaryLabel)
            if let figures = standing.figures {
                if figures.recent.isEmpty {
                    Text("Chưa có khoản chi nào trong tháng.")
                        .font(WidgetFont.rounded(12, .semibold))
                        .foregroundStyle(Palette.secondaryLabel)
                } else {
                    ForEach(Array(figures.recent.enumerated()), id: \.offset) { _, line in row(line) }
                }
            } else {
                // Hidden: not even what was bought shows on the home screen.
                Text("Mở Milu để xem.")
                    .font(WidgetFont.rounded(12, .semibold))
                    .foregroundStyle(Palette.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ line: WidgetSnapshot.Spending) -> some View {
        HStack(spacing: 8) {
            icon(line).frame(width: 24, height: 24)
            Text(line.title)
                .font(WidgetFont.rounded(13, .semibold))
                .foregroundStyle(Palette.label)
            Spacer(minLength: 4)
            Text("−" + line.amount.vndCompact)
                .font(WidgetFont.rounded(13, .bold))
                .foregroundStyle(Palette.negative)
        }
        .lineLimit(1)
        .privacySensitive()
    }

    /// The category's icon, as the app drew it into the shared folder; a quiet dot without one.
    @ViewBuilder
    private func icon(_ line: WidgetSnapshot.Spending) -> some View {
        if let name = line.icon, let url = WidgetShared.iconURL(name), let image = UIImage(contentsOfFile: url.path()) {
            Image(uiImage: image)
                .renderingMode(line.iconIsTemplate ? .template : .original)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Palette.icon)
        } else {
            Circle().fill(Palette.surfaceMuted)
        }
    }
}

#Preview("Nhỏ", as: .systemSmall) {
    MonthSpendingWidget()
} timeline: {
    MonthSpendingProvider.sample
    MonthSpendingEntry(date: .now, figures: .init(spent: 6_600_000, budget: 8_000_000, recent: []))
    MonthSpendingEntry(date: .now, figures: .init(spent: 8_600_000, budget: 8_000_000, recent: []))
    MonthSpendingEntry(date: .now, figures: .init(spent: 4_200_000, budget: 0, recent: []))
    MonthSpendingEntry(date: .now, figures: nil)
}

// MARK: - Màn hình khoá

/// The lock screen draws in one tint over the wallpaper, so no Milu colours and no Milu: the
/// state reads from the words ("Còn", "Vượt"), never from amber or red (Figma board 2).

/// Round: the share of the limit used, as a ring.
private struct LockMonthRing: View {
    let standing: MonthStanding

    var body: some View {
        switch standing.state {
        case .hidden:
            Image("hugeicons-square-lock-02")
                .resizable()
                .frame(width: 22, height: 22)
                .accessibilityLabel("Đang ẩn số tiền")
        case .noLimit:
            // No limit to measure against: the month's spending itself.
            VStack(spacing: 0) {
                Text(standing.spentText)
                    .font(WidgetFont.rounded(14, .heavy))
                    .privacySensitive()
                Text("đã chi")
                    .font(WidgetFont.rounded(10, .bold))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 6)
        default:
            let progress = standing.progress
            Gauge(value: min(max(progress?.ratio ?? 0, 0), 1)) {
                Text("Hạn mức tháng")
            } currentValueLabel: {
                VStack(spacing: -2) {
                    Text(progress?.percentText ?? "")
                        .font(WidgetFont.rounded(15, .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .privacySensitive()
                    Text(standing.state == .over ? "vượt" : "đã chi")
                        .font(WidgetFont.rounded(9, .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        }
    }
}

/// Rectangular: the month in four short lines.
private struct LockMonthLines: View {
    let standing: MonthStanding

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(heading)
                .font(WidgetFont.rounded(11, .heavy))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                if standing.state == .hidden {
                    Image("hugeicons-square-lock-02").resizable().frame(width: 14, height: 14)
                }
                Text(main)
                    .font(WidgetFont.rounded(16, .heavy))
                    .privacySensitive()
                    .widgetAccentable()
            }
            if let progress = standing.progress {
                Gauge(value: min(max(progress.ratio, 0), 1)) { EmptyView() }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .widgetAccentable()
            }
            Text(detail)
                .font(WidgetFont.rounded(12, .semibold))
                .foregroundStyle(.secondary)
                .privacySensitive()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "THÁNG 11 · ĐÃ CHI 52%".
    private var heading: String {
        let month = "THÁNG \(Calendar.current.component(.month, from: standing.date))"
        guard let progress = standing.progress else { return month }
        return "\(month) · ĐÃ CHI \(progress.percentText)"
    }

    private var main: String {
        standing.state == .noLimit ? "Đã chi \(standing.spentText)" : standing.firstLine
    }

    private var detail: String {
        switch standing.state {
        case .hidden: "Mở Milu để xem"
        case .noLimit: "Chưa đặt hạn mức"
        default: standing.secondLine
        }
    }
}

#Preview("Khoá · tròn", as: .accessoryCircular) {
    MonthSpendingWidget()
} timeline: {
    MonthSpendingProvider.sample
    MonthSpendingEntry(date: .now, figures: .init(spent: 8_600_000, budget: 8_000_000, recent: []))
    MonthSpendingEntry(date: .now, figures: .init(spent: 4_200_000, budget: 0, recent: []))
    MonthSpendingEntry(date: .now, figures: nil)
}

#Preview("Khoá · chữ nhật", as: .accessoryRectangular) {
    MonthSpendingWidget()
} timeline: {
    MonthSpendingProvider.sample
    MonthSpendingEntry(date: .now, figures: .init(spent: 8_600_000, budget: 8_000_000, recent: []))
    MonthSpendingEntry(date: .now, figures: .init(spent: 4_200_000, budget: 0, recent: []))
    MonthSpendingEntry(date: .now, figures: nil)
}

#Preview("Vừa", as: .systemMedium) {
    MonthSpendingWidget()
} timeline: {
    MonthSpendingProvider.sample
}
