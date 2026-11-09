import SwiftUI

/// Rows on a card, with an optional heading above (the app's one heading style, as on
/// "Hũ tiết kiệm") and note below. Forms and sheets may use the heading too.
/// Put `FormDivider()` between rows. `error` replaces the note with a red message saying what to
/// fix; mark the row it is about with `isInvalid`.
struct FormGroup<Content: View>: View {
    var title: String? = nil
    var footer: String? = nil
    var error: String? = nil
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // 8 from heading to card (`headerGap`) and from card to its note.
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            if let title {
                // The light group heading: inside a sheet the sheet title is the strong one.
                SectionHeader(title: title, style: .group)
            }
            VStack(spacing: 0) { content }
                .cardSurface(radius: CardCorners.card)
            if let error {
                FormErrorText(message: error)
                    .padding(.horizontal, RowMetrics.horizontal)
            } else if let footer {
                FormFooter(message: footer)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: error)
    }
}

/// A red line saying what to fix: under a `FormGroup` (its `error`), or under a field outside one
/// (the big amount). VoiceOver reads it as it appears, since nothing else says why saving failed.
struct FormErrorText: View {
    let message: String

    /// The glyph before the words, as on `BudgetStatusLine`, growing with them.
    @ScaledMetric(relativeTo: .caption) private var glyph = RowMetrics.inlineGlyph
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Label {
            Text(message)
        } icon: {
            TimiIcon("hugeicons-alert-circle", size: glyph)
        }
        .textRole(.caption)
        .foregroundStyle(Palette.negative)
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
        .accessibilityAddTraits(.isStaticText)
        .onAppear { AccessibilityNotification.Announcement(message).post() }
        .onChange(of: message) { _, new in AccessibilityNotification.Announcement(new).post() }
    }
}

/// The grey note under a card (`FormGroup`'s footer); for a list card, put it right under the card
/// in a `VStack(spacing: Spacing.s)`.
struct FormFooter: View {
    let message: String

    var body: some View {
        Text(message)
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryLabel)
            .padding(.horizontal, RowMetrics.horizontal)
    }
}

/// Hairline between form rows, lined up with the title after the icon: the list's `RowDivider`,
/// whose inset grows with the icons (review 2026-10-31: a fixed 54 here started before the titles
/// at large text, the bug the lists had already fixed).
struct FormDivider: View {
    var hasIcon = true

    var body: some View {
        RowDivider(column: hasIcon ? .icon : .none)
    }
}

/// Icon, title and optional subtitle on the left of a form row.
struct FormRowLabel: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    /// Red title: this row has a problem (the group's `error` says what).
    var isInvalid = false
    /// The icon's size at the default text size; the 32 column unless a row asks for more (the
    /// 32 Fluent Flat pictures of "Thêm mới", as Sổ ví's rows, user request 2026-11-05).
    var iconSize: CGFloat = RowMetrics.iconColumn
    /// Faded icon and title for a row that cannot be used; the subtitle stays as it is, since it
    /// says why ("Sắp có"), and faded grey on grey was hard to read in dark mode (review 2026-11-09).
    var isDimmed = false

    var body: some View {
        // One line: the icon's centre on the middle of the words, not on their line's box (see
        // `centeredOnTextLine`); with a subtitle, centred on the two lines.
        HStack(alignment: subtitle == nil ? .firstTextBaseline : .center, spacing: RowMetrics.gap) {
            if let icon {
                FormRowIcon(icon: icon, size: iconSize)
                    .centeredOnTextLine()
                    .opacity(isDimmed ? 0.45 : 1)
            }
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(title)
                    .textRole(.body)
                    .foregroundStyle(isInvalid ? Palette.negative : Palette.label)
                    .opacity(isDimmed ? 0.45 : 1)
                if let subtitle {
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                }
            }
        }
    }
}

/// A form row's icon: a glyph in ink, no tile, as in iOS Settings (user choice 2026-10-28), in the
/// same column as a list row's icon, growing with the text as that one does.
struct FormRowIcon: View {
    let icon: String
    var size: CGFloat = RowMetrics.iconColumn

    var body: some View {
        RowIcon(name: icon, size: size)
    }
}

extension View {
    /// In an HStack lined up on `.firstTextBaseline`: this picture's centre on the middle of the
    /// capitals of the body text beside it, half Nunito's cap height (0.705 em) above the
    /// baseline. Centred on the text's box instead, an emoji sat about 4 points low, since that
    /// box keeps more room under the words than over them (user report 2026-11-07).
    func centeredOnTextLine() -> some View {
        modifier(TextLineCentered())
    }

    func formRowFrame() -> some View {
        self
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
            .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
            .contentShape(Rectangle())
    }
}

private struct TextLineCentered: ViewModifier {
    /// Half the cap height of 16 point Nunito, growing with the text.
    @ScaledMetric(relativeTo: .body) private var lift: CGFloat = 16 * 0.705 / 2

    func body(content: Content) -> some View {
        content.alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + lift }
    }
}
