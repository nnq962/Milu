import SwiftUI

/// "Biểu tượng" in the goal form, in 3D pictures (user request 2026-11-03): two rows of six likely
/// ones, the last place "more" opening every picture in a sheet (`GoalPictureSheet`), as the line
/// icon picker did. The chosen one is ringed in lime. It still sets the line
/// icon stored on the goal (`Picture3D`), which transaction rows draw.
struct GoalPicturePicker: View {
    @Binding var selection: String
    /// Eleven icons; the twelfth place is "more".
    let suggestions: [String]

    @State private var isShowingAll = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let count = 11
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 6)

    private var shown: [String] {
        let icons = Array(suggestions.prefix(Self.count))
        return icons.contains(selection) ? icons : [selection] + icons.dropLast()
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.s) {
            ForEach(shown, id: \.self) { icon in
                Button { selection = icon } label: {
                    GoalPictureLabel(icon: icon, isSelected: icon == selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Picture3D.choice(for: icon)?.title ?? "")
                .accessibilityAddTraits(icon == selection ? .isSelected : [])
            }
            Button { isShowingAll = true } label: {
                TimiIcon("hugeicons-more-horizontal", size: RowMetrics.featureIcon / 2)
                    .foregroundStyle(Palette.label)
                    .frame(width: RowMetrics.featureIcon, height: RowMetrics.featureIcon)
                    .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: CardCorners.field, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Xem tất cả biểu tượng")
        }
        .padding(Spacing.l)
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isShowingAll) {
            GoalPictureSheet(selection: $selection)
        }
    }
}

/// One goal picture to choose: the 3D picture, ringed in lime when chosen.
struct GoalPictureLabel: View {
    let icon: String
    let isSelected: Bool
    var size: CGFloat = RowMetrics.featureIcon

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.field, style: .continuous)
        Image(Picture3D.name(for: icon))
            .resizable()
            .scaledToFit()
            .padding(size * 0.14)
            .frame(width: size, height: size)
            .overlay { if isSelected { shape.strokeBorder(Palette.accent, lineWidth: 2) } }
            .contentShape(shape)
    }
}

/// Every goal picture, in groups under small headings, five a row. Tapping one picks it and
/// closes the sheet.
struct GoalPictureSheet: View {
    @Binding var selection: String

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 5)

    var body: some View {
        SheetScaffold(title: "Biểu tượng") {
            ForEach(Picture3D.groups) { group in
                VStack(alignment: .leading, spacing: Spacing.headerGap) {
                    SectionHeader(title: group.title, style: .group)
                    LazyVGrid(columns: columns, spacing: Spacing.m) {
                        ForEach(group.choices) { choice in
                            Button {
                                selection = choice.icon
                                Haptics.selection()
                                dismiss()
                            } label: {
                                GoalPictureLabel(icon: choice.icon, isSelected: choice.icon == selection,
                                                 size: RowMetrics.iconChoice)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(choice.title)
                            .accessibilityAddTraits(choice.icon == selection ? .isSelected : [])
                        }
                    }
                    .padding(Spacing.l)
                    .cardSurface(radius: CardCorners.inset)
                }
            }
        }
        .timiSheetStyle()
    }
}
