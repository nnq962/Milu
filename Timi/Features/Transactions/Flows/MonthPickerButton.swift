import SwiftUI

/// Month button: "Tháng 5 ⌄". Tapping it opens the month-and-year wheels in a small sheet
/// (`MonthPickerSheet`) with ✕ and ✓ (user choice 2026-10-31). It was a native
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
        .sheet(isPresented: $isPicking) { MonthPickerSheet(month: $month) }
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
/// grid of twelve months), in the short sheet `MonthPickerButton` opens. Like every sheet of the
/// app (`SheetScaffold`, user choice 2026-10-31): "Chọn tháng" with ✕ and ✓, the wheels on a card,
/// and the page changes on ✓ only (it used to follow the wheels, with no ✓, as a leftover of the
/// month menu's "Tháng khác…"). Months still ahead cannot be reached. "Tháng này" goes straight
/// back to the current month.
struct MonthPickerSheet: View {
    @Binding var month: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(FinanceStore.self) private var store
    /// The month on the wheels; written to `month` on ✓.
    @State private var draft: Date
    /// Whether "Tháng này" shows: only while another month is open.
    private let showsThisMonth: Bool

    private static let wheelsHeight: CGFloat = 216

    init(month: Binding<Date>) {
        _month = month
        _draft = State(initialValue: month.wrappedValue.startOfMonth)
        showsThisMonth = !Calendar.current.isDate(month.wrappedValue, equalTo: .now, toGranularity: .month)
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
        SheetScaffold(title: "Chọn tháng", onConfirm: {
            withAnimation(.smooth(duration: 0.3)) { month = draft }
            dismiss()
        }, fitsContent: true) {
            VStack(spacing: Spacing.s) {
                // UIDatePicker wheels have no size of their own in SwiftUI: 216 is their standard
                // height. On a card, as the time wheels of `FormTimeRow`.
                MonthYearWheels(month: $draft, range: earliest...Date.now)
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.wheelsHeight)
                    .padding(Spacing.m)
                    .cardSurface(radius: CardCorners.inset)
                if showsThisMonth {
                    Button {
                        Haptics.selection()
                        withAnimation(.smooth(duration: 0.3)) { month = Date.now.startOfMonth }
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
        }
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
            month.wrappedValue = picker.date.startOfMonth
        }
    }
}

private extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}
