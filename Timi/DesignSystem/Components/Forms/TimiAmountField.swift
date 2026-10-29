import SwiftUI

/// A ready amount offered before anything is typed ("Mỗi tháng 167k" on a goal deposit).
struct AmountPreset: Hashable {
    let label: String
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

    /// "−" for an amount owed or spent, "+" for income; none until there is a figure (or for a
    /// plain balance).
    private var sign: String? {
        if isNegative { return "−" }
        guard let kind, amount > 0 else { return nil }
        return kind == .income ? "+" : "−"
    }

    private var color: Color {
        if isNegative { return Palette.red }
        switch kind {
        case .income: return Palette.ink
        case .expense: return Palette.red
        case nil: return Palette.ink
        }
    }

    /// The largest amount the field takes (12 digits, as `groupedVNDInput`).
    private static let maxAmount: Double = 999_999_999_999

    /// What the typed digits most likely mean, from thousands up to billions: 5 → 5k, 50k, 500k,
    /// 5tr, 50tr; 25 → 25k … 250tr; 2500 → 2,5tr … 25tỷ. Five chips at most.
    private var suggestions: [Double] {
        guard let base = typedBase, base > 0 else { return [] }
        let multipliers: [Double] = [1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9]
        return Array(multipliers.map { base * $0 }.filter { $0 <= Self.maxAmount }.prefix(5))
    }

    /// "25k", "2,5tr", "1,2tỷ": the short form Vietnamese apps use, so five chips fit one row
    /// without scrolling (a scrolling row of glass chips draws a dark band on iOS 26).
    private static func chipLabel(_ value: Double) -> String {
        value.vndCompact
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                if let sign {
                    // Same view while the sign flips, so "+" and "−" roll into each other.
                    Text(sign)
                        .contentTransition(.numericText())
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
                            .tint(Palette.ink)
                            .focused($isFocused)
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
            .font(Typography.font(.largeTitle, size: heroSize, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(color)
            .animation(.easeOut(duration: 0.15), value: heroSize)
            .animation(.snappy(duration: 0.25), value: sign)
            .animation(.easeInOut(duration: 0.25), value: color)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }

            // The row stays in place even when empty; chips fade in and out with SwiftUI's
            // default transition (user choice 2026-10-28, over a staggered pop-in).
            if showsSuggestions {
                // Centred when the chips fit, otherwise a row that scrolls edge to edge.
                ViewThatFits(in: .horizontal) {
                    suggestionChips
                    ScrollView(.horizontal) {
                        suggestionChips
                            .padding(.horizontal, Spacing.page)
                    }
                    .scrollIndicators(.hidden)
                    // iOS 26 draws a darker band behind glass chips at a scroll view's edges.
                    .modifier(NoScrollEdgeEffect())
                    .padding(.horizontal, -Spacing.page)
                }
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
                withAnimation(.smooth(duration: 0.35)) {
                    typedBase = base
                }
            }
        }
    }

    /// One glass layer for all chips, as `ChipRow`: separate glass chips in a scroll view each
    /// sample the page and draw a darker band behind the row on iOS 26.
    @ViewBuilder
    private var suggestionChips: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer { chipStack }
        } else {
            chipStack
        }
    }

    /// Presets until the user types their own figure.
    private var shownPresets: [AmountPreset] { typedBase == nil ? presets : [] }

    private var chipStack: some View {
        HStack(spacing: Spacing.s) {
            ForEach(shownPresets, id: \.self) { preset in
                let picked = preset.value == amount
                Button {
                    text = String(Int(preset.value)).groupedVNDInput
                    picks += 1
                } label: {
                    Text("\(preset.label) \(preset.value.vndCompact)")
                        .textRole(.captionStrong)
                        .foregroundStyle(picked ? .white : Palette.ink)
                        .fixedSize()
                }
                .nativeGlassButton(prominent: picked, tint: picked ? Palette.primary : nil)
                .buttonBorderShape(.capsule)
                .accessibilityLabel("\(preset.label) \(preset.value.vnd)")
            }
            ForEach(suggestions, id: \.self) { value in
                let picked = value == amount
                Button {
                    text = String(Int(value)).groupedVNDInput
                    picks += 1
                } label: {
                    Text(Self.chipLabel(value))
                        .textRole(.captionStrong)
                        .foregroundStyle(picked ? .white : Palette.ink)
                        .fixedSize()
                }
                .nativeGlassButton(prominent: picked, tint: picked ? Palette.primary : nil)
                .buttonBorderShape(.capsule)
                .accessibilityLabel(value.vnd)
            }
        }
    }
}

/// The top of a money sheet: what the amount is (a small grey line: "Số dư hiện tại", the goal's
/// name) above the big `TimiAmountField`. One layout for every sheet that starts with an amount.
struct SheetAmountHeader<Field: View>: View {
    let caption: String
    @ViewBuilder var field: Field

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(caption)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
            field
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.l)
    }
}
