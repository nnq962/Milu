import SwiftUI

// Timi forms replace SwiftUI's grouped `Form`: iOS-style rows (label left, value right) grouped
// on white cards. The controls inside rows (Menu, DatePicker, Toggle) stay native.

/// Same glyph as UITextField's own clear button; keeps the keyboard up.
private struct ClearFieldButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 17))
                .foregroundStyle(Palette.secondary.opacity(0.6))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Xoá nội dung")
    }
}

// MARK: - Ô số tiền lớn

/// The main amount of a form (web CurrencyInput hero): 40pt figure centred with its sign before and
/// "đ" right after in the same colour and weight (user request 2026-10-28), shrinking as it grows; a clear button at the edge and suggestion chips (3 → 3.000đ, 30.000đ, 300.000đ).
struct TimiAmountField: View {
    @Binding var text: String
    var kind: TransactionKind? = nil
    var showsSuggestions = true

    @FocusState private var isFocused: Bool
    /// Digits the user typed; suggestions follow these, not the chip they picked.
    @State private var typedBase: Double?
    /// Counts suggestion taps, so each one ticks.
    @State private var picks = 0

    private var amount: Double { text.vndInputAmount }

    private var heroSize: CGFloat {
        switch text.count {
        case ..<11: 40
        case ..<14: 30
        default: 22
        }
    }

    private var color: Color {
        switch kind {
        case .income: Palette.ink
        case .expense: Palette.red
        case nil: Palette.ink
        }
    }

    private var suggestions: [Double] {
        guard let base = typedBase, base > 0, base < 1_000 else { return [] }
        return [1_000, 10_000, 100_000].map { base * $0 }
    }

    var body: some View {
        VStack(spacing: Spacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                if let kind, amount > 0 {
                    Text(kind == .income ? "+" : "−")
                }
                // An invisible copy of the figure sizes the field, so it hugs the digits and stays centred.
                Text(text.isEmpty ? "0" : text)
                    .opacity(0)
                    .overlay {
                        TextField("0", text: $text)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .focused($isFocused)
                    }
                // Greys out with the "0" placeholder until there is a figure.
                Text("đ")
                    .foregroundStyle(text.isEmpty ? Color(.placeholderText) : color)
            }
            .font(Typography.font(.largeTitle, size: heroSize, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(color)
            .animation(.easeOut(duration: 0.15), value: heroSize)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .overlay(alignment: .trailing) {
                if !text.isEmpty {
                    ClearFieldButton {
                        text = ""
                        typedBase = nil
                    }
                }
            }

            if showsSuggestions && !suggestions.isEmpty {
                HStack(spacing: Spacing.s) {
                    ForEach(suggestions, id: \.self) { value in
                        let picked = value == amount
                        Button {
                            text = String(Int(value)).groupedVNDInput
                            picks += 1
                        } label: {
                            Text(value.vnd)
                                .textRole(.captionStrong)
                                .foregroundStyle(picked ? .white : Palette.ink)
                        }
                        .nativeGlassButton(prominent: picked, tint: picked ? Palette.primary : nil)
                        .buttonBorderShape(.capsule)
                    }
                }
                .transition(.opacity)
                .sensoryFeedback(.selection, trigger: picks)
            }
        }
        .animation(.easeOut(duration: 0.15), value: suggestions)
        .onChange(of: text) { _, newValue in
            let formatted = newValue.groupedVNDInput
            if formatted != newValue {
                text = formatted
                return
            }
            // A chip's value keeps the row where it is; typing resets the base.
            if !suggestions.contains(newValue.vndInputAmount) {
                typedBase = newValue.isEmpty ? nil : newValue.vndInputAmount
            }
        }
    }
}

// MARK: - Nhóm dòng

/// Rows on a white card, with an optional caption above and note below (web FormSection / SettingsGroup).
/// Put `FormDivider()` between rows.
struct FormGroup<Content: View>: View {
    var title: String? = nil
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let title {
                Text(title)
                    .textRole(.overline)
                    .foregroundStyle(Palette.secondaryText)
                    .padding(.horizontal, RowMetrics.horizontal)
            }
            VStack(spacing: 0) { content }
                .cardSurface(radius: CardCorners.inset, color: Palette.card, elevated: true)
            if let footer {
                Text(footer)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .padding(.horizontal, RowMetrics.horizontal)
            }
        }
    }
}

/// Icon tile sizes for the optional `.tile` style; row geometry comes from RowMetrics.
enum FormMetrics {
    static let icon: CGFloat = 36
    static let iconGlyph: CGFloat = 18
    static let iconCorner: CGFloat = 10
    // Row geometry lives in RowMetrics, shared with lists and option sheets.
    static let plainGlyph = RowMetrics.iconGlyph
    static let plainColumn = RowMetrics.iconColumn
    static let gap = RowMetrics.gap
    static let verticalPadding = RowMetrics.vertical
    static let rowHeight = RowMetrics.minHeight
}

/// Hairline between form rows, lined up with the title after the icon tile.
struct FormDivider: View {
    var hasIcon = true

    @Environment(\.formIconStyle) private var style

    var body: some View {
        Palette.border
            .frame(height: 1)
            .padding(.leading, hasIcon ? (style == .plain ? RowMetrics.dividerInset : RowMetrics.horizontal + FormMetrics.icon + RowMetrics.gap)
                                       : RowMetrics.horizontal)
    }
}

/// Icon tile, title and optional subtitle on the left of a form row.
struct FormRowLabel: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        HStack(spacing: FormMetrics.gap) {
            if let icon {
                FormIconTile(icon: icon)
            }
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(title)
                    .textRole(.body)
                    .foregroundStyle(Palette.ink)
                if let subtitle {
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
    }
}

/// Neutral icon tile of a form row (web IconTile sm, tone neutral); `background` for accent tiles.
struct FormIconTile: View {
    let icon: String
    /// nil follows the group's `formIconStyle`: Palette.muted (same as list icons) or no tile.
    var background: Color? = nil

    @Environment(\.formIconStyle) private var style

    var body: some View {
        let plain = style == .plain && background == nil
        SolarIcon(icon, size: plain ? FormMetrics.plainGlyph : FormMetrics.iconGlyph)
            .foregroundStyle(Palette.ink)
            .frame(width: plain ? FormMetrics.plainColumn : FormMetrics.icon,
                   height: plain ? FormMetrics.plainGlyph : FormMetrics.icon)
            .background(background ?? (style == .tile ? Palette.muted : .clear),
                        in: RoundedRectangle(cornerRadius: FormMetrics.iconCorner, style: .continuous))
    }
}

/// Whether form and list icons sit on a muted tile (default) or stand alone.
enum FormIconStyle { case tile, plain }

private struct FormIconStyleKey: EnvironmentKey {
    // No tile by default (user choice 2026-10-28): icons stand alone as in iOS Settings.
    static let defaultValue: FormIconStyle = .plain
}

extension EnvironmentValues {
    var formIconStyle: FormIconStyle {
        get { self[FormIconStyleKey.self] }
        set { self[FormIconStyleKey.self] = newValue }
    }
}

extension View {
    /// `.plain` drops the tile behind icons in form rows and `ListRow`s inside.
    func formIconStyle(_ style: FormIconStyle) -> some View {
        environment(\.formIconStyle, style)
    }
}

private extension View {
    func formRowFrame() -> some View {
        self
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
            .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
            .contentShape(Rectangle())
    }
}

/// Picks one value in a sheet (roomier than a menu): the row shows the current value and ›.
struct FormPickerRow<Value: Hashable>: View {
    let title: String
    var icon: String? = nil
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    @State private var isPicking = false

    var body: some View {
        Button { isPicking = true } label: {
            FormValueLabel(title: title, icon: icon, value: label(selection))
        }
        .buttonStyle(.plain)
        .accessibilityValue(label(selection))
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isPicking) {
            ChoiceSheet(title: title, selection: $selection, options: options, label: label)
        }
    }
}

/// On/off with Apple's switch: on iOS 26 its knob turns to Liquid Glass while dragged. Black when on.
struct FormToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            FormRowLabel(title: title, subtitle: subtitle, icon: icon)
        }
        .tint(Palette.primary)
        .formRowFrame()
    }
}

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
        .buttonStyle(.plain)
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
        .buttonStyle(.plain)
        .accessibilityValue(valueText)
        .sheet(isPresented: $isPicking) {
            DateTimeSheet(title: title, date: $date, component: .hourAndMinute)
        }
    }
}

/// Label, grey value and › on one row: the look shared by every row that opens a picker sheet.
private struct FormValueLabel: View {
    let title: String
    let icon: String?
    let value: String

    var body: some View {
        HStack(spacing: Spacing.s) {
            FormRowLabel(title: title, icon: icon)
            Spacer(minLength: Spacing.s)
            Text(value)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryText)
                .lineLimit(1)
            SolarIcon("solar-alt-arrow-right-linear", size: 16)
                .foregroundStyle(Palette.secondary)
        }
        .formRowFrame()
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

/// Opens something else: value and › on the right.
struct FormNavigationRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                FormRowLabel(title: title, subtitle: subtitle, icon: icon)
                Spacer(minLength: Spacing.s)
                if let value {
                    Text(value)
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
                SolarIcon("solar-alt-arrow-right-linear", size: 16)
                    .foregroundStyle(Palette.secondary)
            }
            .formRowFrame()
        }
        .buttonStyle(.plain)
    }
}

/// A red text row at the end of a form ("Xoá tài khoản"), as at the end of iOS Contacts. Nothing is
/// deleted on the first tap: iOS's own confirmation sheet asks first (`question`, an optional
/// `message`, a red button repeating `title`); the phone gives a warning buzz when it goes.
struct FormDestructiveRow: View {
    let title: String
    let question: String
    var message: String? = nil
    let action: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) { isConfirming = true } label: {
            Text(title)
                .textRole(.body)
                .foregroundStyle(Palette.red)
                .formRowFrame()
        }
        .buttonStyle(.plain)
        .confirmationDialog(question, isPresented: $isConfirming, titleVisibility: .visible) {
            Button(title, role: .destructive) {
                Haptics.warning()
                action()
            }
        } message: {
            if let message { Text(message) }
        }
    }
}

// MARK: - Ô nhập kiểu iOS

/// iOS Settings/Contacts style field row: label on the left, value typed on the right, inside a FormGroup.
struct FormTextRow: View {
    let title: String
    @Binding var text: String
    var prompt = ""
    var icon: String? = nil
    var keyboard: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            FormRowLabel(title: title, icon: icon)
                .fixedSize()
            TextField(prompt, text: $text)
                .textRole(.body)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)
                .focused($isFocused)
            if isFocused && !text.isEmpty {
                ClearFieldButton { text = "" }
            }
        }
        .formRowFrame()
        .onTapGesture { isFocused = true }
    }
}

/// A multi-line note filling a FormGroup row, placeholder in grey (iOS Notes / Reminders style).
struct FormNoteRow: View {
    @Binding var text: String
    var prompt = "Ghi chú"

    var body: some View {
        TextField(prompt, text: $text, axis: .vertical)
            .textRole(.body)
            .foregroundStyle(Palette.ink)
            .lineLimit(3...6)
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
    }
}
