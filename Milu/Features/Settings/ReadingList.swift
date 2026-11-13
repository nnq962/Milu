import SwiftUI

/// One entry of a page to read under Cài đặt: its title in ink and bold, then its paragraphs in
/// grey. No bullets, so every page reads the same way (user request 2026-11-12: Câu hỏi thường
/// gặp and the legal pages looked different, and the legal pages mixed bullets with paragraphs).
struct ReadingEntry: Identifiable {
    let title: String
    let paragraphs: [String]
    var id: String { title }

    init(_ title: String, _ paragraphs: String...) {
        self.title = title
        self.paragraphs = paragraphs
    }
}

/// A pushed page of `ReadingEntry`s in one card, a line between them: Câu hỏi thường gặp,
/// Chính sách quyền riêng tư, Điều khoản sử dụng. `note` goes under the card (when it was updated).
struct ReadingListView: View {
    let title: String
    let entries: [ReadingEntry]
    var note: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(entry.title)
                                .textRole(.bodyStrong)
                                .foregroundStyle(Palette.label)
                            VStack(alignment: .leading, spacing: Spacing.s) {
                                ForEach(Array(entry.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                                    Text(paragraph)
                                        .textRole(.body)
                                        .foregroundStyle(Palette.secondaryLabel)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, RowMetrics.horizontal)
                        .padding(.vertical, Spacing.l)
                        .separatorAbove(index > 0, order: index) { FormDivider(hasIcon: false) }
                        .accessibilityElement(children: .combine)
                    }
                }
                .listCard()

                if let note {
                    Text(note)
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryLabel)
                        .padding(.horizontal, RowMetrics.horizontal)
                }
            }
            .textSelection(.enabled)
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
