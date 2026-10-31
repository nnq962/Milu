import SwiftUI

/// A ready amount offered before anything is typed ("Mỗi tháng 167k" on a goal deposit); with no
/// label, the amount alone ("10tr").
struct AmountPreset: Hashable {
    /// The words before the figure ("Mỗi tháng"); empty shows the figure alone.
    let title: String
    let value: Double
}

/// The main amount of a form (web CurrencyInput hero): 40pt figure centred with its sign before and
/// "đ" right after in the same colour and weight (user request 2026-10-28), shrinking as it grows;
/// suggestion chips (3 → 3k … 30tr).
struct TimiAmountField: View {
    @Binding var text: String
    var kind: TransactionKind? = nil
    var showsSuggestions = true
    /// Opens the keyboard as the form appears (new entries, where the amount comes first).
    var focusesOnAppear = false
    /// Shows the figure as owed: a "−" before it and red (an overdrawn account, cash owed).
    var isNegative = false
    /// Chips shown while nothing is typed; typing replaces them with the usual suggestions.
    var presets: [AmountPreset] = []
    /// What VoiceOver calls the field ("Số tiền gốc"); the title above it is a separate element.
    var accessibilityLabel = "Số tiền"

    @FocusState private var isFocused: Bool
    /// Digits the user typed; suggestions follow these, not the chip they picked.
    @State private var typedBase: Double?
    /// Counts suggestion taps, so each one ticks.
    @State private var picks = 0

    private var amount: Double { text.vndInputAmount }

    private var heroSize: CGFloat { TextRole.amountEntrySize(for: text.count) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// "−" for an amount owed or spent, "+" for income; none until there is a figure (or for a
    /// plain balance).
    private var sign: String? {
        if isNegative { return "−" }
        guard let kind, amount > 0 else { return nil }
        return kind == .income ? "+" : "−"
    }

    private var color: Color {
        if isNegative { return Palette.negative }
        switch kind {
        case .income: return Palette.label
        case .expense: return Palette.negative
        case nil: return Palette.label
        }
    }

    /// The largest amount the field takes (12 digits, as `groupedVNDInput`).
    private static let maxAmount: Double = 999_999_999_999

    /// What the typed digits most likely mean: 5 → 5.000đ, 50.000đ, 500.000đ; 25 → 25.000đ …
    /// 2.500.000đ. Three chips, written in full as a banking app does (user choice 2026-10-31:
    /// five short "25k … 250tr" chips mixed two forms of money), so they fit one row.
    private var suggestions: [Double] {
        guard let base = typedBase, base > 0 else { return [] }
        let multipliers: [Double] = [1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9]
        return Array(multipliers.map { base * $0 }.filter { $0 <= Self.maxAmount }.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                if let sign {
                    // Same view while the sign flips, so "+" and "−" roll into each other.
                    Text(sign)
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
                // The figure the user sees, changing at once (no rolling digits: too busy when a
                // chip is picked, user request 2026-10-28). The TextField over it draws no text
                // of its own, only the caret, so the two always line up. Empty, the field is a
                // 2pt sliver: its caret blinks right before the grey "0", so tapping shows at
                // once where typing goes.
                Text(text.isEmpty ? " " : text)
                    .opacity(text.isEmpty ? 0 : 1)
                    .frame(width: text.isEmpty ? 2 : nil)
                    .overlay {
                        TextField("", text: $text)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(text.isEmpty ? .leading : .center)
                            .foregroundStyle(.clear)
                            .tint(Palette.label)
                            .focused($isFocused)
                            .accessibilityLabel(accessibilityLabel)
                    }
                if text.isEmpty {
                    Text("0")
                        .foregroundStyle(Color(.placeholderText))
                        .accessibilityHidden(true)
                }
                // Greys out with the "0" placeholder until there is a figure.
                Text("đ")
                    .foregroundStyle(text.isEmpty ? Color(.placeholderText) : color)
            }
            .font(Typography.font(TextRole.amountEntry.textStyle, size: heroSize, weight: TextRole.amountEntry.weight))
            .monospacedDigit()
            .foregroundStyle(color)
            // Still under Reduce Motion: the figure, sign and colour change at once.
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: heroSize)
            .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: sign)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: color)
            .frame(maxWidth: .infinity, minHeight: ControlHeight.large)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }

            // The row stays in place even when empty; chips fade in and out with SwiftUI's
            // default transition (user choice 2026-10-28, over a staggered pop-in).
            if showsSuggestions {
                // Centred, wrapping onto a second line rather than scrolling when they do not fit.
                chipStack
                    .padding(.top, suggestions.isEmpty && shownPresets.isEmpty ? 0 : Spacing.m)
                    .sensoryFeedback(.selection, trigger: picks)
            }
        }
        .task {
            guard focusesOnAppear else { return }
            // Wait for the sheet to settle, or the keyboard fights its slide-in.
            try? await Task.sleep(for: .milliseconds(450))
            isFocused = true
        }
        .onChange(of: text) { _, newValue in
            let formatted = newValue.groupedVNDInput
            if formatted != newValue {
                text = formatted
                return
            }
            // A chip's value keeps the row where it is; typing resets the base.
            let value = newValue.vndInputAmount
            if !suggestions.contains(value) && !presets.contains(where: { $0.value == value }) {
                let base: Double? = newValue.isEmpty ? nil : newValue.vndInputAmount
                guard base != typedBase else { return }
                // One transaction for the whole sheet: the chip row opens or closes and the rows
                // below glide with it, instead of jumping while only the chips animate.
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) {
                    typedBase = base
                }
            }
        }
    }


    /// Presets until the user types their own figure.
    private var shownPresets: [AmountPreset] { typedBase == nil ? presets : [] }

    /// Flat chips, the one matching the amount filled (user choice 2026-10-31: no glass in content).
    /// Lines wrap, centred under the figure, when the full amounts do not fit one row.
    private var chipStack: some View {
        FlowLayout(spacing: Spacing.s, centered: true) {
            ForEach(shownPresets, id: \.self) { preset in
                // An empty label shows the amount alone ("10tr").
                TagChip(title: preset.title.isEmpty ? preset.value.vnd : "\(preset.title) \(preset.value.vnd)",
                        isProminent: preset.value == amount) {
                    text = String(Int(preset.value)).groupedVNDInput
                    picks += 1
                }
                .fixedSize()
                .accessibilityLabel(preset.title.isEmpty ? preset.value.vnd : "\(preset.title) \(preset.value.vnd)")
            }
            ForEach(suggestions, id: \.self) { value in
                TagChip(title: value.vnd, isProminent: value == amount) {
                    text = String(Int(value)).groupedVNDInput
                    picks += 1
                }
                .fixedSize()
                .accessibilityLabel(value.vnd)
            }
        }
    }
}

/// The top of a money sheet: what the amount is (a small grey line: "Số dư hiện tại", the goal's
/// name) above the big `TimiAmountField`. One layout for every sheet that starts with an amount.
struct SheetAmountHeader<Field: View>: View {
    let title: String
    /// The field reads the title itself (`TimiAmountField(accessibilityLabel:)`), so VoiceOver skips
    /// the line above it rather than saying it twice.
    var fieldSaysCaption = false
    @ViewBuilder var field: Field

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .accessibilityHidden(fieldSaysCaption)
            field
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.l)
    }
}
