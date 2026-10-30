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

/// Icon tile sizes for the optional `.tile` style; row geometry comes from RowMetrics.
enum FormMetrics {
    static let icon: CGFloat = 36
    static let iconGlyph: CGFloat = 18
    static let iconCorner: CGFloat = 10
    // Row geometry lives in RowMetrics, shared with lists and option sheets.
    static let plainGlyph = RowMetrics.iconGlyph
    static let plainColumn = RowMetrics.iconColumn
    static let gap = RowMetrics.gap
}

/// Hairline between form rows, lined up with the title after the icon tile.
struct FormDivider: View {
    var hasIcon = true

    @Environment(\.formIconStyle) private var style

    var body: some View {
        Palette.border
            .frame(height: 1)
            .padding(.leading, hasIcon ? (style == .plain ? RowMetrics.dividerInset : RowMetrics.horizontal + FormMetrics.icon + RowMetrics.gap)
                                       : RowMetrics.horizontal)
    }
}

/// Icon tile, title and optional subtitle on the left of a form row.
struct FormRowLabel: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    /// Red title: this row has a problem (the group's `error` says what).
    var isInvalid = false

    var body: some View {
        HStack(spacing: FormMetrics.gap) {
            if let icon {
                FormIconTile(icon: icon)
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

/// Neutral icon tile of a form row (web IconTile sm, tone neutral); `background` for accent tiles.
struct FormIconTile: View {
    let icon: String
    /// nil follows the group's `formIconStyle`: Palette.muted (same as list icons) or no tile.
    var background: Color? = nil

    @Environment(\.formIconStyle) private var style

    var body: some View {
        let plain = style == .plain && background == nil
        TimiIcon(icon, size: plain ? FormMetrics.plainGlyph : FormMetrics.iconGlyph)
            .foregroundStyle(Palette.ink)
            .frame(width: plain ? FormMetrics.plainColumn : FormMetrics.icon,
                   height: plain ? FormMetrics.plainGlyph : FormMetrics.icon)
            .background(background ?? (style == .tile ? Palette.muted : .clear),
                        in: RoundedRectangle(cornerRadius: FormMetrics.iconCorner, style: .continuous))
    }
}

/// Whether form and list icons sit on a muted tile (default) or stand alone.
enum FormIconStyle { case tile, plain }

private struct FormIconStyleKey: EnvironmentKey {
    // No tile by default (user choice 2026-10-28): icons stand alone as in iOS Settings.
    static let defaultValue: FormIconStyle = .plain
}

extension EnvironmentValues {
    var formIconStyle: FormIconStyle {
        get { self[FormIconStyleKey.self] }
        set { self[FormIconStyleKey.self] = newValue }
    }
}

extension View {
    /// `.plain` drops the tile behind icons in form rows and `ListRow`s inside.
    func formIconStyle(_ style: FormIconStyle) -> some View {
        environment(\.formIconStyle, style)
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
