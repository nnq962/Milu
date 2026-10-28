import SwiftUI

enum GoalIcon: String, CaseIterable, Identifiable {
    case piggyBank = "mdi-piggy-bank"
    case car = "mdi-car-outline"
    case airplane = "mdi-airplane"

    var id: Self { self }

    var title: String {
        switch self {
        case .piggyBank: "Tiết kiệm"
        case .car: "Xe cộ"
        case .airplane: "Du lịch"
        }
    }
}

/// Hũ tiết kiệm có mục tiêu; số đã để dành được tính vào tài sản.
struct SavingsGoal: Identifiable, Hashable {
    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    var name: String
    var icon: GoalIcon
    var saved: Double
    var target: Double

    var progress: Double { target > 0 ? min(saved / target, 1) : 0 }
    var remaining: Double { max(target - saved, 0) }
}
