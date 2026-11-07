import SwiftUI

/// The filter row of Giao dịch (Figma 239:7381, "Giao dịch / Tab bộ lọc", 2026-11-07): words
/// side by side in a capsule tray, the chosen one on a pill in the link colour (`primary`, as
/// "Tháng 11" and "Báo cáo" above it) with its words in `onPrimary`. One weight for every word,
/// so choosing one does not shift the others. The pill moves at once, no slide (user choice
/// 2026-11-07, after a SwiftUI slide stuttered and iOS's own segmented control looked out of
/// place with its grey track).
///
/// The tray is a card's white with a card's quiet edge, as wide as the cards around it. When the
/// words no longer fit one line (the accessibility sizes), the pills wrap onto more lines without
/// the tray, so none is cut at the screen's edge (review 2026-11-07).
struct SegmentPills<Option: Hashable & Identifiable>: View {
    @Binding var selection: Option
    let options: [Option]
    let optionTitle: (Option) -> String

    /// 40 tall pills in a tray 4 in, at least 62 wide, the words 16 from their ends (Figma 18: with
    /// the tray's edge, four filters then ran a few points past the page and lost the tray).
    private static var pillHeight: CGFloat { 40 }
    private static var pillMinWidth: CGFloat { 62 }
    private static var inset: CGFloat { Spacing.xs }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tray
            FlowLayout(spacing: Spacing.xs) { ForEach(options) { pill($0) } }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // One group for VoiceOver, "Bộ lọc", with the chosen pill marked as selected.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bộ lọc")
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// As wide as the cards above and below it: each pill keeps its words' width and the room
    /// left goes between them, never into a pill (shared into the pills, "Chuyển khoản" ran out).
    private var tray: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                if index > 0 { Spacer(minLength: Spacing.xs) }
                pill(option)
            }
        }
        .padding(Self.inset)
        .background(Palette.surface, in: Capsule())
        .overlay { Capsule().strokeBorder(Palette.separator, lineWidth: 1) }
    }

    private func pill(_ option: Option) -> some View {
        let selected = option == selection
        return Button { selection = option } label: {
            Text(optionTitle(option))
                .textRole(.button)
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(selected ? Palette.onPrimary : Palette.secondaryLabel)
                .padding(.horizontal, Spacing.l)
                .frame(minWidth: Self.pillMinWidth, minHeight: Self.pillHeight)
                .background { Capsule().fill(selected ? Palette.primary : .clear) }
                // The tap reaches the tray's 4 around the 40 tall pill: 48, over the HIG's 44
                // (review 2026-11-07).
                .contentShape(Rectangle().inset(by: -Spacing.xs))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
