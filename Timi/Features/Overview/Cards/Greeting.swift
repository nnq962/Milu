import Foundation

/// The greeting for the time of day, on the head of Tổng quan (`OverviewHeader`).
enum Greeting {
    static func salutation(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Chào buổi sáng"
        case 12..<18: "Chào buổi chiều"
        default: "Chào buổi tối"
        }
    }
}
