import SwiftUI

/// Month button: "Tháng 5 ⌄", a native menu (user choice 2026-10-30): on iOS 26 it opens out of the
/// button as a glass panel with no arrow, the last six months to pick in one tap (the chosen
/// one ticked), then "Tháng khác…" for the month-and-year wheels in a small sheet. The popover the
/// wheels used to open in pointed an arrow at the button, which read as dated.
///
/// The capsule is plain glass (`GlassCapsule`); `compact` is the quiet form for a section heading
/// (Lịch thu chi on Tổng quan): moss words (14) and chevron with no capsule, still 44pt to tap.
struct MonthMenu: View {
    @Binding var month: Date
    var compact = false

    @State private var isPicking = false

    var body: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let number = calendar.component(.month, from: month)
        let isCurrentYear = year == calendar.component(.year, from: .now)
        let title = isCurrentYear ? "Tháng \(number)" : "T\(number)/\(year.formatted(.number.grouping(.never)))"
        Menu {
            Picker("Tháng", selection: chosenMonth) {
                ForEach(recentMonths, id: \.self) { start in
                    Text(Self.name(of: start)).tag(start)
                }
            }
            Divider()
            Button("Tháng khác…") { isPicking = true }
        } label: {
            if compact { compactLabel(title) } else { capsuleLabel(title) }
        }
        .menuOrder(.fixed)
        .modifier(MonthMenuStyle(compact: compact))
        .accessibilityLabel("Chọn tháng, tháng \(number) năm \(String(year))")
        .sheet(isPresented: $isPicking) {
            MonthPickerPopover(month: $month)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    /// The month shown, as the first of it; picking one moves the page there.
    private var chosenMonth: Binding<Date> {
        Binding {
            month.startOfMonth
        } set: { start in
            Haptics.selection()
            withAnimation(.smooth(duration: 0.3)) { month = start }
        }
    }

    /// This month and the five before it, newest first (twelve made the menu scroll and hid
    /// "Tháng khác…"); an older month being shown is added at
    /// the end so it still shows ticked.
    private var recentMonths: [Date] {
        let calendar = Calendar.current
        let now = Date.now.startOfMonth
        var months = (0..<6).compactMap { calendar.date(byAdding: .month, value: -$0, to: now) }
        if !months.contains(month.startOfMonth) { months.append(month.startOfMonth) }
        return months
    }

    /// "Tháng 9" this year, "Tháng 9/2025" another.
    private static func name(of start: Date) -> String {
        let calendar = Calendar.current
        let number = calendar.component(.month, from: start)
        let year = calendar.component(.year, from: start)
        return year == calendar.component(.year, from: .now) ? "Tháng \(number)" : "Tháng \(number)/\(String(year))"
    }

    private func compactLabel(_ title: String) -> some View {
        HStack(spacing: Spacing.xs) {
            // 14, clearly under the 17 heading beside it: 16 read as large as the heading, 13 as
            // too small (user 2026-10-30).
            Text(title)
                .textRole(.accessory)
                .monospacedDigit()
                .fixedSize()
                .contentTransition(.numericText())
            TimiIcon("hugeicons-arrow-down-01", size: 12)
        }
        .foregroundStyle(Palette.primary)
        .frame(minHeight: ControlHeight.regular)
        .contentShape(Rectangle())
    }

    private func capsuleLabel(_ title: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .textRole(.body)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
                .contentTransition(.numericText())
            TimiIcon("hugeicons-arrow-down-01", size: 14)
        }
        .foregroundStyle(Palette.ink)
        // Inside the label, so the whole capsule takes the tap, not only the words.
        .padding(.horizontal, Spacing.l)
        // At least the 44 of the circles beside it, taller with larger text.
        .padding(.vertical, Spacing.xs)
        .frame(minHeight: ControlHeight.regular)
        .contentShape(Capsule())
    }
}

/// The menu's button: plain words for `compact`, else the glass capsule.
private struct MonthMenuStyle: ViewModifier {
    let compact: Bool

    func body(content: Content) -> some View {
        if compact {
            content.buttonStyle(.plain)
        } else {
            // The same plain glass as the circles beside it (user choice 2026-10-29, after lime).
            content.modifier(GlassCapsule())
        }
    }
}

/// Picks a month on the iOS month-and-year wheels (user choice 2026-10-30: native, over the drawn
/// grid of twelve months), in a small sheet from "Tháng khác…" of `MonthMenu`. The page follows
/// the wheels as they turn; a swipe down or a tap outside closes it. Months still ahead
/// cannot be reached. "Tháng này" goes back to the current month.
struct MonthPickerPopover: View {
    @Binding var month: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(FinanceStore.self) private var store
    /// Whether "Tháng này" shows, decided as it opens: turning the wheels changes `month`, and the
    /// button must not pop in and out (and the popover resize) while they turn.
    @State private var showsThisMonth: Bool

    private let calendar = Calendar.current

    init(month: Binding<Date>) {
        _month = month
        _showsThisMonth = State(initialValue: !Calendar.current.isDate(month.wrappedValue, equalTo: .now, toGranularity: .month))
    }

    private var earliest: Date { Self.earliest(in: store) }

    /// Back no further than January of the oldest thing recorded (or last year, on a new install).
    static func earliest(in store: FinanceStore) -> Date {
        let calendar = Calendar.current
        let oldest = (store.transactions.map(\.date) + store.accountTransfers.map(\.date)
            + store.loanMoves.map(\.date) + store.listedLoanPayments.map(\.date)).min() ?? .now
        let year = min(calendar.component(.year, from: oldest), calendar.component(.year, from: .now) - 1)
        return calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? oldest
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            MonthYearWheels(month: $month, range: earliest...Date.now)
                .frame(width: 300, height: 216)
            if showsThisMonth {
                Button("Tháng này") {
                    Haptics.selection()
                    withAnimation(.smooth(duration: 0.3)) { month = .now.startOfMonth }
                    dismiss()
                }
                .textRole(.bodyStrong)
                .tint(Palette.primary)
                .frame(minHeight: ControlHeight.regular)
            }
        }
        .padding(.vertical, Spacing.s)
        .frame(maxWidth: .infinity)
    }
}

/// `UIDatePicker` in its month-and-year wheels (iOS 17.4), which SwiftUI's `DatePicker` does not
/// offer. Sets `month` to the first of the month shown.
private struct MonthYearWheels: UIViewRepresentable {
    @Binding var month: Date
    let range: ClosedRange<Date>

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .yearAndMonth
        picker.preferredDatePickerStyle = .wheels
        picker.locale = .vietnam
        picker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        context.coordinator.month = $month
        picker.minimumDate = range.lowerBound
        picker.maximumDate = range.upperBound
        // Only when it differs, so a redraw does not fight the wheels mid-turn.
        if !Calendar.current.isDate(picker.date, equalTo: month, toGranularity: .month) {
            picker.setDate(month, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(month: $month) }

    final class Coordinator: NSObject {
        var month: Binding<Date>

        init(month: Binding<Date>) { self.month = month }

        // The wheels tick on their own, so no haptic here.
        @objc func changed(_ picker: UIDatePicker) {
            withAnimation(.smooth(duration: 0.3)) { month.wrappedValue = picker.date.startOfMonth }
        }
    }
}

private extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}

/// The month button's look: the iOS default glass, as the search circle beside it, 44pt tall
/// like it. A glass button style there takes the toolbar's smaller height, so the capsule is
/// drawn here; earlier iOS has no glass and takes the light grey fill a bordered button has.
private struct GlassCapsule: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .buttonStyle(.plain)
                .background(Palette.fill3, in: Capsule())
        }
    }
}
