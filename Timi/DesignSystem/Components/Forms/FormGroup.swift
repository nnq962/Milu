import SwiftUI

/// Rows on a white card, with an optional heading above (the app's one heading style, as on
/// "Hũ tiết kiệm") and note below. Forms and sheets may use the heading too.
/// Put `FormDivider()` between rows. `error` replaces the note with a red message saying what to
/// fix; mark the row it is about with `isInvalid`.
struct FormGroup<Content: View>: View {
    var title: String? = nil
    var footer: String? = nil
    var error: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let title {
                // The light group heading: inside a sheet the sheet title is the strong one.
                SectionHeader(title: title, style: .group)
                    .padding(.bottom, Spacing.headerGap - Spacing.s)
            }
            VStack(spacing: 0) { content }
                .cardSurface(radius: CardCorners.inset, color: Palette.card, elevated: true)
            if let error {
                FormErrorText(text: error)
                    .padding(.horizontal, RowMetrics.horizontal)
            } else if let footer {
                FormFooter(text: footer)
            }
        }
        .animation(.easeOut(duration: 0.2), value: error)
    }
}

/// A red line saying what to fix: under a `FormGroup` (its `error`), or under a field outside one
/// (the big amount). VoiceOver reads it as it appears, since nothing else says why saving failed.
struct FormErrorText: View {
    let text: String

    var body: some View {
        Label {
            Text(text)
        } icon: {
            TimiIcon("hugeicons-alert-circle", size: 16)
        }
        .textRole(.caption)
        .foregroundStyle(Palette.red)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityAddTraits(.isStaticText)
        .onAppear { AccessibilityNotification.Announcement(text).post() }
        .onChange(of: text) { _, new in AccessibilityNotification.Announcement(new).post() }
    }
}

/// The grey note under a card (`FormGroup`'s footer); for a list card, put it right under the card
/// in a `VStack(spacing: Spacing.s)`.
struct FormFooter: View {
    let text: String

    var body: some View {
        Text(text)
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryText)
            .padding(.horizontal, RowMetrics.horizontal)
    }
}

/// Hairline between form rows, lined up with the title after the icon.
struct FormDivider: View {
    var hasIcon = true

    var body: some View {
        Palette.border
            .frame(height: 1)
            .padding(.leading, hasIcon ? RowMetrics.dividerInset : RowMetrics.horizontal)
    }
}

/// Icon, title and optional subtitle on the left of a form row.
struct FormRowLabel: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    /// Red title: this row has a problem (the group's `error` says what).
    var isInvalid = false

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            if let icon {
                FormRowIcon(icon: icon)
            }
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(title)
                    .textRole(.body)
                    .foregroundStyle(isInvalid ? Palette.red : Palette.ink)
                if let subtitle {
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
    }
}

/// A form row's icon: a glyph in ink, no tile, as in iOS Settings (user choice 2026-10-28), in the
/// same column as a list row's icon. The tiled style had no caller left and went (strict review
/// 2026-10-31).
struct FormRowIcon: View {
    let icon: String

    var body: some View {
        TimiIcon(icon, size: RowMetrics.iconGlyph)
            .foregroundStyle(Palette.ink)
            .frame(width: RowMetrics.iconColumn, height: RowMetrics.iconGlyph)
    }
}

extension View {
    func formRowFrame() -> some View {
        self
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
            .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
            .contentShape(Rectangle())
    }
}
