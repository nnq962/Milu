import SwiftUI

/// Month button: "Tháng 5 ⌄". Tapping it opens the month-and-year wheels in a small sheet
/// (`MonthPickerSheet`) with ✕ and ✓ (user choice 2026-10-31). It was a native
/// menu of the last six months: as the menu closed without a pick, iOS shrank its glass back into
/// the button over the words, which read as the words being squeezed.
///
/// The capsule is a flat fill; `compact` is plain words (14, `HeaderLink`) for beside a section
/// heading (Lịch thu chi on Tổng quan); `lead` puts words before the month in the small label of a
/// page's figure, "Đã chi tháng 11 ⌄" (the head of Thu chi, user pick "A" 2026-11-03: the capsule
/// read heavy over the figure).
struct MonthPickerButton: View {
    @Binding var month: Date
    var compact = false
    var lead: String? = nil

    @State private var isPicking = false
    /// The ⌄ grows with the words beside it: fixed, it looked tiny at the accessibility sizes
    /// (review 2026-10-31).
    @ScaledMetric(relativeTo: .body) private var chevron = RowMetrics.inlineGlyph
    /// The ⌄ after the small words of `lead`, growing with them as well.
    @ScaledMetric(relativeTo: .caption) private var leadChevron = RowMetrics.linkChevron

    var body: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let number = calendar.component(.month, from: month)
        let title = Self.name(of: month)
        Group {
            if let lead {
                Button { isPicking = true } label: { leadLabel(lead, title) }
                    .headerLinkButton()
            } else if compact {
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

    /// "Đã chi tháng 11 ⌄" in the figure's small label, its colour and size; the area that takes a
    /// tap reaches past the words, as a `HeaderLink`'s, so it is 44 tall at any size. The words may
    /// wrap at the largest text sizes, where on one line they pushed the page past the screen
    /// (review 2026-11-03).
    private func leadLabel(_ lead: String, _ title: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text("\(lead) \(title.lowercased())")
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
            TimiIcon("hugeicons-arrow-down-01", size: leadChevron)
        }
        .textRole(.captionStrong)
        .foregroundStyle(Palette.secondaryLabel)
        .contentShape(Rectangle().inset(by: -Spacing.m))
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
        // Month and year wheels from iOS 17.4; before it the date wheels, read as their month.
        if #available(iOS 17.4, *) {
            picker.datePickerMode = .yearAndMonth
        } else {
            picker.datePickerMode = .date
        }
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
