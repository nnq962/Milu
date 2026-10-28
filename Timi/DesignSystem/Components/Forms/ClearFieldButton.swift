import SwiftUI

/// Same glyph as UITextField's own clear button; keeps the keyboard up.
struct ClearFieldButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 17))
                .foregroundStyle(Palette.secondary.opacity(0.6))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Xoá nội dung")
    }
}
