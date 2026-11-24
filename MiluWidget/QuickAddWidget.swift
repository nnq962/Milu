import SwiftUI
import WidgetKit

/// "Ghi nhanh": from the home screen to a recorded spending in one tap (Figma "13 · Milu ·
/// Widget", 2026-11-19). "Thêm" opens Thêm giao dịch, "Nói với Milu" opens Thêm bằng AI, which
/// listens at once; above them, what was spent today, so the widget is worth a look untapped.
struct QuickAddWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetShared.quickAddKind, provider: QuickAddProvider()) { entry in
            QuickAddView(entry: entry)
        }
        .configurationDisplayName("Ghi nhanh")
        .description("Thêm một khoản chi, hoặc nói với Milu, chỉ một chạm.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

/// The lock screen's "Ghi nhanh": a "+" that opens Thêm giao dịch once the iPhone is unlocked
/// (Figma board 1). No amount: the lock screen is seen by anyone.
private struct LockQuickAdd: View {
    var body: some View {
        ZStack {
            // A faint disc of its own: iOS 26 draws none behind a lock screen widget, and a bare
            // "+" did not read as a button (simulator check 2026-11-19).
            Circle().fill(.white.opacity(0.18))
            Image("hugeicons-add-01")
                .resizable()
                .frame(width: 30, height: 30)
                .widgetAccentable()
        }
        .accessibilityElement()
        .accessibilityLabel("Thêm giao dịch")
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        .widgetURL(WidgetShared.Link.add.url)
    }
}

struct QuickAddEntry: TimelineEntry {
    let date: Date
    /// Today's spending ("185k"); nil when amounts are hidden (Face ID lock on) or not known yet.
    let spentText: String?
}

struct QuickAddProvider: TimelineProvider {
    /// What the widget gallery and the first frame show.
    private static let sample = QuickAddEntry(date: .now, spentText: "185k")

    func placeholder(in context: Context) -> QuickAddEntry { Self.sample }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> Void) {
        completion(context.isPreview ? Self.sample : entry(at: .now))
    }

    /// Now, and again at midnight, when today's spending starts from nothing. The app asks for a
    /// new timeline whenever the figure changes (`WidgetShared.write`).
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        let now = Date.now
        let calendar = Calendar.current
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        completion(Timeline(entries: [entry(at: now), entry(at: midnight)], policy: .atEnd))
    }

    private func entry(at date: Date) -> QuickAddEntry {
        guard let snapshot = WidgetShared.read(), !snapshot.hidesAmounts else { return QuickAddEntry(date: date, spentText: nil) }
        return QuickAddEntry(date: date, spentText: snapshot.spentToday(on: date).vndCompact)
    }
}

struct QuickAddView: View {
    let entry: QuickAddEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if family == .accessoryCircular { LockQuickAdd() } else { QuickAddHome(entry: entry) }
    }
}

private struct QuickAddHome: View {
    let entry: QuickAddEntry

    /// Milu over "Thêm", and its distance from the button's right end: inside the button's straight
    /// top edge, clear of its round end (the button is 42 high).
    private static let faceWidth: CGFloat = 54
    private static let faceInset: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("HÔM NAY ĐÃ CHI")
                    .font(WidgetFont.rounded(11, .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Palette.secondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                // Hidden as on "Chi tiêu tháng này". Kept left of Milu, who sits on the same line:
                // "Ghi nhanh" and a "1,3tr" ran under its head (simulator check 2026-11-19).
                Text(entry.spentText ?? "•••")
                    .font(WidgetFont.rounded(21, .black))
                    .foregroundStyle(entry.spentText == nil ? Palette.tertiaryLabel : Palette.label)
                    .privacySensitive()
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.trailing, Self.faceInset + Self.faceWidth + 4)
            }
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                WidgetButton(title: "Thêm", icon: "hugeicons-add-01", link: .add, isPrimary: true)
                    // Milu peeks over "Thêm": its flat bottom tucked 2pt under the button's
                    // straight top edge, clear of the round ends (a head with no body never
                    // floats, user note 2026-11-19).
                    .background(alignment: .topTrailing) {
                        Image("MiluFriendly")
                            .miluFullColor()
                            .scaledToFit()
                            .frame(width: Self.faceWidth)
                            .alignmentGuide(.top) { $0[.bottom] - 2 }
                            .padding(.trailing, Self.faceInset)
                            .accessibilityHidden(true)
                    }
                WidgetButton(title: "Nói với Milu", icon: "hugeicons-mic-01", link: .ai, isPrimary: false)
            }
        }
        .containerBackground(Palette.sky, for: .widget)
        // A tap beside the buttons opens Milu on the add form too.
        .widgetURL(WidgetShared.Link.add.url)
    }
}

#Preview("Ghi nhanh", as: .systemSmall) {
    QuickAddWidget()
} timeline: {
    QuickAddEntry(date: .now, spentText: "185k")
    QuickAddEntry(date: .now, spentText: nil)
}
