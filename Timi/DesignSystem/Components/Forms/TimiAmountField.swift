import SwiftUI

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
