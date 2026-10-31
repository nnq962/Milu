import SwiftUI

/// Month button: "Tháng 5 ⌄". Tapping it opens the month-and-year wheels in a small sheet
/// (`MonthPickerSheet`), the page following as they turn (user choice 2026-10-31). It was a native
/// menu of the last six months: as the menu closed without a pick, iOS shrank its glass back into
/// the button over the words, which read as the words being squeezed.
///
/// The capsule is a flat fill; `compact` is plain words (14, `HeaderLink`) for beside a section
/// heading (Lịch thu chi on Tổng quan).
struct MonthPickerButton: View {
    @Binding var month: Date
    var compact = false

    @State private var isPicking = false
    /// The ⌄ grows with the words beside it: fixed, it looked tiny at the accessibility sizes
    /// (review 2026-10-31).
    @ScaledMetric(relativeTo: .body) private var chevron = RowMetrics.inlineGlyph

    var body: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let number = calendar.component(.month, from: month)
        let title = Self.name(of: month)
        Group {
            if compact {
                Button { isPicking = true } label: { HeaderLink(title: title, opensMenu: true) }
                    .headerLinkButton()
            } else {
                Button { isPicking = true } label: { capsuleLabel(title) }
                    // A flat fill, as the report circle beside it. Glass here, inside a scrolling
                    // card, trailed behind the card as the page scrolled (user report 2026-10-31).
                    .flatCapsuleButton()
            }
        }
        // A new button for each month: the old label's width stayed, so "Tháng 9" ↔ "Tháng 10"
        // came out cut short or too wide (user report 2026-10-31). It swaps at once: a fade left
        // the old month showing through the new one.
        .id(title)
        .transition(.identity)
        .accessibilityLabel("Chọn tháng, tháng \(number) năm \(String(year))")
        .sheet(isPresented: $isPicking) {
            MonthPickerSheet(month: $month)
                // Apple's own sheet: one height, so iOS shows no grabber, as on every other one.
                .presentationDetents([.height(320)])
                .presentationBackground(Palette.background)
        }
    }

    /// "Tháng 9" this year, "Tháng 9/2025" another: the button and the page's empty state.
    static func name(of start: Date) -> String {
        let calendar = Calendar.current
        let number = calendar.component(.month, from: start)
        let year = calendar.component(.year, from: start)
        return year == calendar.component(.year, from: .now) ? "Tháng \(number)" : "Tháng \(number)/\(String(year))"
    }

    private func capsuleLabel(_ title: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .textRole(.body)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
            TimiIcon("hugeicons-arrow-down-01", size: chevron)
        }
        .foregroundStyle(Palette.label)
        // Inside the label, so the whole capsule takes the tap, not only the words.
        .padding(.horizontal, Spacing.l)
        // At least the 44 of the circles beside it, taller with larger text.
        .padding(.vertical, Spacing.xs)
        .frame(minHeight: ControlHeight.regular)
    }
}

/// Picks a month on the iOS month-and-year wheels (user choice 2026-10-30: native, over the drawn
/// grid of twelve months), in the small sheet `MonthPickerButton` opens. The page follows
/// the wheels as they turn; a swipe down or a tap outside closes it. Months still ahead
/// cannot be reached. "Tháng này" goes back to the current month.
struct MonthPickerSheet: View {
    @Binding var month: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(FinanceStore.self) private var store
    /// Whether "Tháng này" shows, decided as it opens: turning the wheels changes `month`, and the
    /// button must not pop in and out (and the sheet resize) while they turn.
    @State private var showsThisMonth: Bool

    private let calendar = Calendar.current
    private static let wheelsSize = CGSize(width: 300, height: 216)

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
            // UIDatePicker wheels have no size of their own in SwiftUI: 216 is their standard
            // height, and the width keeps month and year close together in the middle of the sheet
            // rather than flung to its edges.
            MonthYearWheels(month: $month, range: earliest...Date.now)
                .frame(width: Self.wheelsSize.width, height: Self.wheelsSize.height)
            if showsThisMonth {
                Button {
                    Haptics.selection()
                    withAnimation(.smooth(duration: 0.3)) { month = .now.startOfMonth }
                    dismiss()
                } label: {
                    // The frame inside the label, so all 44 take the tap (strict review 2026-10-31).
                    Text("Tháng này")
                        .padding(.horizontal, Spacing.l)
                        .frame(minHeight: ControlHeight.regular)
                        .contentShape(Rectangle())
                }
                .textRole(.bodyStrong)
                .tint(Palette.primary)
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
