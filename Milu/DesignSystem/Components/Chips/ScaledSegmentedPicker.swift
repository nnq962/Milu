import SwiftUI

/// The system segmented `Picker`, its words at the user's text size: the fonts are set for that
/// size just before the control is made, and a new size makes a new control, since UIKit keeps the
/// font it was made with (HIG review 2026-10-30: "Thu chi · Vay nợ" stayed small at large sizes).
///
/// At the accessibility sizes the choices go one under another, each the control's whole width:
/// a segment's title is one line, so side by side "Chuyển khoản" was cut from AX1 and every title
/// by AX3 (audit round 5, 2026-11-16).
struct ScaledSegmentedPicker<Value: Hashable & Identifiable>: View {
    /// What VoiceOver calls the control; the segments say their own words.
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let optionTitle: (Value) -> String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stacked
        } else {
            // A side effect in body on purpose: it must run before UIKit makes the control below.
            let _ = Typography.configureSegmentedControls(for: dynamicTypeSize)
            Picker(title, selection: $selection) {
                ForEach(options) { Text(optionTitle($0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .id(dynamicTypeSize)
        }
    }

    /// The same track and chosen card as the system control's (`fill`, the card's surface), the
    /// choices stacked, their titles wrapping.
    private var stacked: some View {
        let inset: CGFloat = 2
        return VStack(spacing: inset) {
            ForEach(options) { option in
                let isChosen = option == selection
                Button {
                    selection = option
                } label: {
                    Text(optionTitle(option))
                        .textRole(.accessory)
                        .foregroundStyle(isChosen ? Palette.label : Palette.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xs)
                        .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight)
                        .background {
                            if isChosen {
                                RoundedRectangle(cornerRadius: CardCorners.concentric(in: CardCorners.inner, inset: inset),
                                                 style: .continuous)
                                    .fill(Palette.surface)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
        .padding(inset)
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}
