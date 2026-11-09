import SwiftUI

/// Picks a bank or e-wallet: Apple's search field (at the bottom on iOS 26), then every match with its logo,
/// short name and full name; the current one is checked. Picking closes the sheet.
struct InstitutionPickerSheet: View {
    let type: AccountType
    @Binding var selection: String?

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var title: String { type == .eWallet ? "Chọn ví điện tử" : "Chọn ngân hàng" }
    private var results: [Institution] { Institution.search(query, in: Institution.list(for: type)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if results.isEmpty {
                    EmptyStateCard(title: "Không tìm thấy",
                                   message: type == .eWallet ? "Thử tên ngắn, như momo." : "Thử tên viết tắt, như vcb.",
                                   picture: IconCatalog.emojiName("🧭"))
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, institution in
                            row(institution)
                                .overlay(alignment: .top) {
                                    if index > 0 { RowDivider().padding(.trailing, RowMetrics.horizontal) }
                                }
                        }
                    }
                    // The card of Sổ ví, where these logos show next: its corners, the hairline
                    // stopping where the row's ✓ does (review 2026-11-06).
                    .cardSurface(radius: CardCorners.card)
                }
            }
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            // The top margin of every sheet's page (`SheetPage`, review 2026-11-07).
            .contentMargins(.top, Spacing.s, for: .scrollContent)
            .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
            .scrollDismissesKeyboard(.immediately)
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // Default placement: on iOS 26 the field sits at the bottom, by the thumb, in Liquid Glass
            // (Apple's own apps); earlier iOS keeps it under the title.
            .searchable(text: $query,
                        prompt: type == .eWallet ? "Tìm ví" : "Tìm ngân hàng")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
        }
        .timiSheetStyle()
    }

    private func row(_ institution: Institution) -> some View {
        let selected = institution.id == selection
        return Button {
            selection = institution.id
            Haptics.selection()
            dismiss()
        } label: {
            PickerRowContent(icon: institution.logoImage, title: institution.shortName,
                           subtitle: institution.name, isSelected: selected)
        }
        .buttonStyle(.row)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
