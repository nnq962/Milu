import SwiftUI

/// A day, shown like a picker row (value and ›): "Hôm nay", "Hôm qua" or 30/10/2026. Tapping it opens
/// a short sheet with Apple's calendar. Changes only the day; the time of `date` is kept, so a
/// `FormTimeRow` can sit under it on the same binding.
struct FormDateRow: View {
    let title: String
    var icon: String? = nil
    @Binding var date: Date
    /// The earliest day the calendar lets the user pick (a deadline starts tomorrow).
    var earliest: Date? = nil
    /// The latest day it lets the user pick (something that already happened: today).
    var latest: Date? = nil
    var isInvalid = false

    @State private var isPicking = false

    private var valueText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Hôm nay" }
        if calendar.isDateInYesterday(date) { return "Hôm qua" }
        return date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(.vietnam))
    }

    var body: some View {
        Button { isPicking = true } label: {
            FormValueRowContent(title: title, icon: icon, value: valueText, isInvalid: isInvalid)
        }
        .buttonStyle(.row)
        .accessibilityValue(valueText)
        .sheet(isPresented: $isPicking) {
            DateTimeSheet(title: title, date: $date, component: .date, earliest: earliest, latest: latest)
        }
    }
}

/// The day and the time on one row ("Hôm nay, 17:07" and ›); tapping it opens the calendar with
/// the time under it (user request 2026-10-30: two rows for one moment).
struct FormDateTimeRow: View {
    let title: String
    @Binding var date: Date
    var latest: Date? = nil

    @State private var isPicking = false

    private var valueText: String {
        let calendar = Calendar.current
        let day = calendar.isDateInToday(date) ? "Hôm nay"
            : calendar.isDateInYesterday(date) ? "Hôm qua"
            : date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(.vietnam))
        return "\(day), \(date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam)))"
    }

    var body: some View {
        Button { isPicking = true } label: {
            FormValueRowContent(title: title, icon: nil, value: valueText)
        }
        .buttonStyle(.row)
        .accessibilityValue(valueText)
        .sheet(isPresented: $isPicking) {
            DateTimeSheet(title: title, date: $date, component: [.date, .hourAndMinute], latest: latest)
        }
    }
}

/// The calendar or the time wheel in a white card. Works on a copy: ✓ saves, ✕ discards.
private struct DateTimeSheet: View {
    let title: String
    @Binding var date: Date
    let component: DatePickerComponents
    var earliest: Date? = nil
    var latest: Date? = nil

    @State private var draft: Date
    @Environment(\.dismiss) private var dismiss

    init(title: String, date: Binding<Date>, component: DatePickerComponents, earliest: Date? = nil,
         latest: Date? = nil) {
        self.title = title
        _date = date
        self.component = component
        self.earliest = earliest
        self.latest = latest
        // A day now outside the range (a due date before a later loan date) starts on the nearest
        // one allowed, so ✓ without a tap fixes it rather than writing the old day back.
        var start = date.wrappedValue
        if component.contains(.date) {
            let calendar = Calendar.current
            if let earliest, start < calendar.startOfDay(for: earliest) {
                start = calendar.date(bySettingHour: calendar.component(.hour, from: start),
                                      minute: calendar.component(.minute, from: start), second: 0,
                                      of: earliest) ?? earliest
            }
            if let latest, !calendar.isDate(start, inSameDayAs: latest), start > latest { start = latest }
        }
        _draft = State(initialValue: start)
    }

    /// The last moment that can be picked: the end of `latest`'s day, so a time already set later
    /// today (21:00 at 10:00) is kept rather than pulled back to now.
    private var latestDay: Date {
        guard let latest else { return .distantFuture }
        let calendar = Calendar.current
        let next = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: latest)) ?? latest
        return next.addingTimeInterval(-1)
    }

    var body: some View {
        SheetScaffold(title: title, onConfirm: { date = draft; dismiss() }, fitsContent: true) {
            // Apple's calendar, with the time under it when asked for (`component`).
            DatePicker(title, selection: $draft, in: (earliest ?? .distantPast)...latestDay,
                       displayedComponents: component)
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(Spacing.m)
            .environment(\.locale, .vietnam)
            .tint(Palette.primary)
            .cardSurface(radius: CardCorners.inset)
        }
    }
}
