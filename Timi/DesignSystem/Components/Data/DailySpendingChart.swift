import Charts
import SwiftUI

/// Spending per day of a month, drawn with Swift Charts: one bar per day, today in teal, days still
/// ahead faint. Tap a bar (or drag sideways across them) to read a day's total under the chart; the
/// selected bar turns teal and the phone ticks. The pick stays after the finger lifts; tapping it
/// again clears it. A tap answers at once: Charts' own selection waited for a long press inside the
/// scrolling page and lit the bars up before it took. VoiceOver reads every day through Charts'
/// own audio graph.
struct DailySpendingChart: View {
    let month: Date
    /// Day of the month → amount spent.
    let totals: [Int: Double]
    /// Which day is lit; the page passes it on so a new day (the app left open overnight) moves it.
    var today = Date.now

    @State private var selectedDay: String?
    /// How tall the bars are.
    var height: CGFloat = 64

    private struct Day: Identifiable {
        let number: Int
        let amount: Double
        let isToday: Bool
        let isFuture: Bool
        var id: Int { number }
        var label: String { String(number) }
    }

    private var calendar: Calendar { .current }
    private var start: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month }
    private var monthNumber: Int { calendar.component(.month, from: start) }

    private var days: [Day] {
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let today = calendar.startOfDay(for: self.today)
        return (1...count).map { number in
            let date = calendar.date(byAdding: .day, value: number - 1, to: start) ?? start
            return Day(number: number, amount: totals[number, default: 0],
                       isToday: calendar.isDate(date, inSameDayAs: today), isFuture: date > today)
        }
    }

    var body: some View {
        let days = days
        let peak = max(days.map(\.amount).max() ?? 0, 1)
        let selected = days.first { $0.label == selectedDay }

        VStack(spacing: Spacing.s) {
            Chart(days) { day in
                // Empty and future days keep a stub so the month still reads as 30 slots.
                BarMark(
                    x: .value("Ngày", day.label),
                    y: .value("Chi", day.isFuture && day.amount == 0 ? peak * 0.06 : max(day.amount, peak * 0.04)),
                    width: .ratio(0.7)
                )
                .clipShape(Capsule())
                .foregroundStyle(color(for: day, selected: selected))
                .accessibilityLabel("Ngày \(day.number)/\(monthNumber)")
                .accessibilityValue(day.amount.vnd)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...peak)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        // A tap on the day already picked clears it.
                        .gesture(SpatialTapGesture().onEnded { value in
                            let day = self.day(at: value.location, proxy: proxy, geometry: geometry)
                            // Tapping the picked day again clears it, with a tick of its own (the
                            // feedback below only ticks when a day is picked).
                            if day == selectedDay, day != nil { Haptics.selection() }
                            selectedDay = day == selectedDay ? nil : day
                        })
                        // Sideways only, so the page still scrolls up and down over the chart.
                        .modifier(SidewaysDrag { location in
                            guard let day = self.day(at: location, proxy: proxy, geometry: geometry) else { return }
                            selectedDay = day
                        })
                }
            }
            .frame(height: height)
            // A tick when a day is picked, not when another month clears it (the picker ticks then).
            .sensoryFeedback(.selection, trigger: selectedDay) { _, new in new != nil }

            HStack {
                Text("1/\(monthNumber)")
                Spacer()
                if let selected {
                    Text("Ngày \(selected.number)/\(monthNumber) · \(selected.amount.vnd)")
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                    Spacer()
                }
                Text("\(days.count)/\(monthNumber)")
            }
            .textRole(.footnote)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
            // Room for the selected day's line, so the card doesn't jump when it appears.
            .frame(minHeight: 18)
        }
        .animation(.easeOut(duration: 0.15), value: selectedDay)
        // Another month: nothing picked.
        .onChange(of: start) { selectedDay = nil }
    }

    /// The day under a point of the chart, if any.
    private func day(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> String? {
        guard let plot = proxy.plotFrame else { return nil }
        let x = location.x - geometry[plot].origin.x
        return proxy.value(atX: x, as: String.self)
    }

    private func color(for day: Day, selected: Day?) -> Color {
        if let selected { return day.id == selected.id ? Palette.primary : Palette.secondary.opacity(0.2) }
        if day.isToday { return Palette.primary }
        return day.isFuture && day.amount == 0 ? Palette.muted : Palette.secondary.opacity(0.3)
    }
}

/// A drag across the chart that only starts sideways. iOS 18 and later let a SwiftUI drag inside
/// the page take the touch even when it goes up or down, so a swipe that began on the chart did
/// not scroll; there a UIKit pan declines anything but a sideways start. iOS 17 keeps the SwiftUI
/// drag, which shares the touch with the scroll.
private struct SidewaysDrag: ViewModifier {
    let onChange: (CGPoint) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(SidewaysPan(onChange: onChange))
        } else {
            content.simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                onChange(value.location)
            })
        }
    }
}

@available(iOS 18.0, *)
private struct SidewaysPan: UIGestureRecognizerRepresentable {
    let onChange: (CGPoint) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard recognizer.state == .began || recognizer.state == .changed else { return }
        onChange(context.converter.localLocation)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
