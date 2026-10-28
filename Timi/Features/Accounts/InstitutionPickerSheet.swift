import SwiftUI

/// Picks a bank or e-wallet: Apple's search field under the bar, then every match with its logo,
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
                    EmptyStateCard(icon: "solar-magnifer-linear", title: "Không tìm thấy",
                                   message: "Thử tên viết tắt như “vcb”, “mb” hoặc tên đầy đủ.")
                        .padding(.top, Spacing.s)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, institution in
                            row(institution)
                                .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                        }
                    }
                    .sleekCard(padding: 0)
                }
            }
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
            .scrollDismissesKeyboard(.immediately)
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: type == .eWallet ? "Tìm ví: MoMo, ZaloPay…" : "Tìm ngân hàng: vcb, mb, techcom…")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) { dismiss() }
                    } else {
                        Button { dismiss() } label: { Image(systemName: "xmark") }
                            .accessibilityLabel("Đóng")
                    }
                }
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
            HStack(spacing: RowMetrics.gap) {
                RowIcon(name: institution.logoImage)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(institution.shortName)
                        .textRole(.body)
                        .lineLimit(1)
                    Text(institution.name)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.primary)
                }
            }
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, RowMetrics.vertical)
            .frame(minHeight: RowMetrics.minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.row)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
