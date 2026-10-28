import SwiftUI

struct EmptyPart: View {
    var body: some View {
        PartSection(part: .empty) {
            EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có giao dịch",
                           message: "Thêm giao dịch đầu tiên để bắt đầu theo dõi.")
            EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa có hũ nào",
                           message: "Để dành cho chuyến đi, chiếc xe hay quỹ dự phòng, mỗi mục tiêu một hũ.")
        }
    }
}
