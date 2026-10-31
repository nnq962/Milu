import SwiftUI

/// A short note in a sheet as tall as its words: ✕ and the title on top, the message under it.
/// For a feature still to come (Cài đặt) and Thông báo / Timi Pro on Tổng quan, so they all look
/// the same (sheet review 2026-10-30: Tổng quan had its own, with "Đóng" on the right).
struct NoteSheet: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: title)
            Text(message)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .timiFittedSheet()
    }
}
