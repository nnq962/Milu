import SwiftUI

struct EmptyPart: View {
    var body: some View {
        PartSection(part: .empty) {
            // One short sentence saying what will appear; no button named (strict review 2026-10-31).
            EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có giao dịch",
                           message: "Giao dịch trong tháng sẽ hiện ở đây.")
            EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa có hũ nào",
                           message: "Hũ tiết kiệm sẽ hiện ở đây.")
        }
    }
}
