import SwiftUI

/// Picks one value in a sheet (roomier than a menu): the row shows the current value and ›.
struct FormPickerRow<Value: Hashable>: View {
    let title: String
    var icon: String? = nil
    @Binding var selection: Value
    let options: [Value]
    /// Icon beside each choice in the sheet (categories, accounts), and beside the chosen one on
    /// the row.
    var optionIcon: ((Value) -> String)? = nil
    let optionTitle: (Value) -> String

    @State private var isPicking = false

    var body: some View {
        // The chosen option shows with the icon or logo it has in the sheet, as "Hạng mục" does.
        Button { isPicking = true } label: {
            FormValueRowContent(title: title, icon: icon, value: optionTitle(selection), valueIcon: optionIcon?(selection))
        }
        .buttonStyle(.row)
        .accessibilityValue(optionTitle(selection))
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isPicking) {
            ChoiceSheet(title: title, selection: $selection, options: options, optionIcon: optionIcon, optionTitle: optionTitle)
        }
    }
}

/// On/off with Apple's switch, in the primary colour when on; its knob turns to Liquid Glass while dragged.
struct FormToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            FormRowLabel(title: title, subtitle: subtitle, icon: icon)
        }
        .tint(Palette.switchOn)
        .formRowFrame()
    }
}

/// Label, grey value and › on one row: the look shared by every row that opens a picker sheet.
/// Without the › (`showsChevron: false`) it only shows a value, as on a detail sheet.
struct FormValueRowContent: View {
    let title: String
    var icon: String? = nil
    let value: String
    /// An icon or bank logo before the value ("Ngân hàng  [logo] Vietcombank ›").
    var valueIcon: String? = nil
    var isInvalid = false
    var showsChevron = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Spacing.s) {
            // Value at the right of the label; under it at the accessibility sizes, where one
            // line cut "Hôm nay, 13:…" short (review 2026-10-31).
            AdaptiveStack(spacing: Spacing.s) {
                FormRowLabel(title: title, icon: icon, isInvalid: isInvalid)
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                HStack(spacing: Spacing.s) {
                    if let valueIcon {
                        RowIcon(name: valueIcon, size: IconSize.valueArtwork)
                    }
                    // A new date, time or choice rolls in, so the change is easy to notice (not
                    // under Reduce Motion).
                    Text(value)
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: value)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsChevron {
                RowChevron()
            }
        }
        .formRowFrame()
    }
}

/// A row that only shows a value (a detail sheet): label, grey value with its icon or logo, no ›.
struct FormInfoRow: View {
    let title: String
    let value: String
    var valueIcon: String? = nil

    var body: some View {
        FormValueRowContent(title: title, icon: nil, value: value, valueIcon: valueIcon, showsChevron: false)
            .accessibilityElement(children: .combine)
    }
}

/// A read-only row whose value is money: the title, and the amount by `MoneyText` (a transfer's
/// fee "-5.000đ" red, a loan's principal), never a grey string.
struct FormAmountInfoRow: View {
    let title: String
    let amount: Double
    var tone: MoneyText.Tone = .neutral

    var body: some View {
        HStack(spacing: Spacing.s) {
            FormRowLabel(title: title)
            Spacer(minLength: Spacing.s)
            MoneyText(amount: amount, tone: tone)
                .fixedSize()
        }
        .formRowFrame()
        .accessibilityElement(children: .combine)
    }
}

/// The label of a row that pushes a screen (a `NavigationLink`): icon, title, optional subtitle and
/// value, and ›. Put it in a `NavigationLink` with `.buttonStyle(.row)`.
struct NavigationRowContent: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var value: String? = nil
    /// What VoiceOver reads for a bare number in `value` ("12 hạng mục"), once, after the title.
    var spokenValue: String? = nil
    var iconSize: CGFloat = RowMetrics.iconColumn

    var body: some View {
        let row = HStack(spacing: Spacing.s) {
            FormRowLabel(title: title, subtitle: subtitle, icon: icon, iconSize: iconSize)
            Spacer(minLength: Spacing.s)
            if let value {
                Text(value)
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryLabel)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            RowChevron()
        }
        .formRowFrame()
        .contentShape(Rectangle())
        if let spokenValue {
            row
                .accessibilityElement(children: .ignore)
                .accessibilityLabel([title, subtitle].compactMap { $0 }.joined(separator: ", "))
                .accessibilityValue(spokenValue)
        } else {
            row
        }
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
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(1)
                }
                RowChevron()
            }
            .formRowFrame()
        }
        .buttonStyle(.row)
    }
}

/// An action that can be undone, done in place ("Lưu trữ tài khoản", "Khôi phục", "Mở lại hũ"):
/// icon and title in ink, no ›. With `question`, an alert asks first (`message`, a button repeating
/// `title`). Deleting is `FormDestructiveRow`.
struct FormActionRow: View {
    let title: String
    var icon: String? = nil
    var question: String? = nil
    var message: String? = nil
    /// False: the alert only explains (`message`) and offers "OK", e.g. the last group of a kind.
    var canConfirm = true
    let action: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button {
            if question == nil { action() } else { isConfirming = true }
        } label: {
            HStack(spacing: RowMetrics.gap) {
                if let icon {
                    RowIcon(name: icon)
                }
                Text(title)
                    .textRole(.body)
            }
            .foregroundStyle(Palette.label)
            .formRowFrame()
        }
        .buttonStyle(.row)
        .systemAlert(question ?? "", isPresented: $isConfirming) {
            Button(canConfirm ? "Huỷ" : "OK", role: .cancel) {}
            if canConfirm { Button(title, action: action) }
        } message: {
            if let message { Text(message) }
        }
    }
}

/// A red text row at the end of a form ("Xoá tài khoản"), as at the end of iOS Contacts. Nothing is
/// deleted on the first tap: iOS's own confirmation sheet asks first (`question`, an optional
/// `message`, a red button repeating `title`); the phone gives a warning buzz when it goes.
/// With `choices`, the alert offers those buttons instead (each red), e.g. which account gets the
/// money back before a goal goes.
struct FormDestructiveRow: View {
    struct Choice: Identifiable {
        /// Unique per choice (an account's id), so two accounts with one name still get two buttons.
        let id: String
        let title: String
        let action: () -> Void
    }

    let title: String
    let question: String
    var message: String? = nil
    var choices: [Choice] = []
    /// False: the alert only explains (`message`) and offers "Huỷ", e.g. nowhere to send the money.
    var canConfirm = true
    /// A bin before the title, in the same red, so the row reads as "delete" at a glance.
    var icon: String? = "hugeicons-delete-02"
    let action: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) { isConfirming = true } label: {
            HStack(spacing: RowMetrics.gap) {
                if let icon {
                    RowIcon(name: icon, tint: Palette.negative)
                }
                Text(title)
                    .textRole(.body)
            }
            .foregroundStyle(Palette.negative)
            .formRowFrame()
        }
        .buttonStyle(.row)
        // A centred iOS alert, not a sheet from the button (user choice 2026-10-29).
        .systemAlert(question, isPresented: $isConfirming) {
            Button(canConfirm ? "Huỷ" : "OK", role: .cancel) {}
            if !canConfirm {
                EmptyView()
            } else if choices.isEmpty {
                Button(title, role: .destructive) {
                    Haptics.warning()
                    action()
                }
            } else {
                ForEach(choices) { choice in
                    Button(choice.title, role: .destructive) {
                        Haptics.warning()
                        choice.action()
                    }
                }
            }
        } message: {
            if let message { Text(message) }
        }
    }
}
