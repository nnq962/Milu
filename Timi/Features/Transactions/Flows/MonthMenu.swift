import SwiftUI

/// Month button: "Tháng 5" + chevron on a plain glass capsule (`GlassCapsule`). It opens
/// `MonthPickerSheet` (user choice 2026-10-29), not a menu: a menu read as "earlier / later"
/// rather than picking a month, and its glass button took a moment to settle after it closed.
struct MonthMenu: View {
    @Binding var month: Date

    @State private var isPicking = false

    var body: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let number = calendar.component(.month, from: month)
        let isCurrentYear = year == calendar.component(.year, from: .now)
        Button { isPicking = true } label: {
            HStack(spacing: Spacing.xs) {
                Text(isCurrentYear ? "Tháng \(number)" : "T\(number)/\(year.formatted(.number.grouping(.never)))")
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
            // At least the 44 of the search circle beside it, taller with larger text.
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: ControlHeight.regular)
            .contentShape(Capsule())
        }
        // The same plain glass as the search circle beside it (user choice 2026-10-29, after lime).
        .modifier(GlassCapsule())
        .accessibilityLabel("Chọn tháng, tháng \(number) năm \(String(year))")
        .sheet(isPresented: $isPicking) {
            MonthPickerSheet(month: $month)
        }
    }
}

/// Picks a month: the year with ‹ › on top, then the twelve months in a grid; the chosen one is
/// black, months still ahead are faint and cannot be picked. Picking closes the sheet. "Tháng này"
/// goes back to the current month.
struct MonthPickerSheet: View {
    @Binding var month: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(FinanceStore.self) private var store
    @State private var year: Int
    /// Whether "Tháng này" shows, decided as the sheet opens: picking a month changes `month` and
    /// closes the sheet, and the button must not pop in (and the sheet grow) while it slides away.
    @State private var showsThisMonth: Bool

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 4)

    init(month: Binding<Date>) {
        _month = month
        _year = State(initialValue: Calendar.current.component(.year, from: month.wrappedValue))
        _showsThisMonth = State(initialValue: !Calendar.current.isDate(month.wrappedValue, equalTo: .now, toGranularity: .month))
    }

    private var thisYear: Int { calendar.component(.year, from: .now) }
    /// Back no further than the oldest thing recorded (or last year, on a new install).
    private var firstYear: Int {
        let oldest = (store.transactions.map(\.date) + store.accountTransfers.map(\.date)
            + store.loanMoves.map(\.date) + store.listedLoanPayments.map(\.date)).min() ?? .now
        return min(calendar.component(.year, from: oldest), thisYear - 1)
    }
    private var thisMonth: Int { calendar.component(.month, from: .now) }
    private var chosen: (year: Int, month: Int) {
        (calendar.component(.year, from: month), calendar.component(.month, from: month))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: "Chọn tháng")

            HStack {
                yearButton("hugeicons-arrow-left-01", label: "Năm trước", delta: -1, isEnabled: year > firstYear)
                Spacer()
                Text(String(year))
                    .textRole(.title)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
                yearButton("hugeicons-arrow-right-01", label: "Năm sau", delta: 1, isEnabled: year < thisYear)
            }

            LazyVGrid(columns: columns, spacing: Spacing.s) {
                ForEach(1...12, id: \.self) { number in
                    monthCell(number)
                }
            }

            if showsThisMonth {
                Button("Tháng này") { pick(year: thisYear, month: thisMonth) }
                    .textRole(.bodyStrong)
                    .tint(Palette.ink)
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .animation(.snappy(duration: 0.25), value: year)
        .timiFittedSheet()
    }

    /// The glass circle draws its glyph itself, so a year that cannot be reached greys the glyph
    /// here (`disabled` alone leaves it black).
    private func yearButton(_ icon: String, label: String, delta: Int, isEnabled: Bool) -> some View {
        Button { year += delta } label: {
            TimiIcon(icon, size: 20)
                .foregroundStyle(isEnabled ? Palette.ink : Palette.secondary.opacity(0.4))
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .nativeCircleButton(diameter: 44)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }

    private func monthCell(_ number: Int) -> some View {
        let isChosen = chosen == (year, number)
        let isAhead = year > thisYear || (year == thisYear && number > thisMonth)
        return Button { pick(year: year, month: number) } label: {
            Text("T\(number)")
                .textRole(.bodyStrong)
                .monospacedDigit()
                .foregroundStyle(isChosen ? Palette.onPrimary : isAhead ? Palette.secondaryText : Palette.ink)
                .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
                .background(isChosen ? Palette.primary : Palette.card, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isAhead)
        .accessibilityLabel("Tháng \(number) năm \(String(year))")
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    private func pick(year: Int, month number: Int) {
        guard let date = calendar.date(from: DateComponents(year: year, month: number, day: 1)) else { return }
        Haptics.selection()
        withAnimation(.smooth(duration: 0.3)) { month = date }
        dismiss()
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
