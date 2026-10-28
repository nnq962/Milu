import SwiftUI

struct EmptyPart: View {
    var body: some View {
        PartSection(part: .empty) {
            EmptyStateCard(icon: "solar-inbox-linear", title: "Chưa có giao dịch",
                           message: "Thêm giao dịch đầu tiên để bắt đầu theo dõi.")
        }
    }
}
