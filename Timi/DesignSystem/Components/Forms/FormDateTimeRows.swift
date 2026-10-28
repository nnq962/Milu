import SwiftUI

/// A day, shown like a picker row (value and ›): "Hôm nay", "Hôm qua" or 30/10/2026. Tapping it opens
/// a short sheet with Apple's calendar. Changes only the day; the time of `date` is kept, so a
/// `FormTimeRow` can sit under it on the same binding.
struct FormDateRow: View {
    let title: String
    var icon: String? = nil
    @Binding var date: Date

    @State private var isPicking = false

    private var valueText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Hôm nay" }
        if calendar.isDateInYesterday(date) { return "Hôm qua" }
        return date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(.vietnam))
    }

    var body: some View {
        Button { isPicking = true } label: {
            FormValueLabel(title: title, icon: icon, value: valueText)
        }
        .buttonStyle(.row)
        .accessibilityValue(valueText)
        .sheet(isPresented: $isPicking) {
            DateTimeSheet(title: title, date: $date, component: .date)
        }
    }
}

/// A time of day, shown like a picker row ("13:28" and ›); tapping it opens a short sheet with the
/// time wheel. Changes only the hour and minute of `date`.
struct FormTimeRow: View {
    let title: String
    var icon: String? = nil
    @Binding var date: Date

    @State private var isPicking = false

    private var valueText: String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
    }

    var body: some View {
        Button { isPicking = true } label: {
            FormValueLabel(title: title, icon: icon, value: valueText)
        }
        .buttonStyle(.row)
        .accessibilityValue(valueText)
        .sheet(isPresented: $isPicking) {
            DateTimeSheet(title: title, date: $date, component: .hourAndMinute)
        }
    }
}

/// The calendar or the time wheel in a white card. Works on a copy: ✓ saves, ✕ discards.
private struct DateTimeSheet: View {
    let title: String
    @Binding var date: Date
    let component: DatePickerComponents

    @State private var draft: Date
    @Environment(\.dismiss) private var dismiss

    init(title: String, date: Binding<Date>, component: DatePickerComponents) {
        self.title = title
        _date = date
        self.component = component
        _draft = State(initialValue: date.wrappedValue)
    }

    var body: some View {
        VStack(spacing: Spacing.l) {
            SheetHeader(title: title) {
                date = draft
                Haptics.success()
                dismiss()
            }
            Group {
                if component == .date {
                    DatePicker(title, selection: $draft, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                } else {
                    DatePicker(title, selection: $draft, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                }
            }
            .labelsHidden()
            .padding(Spacing.m)
            .environment(\.locale, .vietnam)
            .tint(Palette.primary)
            .cardSurface(radius: CardCorners.inset, color: Palette.card, elevated: true)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .timiFittedSheet()
    }
}
