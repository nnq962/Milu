import SwiftUI

/// A short note in a sheet as tall as its words: the bar with ✕ and the title, the message under
/// it. For a feature still to come (Cài đặt) and Thông báo on Tổng quan, so they all look the same.
struct NoteSheet: View {
    let title: String
    let message: String

    var body: some View {
        SheetScaffold(title: title, fitsContent: true) {
            Text(message)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
                // Where a row's words start, as in every sheet.
                .padding(.horizontal, RowMetrics.horizontal)
        }
    }
}
