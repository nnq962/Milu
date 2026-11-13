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
        // The row's name as its label, the value once as its value: the label's words already
        // held the value, so VoiceOver read it twice (review 2026-11-07).
        .accessibilityLabel(title)
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

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Toggle(isOn: $isOn) {
            // Dimmed with the switch when it cannot be used: the label sets its own colours,
            // which `.disabled` alone leaves at full ink (review 2026-11-09).
            FormRowLabel(title: title, subtitle: subtitle, icon: icon, isDimmed: !isEnabled)
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
        // On the words' baseline, not centred: Nunito keeps room above for Vietnamese marks, so a
        // › centred on the line sat above the words beside it (user report 2026-11-07).
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            // Value at the right of the label; under it at the accessibility sizes, where one
            // line cut "Hôm nay, 13:…" short (review 2026-10-31).
            AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                FormRowLabel(title: title, icon: icon, isInvalid: isInvalid)
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    if let valueIcon {
                        RowIcon(name: valueIcon, size: IconSize.valueArtwork)
                            .centeredOnTextLine()
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
        // On the words' baseline as every one-line row; the figure keeps its room by priority,
        // and goes under the title at the accessibility sizes (review 2026-11-07).
        AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            FormRowLabel(title: title)
            Spacer(minLength: Spacing.s)
            MoneyText(amount: amount, tone: tone)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // One line: the › on the words' baseline (see `FormValueRowContent`); with a subtitle,
        // centred on the two lines. At the accessibility sizes the value goes under the title,
        // as `FormValueRowContent` does: beside it "30.000.000đ" was cut short (review 2026-11-09).
        let row = HStack(alignment: subtitle == nil && !stacksValue ? .firstTextBaseline : .center, spacing: Spacing.s) {
            if stacksValue, let value {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    FormRowLabel(title: title, subtitle: subtitle, icon: icon, iconSize: iconSize)
                    valueText(value)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FormRowLabel(title: title, subtitle: subtitle, icon: icon, iconSize: iconSize)
                Spacer(minLength: Spacing.s)
                if let value { valueText(value) }
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

    private var stacksValue: Bool { dynamicTypeSize.isAccessibilitySize && value != nil }

    private func valueText(_ value: String) -> some View {
        Text(value)
            .textRole(.body)
            .foregroundStyle(Palette.secondaryLabel)
            .monospacedDigit()
            .lineLimit(1)
    }
}

/// Opens something else: value and › on the right.
struct FormNavigationRow: View {
    /// What the row's end says it does: › pushes a page, ↗ leaves the app (Mail), nothing for a
    /// sheet over this one, as iOS draws them (review 2026-11-09: › on all three).
    enum Accessory { case chevron, external, none }

    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var value: String? = nil
    var accessory: Accessory = .chevron
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: subtitle == nil ? .firstTextBaseline : .center, spacing: Spacing.s) {
                FormRowLabel(title: title, subtitle: subtitle, icon: icon)
                Spacer(minLength: Spacing.s)
                if let value {
                    Text(value)
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(1)
                }
                switch accessory {
                case .chevron: RowChevron()
                case .external:
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: IconSize.chevron, weight: .semibold))
                        .foregroundStyle(Palette.tertiaryLabel)
                        .accessibilityHidden(true)
                case .none: EmptyView()
                }
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

    var body: some View {
        Button {
            if let question { confirm(question) } else { action() }
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
    }

    /// iOS's alert, shown by UIKit (`NativeAlert`): in a sheet over a sheet, SwiftUI's lost its
    /// buttons' actions.
    private func confirm(_ question: String) {
        var buttons: [NativeAlert.Button] = [.cancel(canConfirm ? "Huỷ" : "OK")]
        if canConfirm { buttons.append(.init(title: title, action: action)) }
        NativeAlert.show(question, message: message, buttons: buttons)
    }
}

/// A red text row at the end of a form ("Xoá tài khoản"), as at the end of iOS Contacts. Nothing is
/// deleted on the first tap: iOS's own alert asks first (`question`, an optional
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
    /// False: the alert only explains (`message`) and offers "OK", e.g. nowhere to send the money.
    var canConfirm = true
    /// A bin before the title, in the same red, so the row reads as "delete" at a glance.
    var icon: String? = "hugeicons-delete-02"
    /// False when this alert only leads to a second ask: the warning tick belongs to the step
    /// that really deletes (review 2026-11-09).
    var warns = true
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: confirm) {
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
    }

    /// A centred iOS alert, not a sheet from the button (user choice 2026-10-29), shown by UIKit
    /// (`NativeAlert`): in a sheet over a sheet, SwiftUI's alert rebuilt the form and its red
    /// button then deleted nothing (2026-11-13).
    private func confirm() {
        var buttons: [NativeAlert.Button] = [.cancel(canConfirm ? "Huỷ" : "OK")]
        if canConfirm {
            if choices.isEmpty {
                let warns = warns, action = action
                buttons.append(.init(title: title, role: .destructive) {
                    if warns { Haptics.warning() }
                    action()
                })
            } else {
                buttons += choices.map { choice in
                    .init(title: choice.title, role: .destructive) {
                        Haptics.warning()
                        choice.action()
                    }
                }
            }
        }
        NativeAlert.show(question, message: message, buttons: buttons)
    }
}
