//
//  Formatting.swift
//  Timi
//

import SwiftUI

extension Locale {
    nonisolated static let vietnam = Locale(identifier: "vi_VN")
}

extension Double {
    /// 1250000 → "1.250.000đ"
    nonisolated var vnd: String {
        formatted(.number.locale(.vietnam).precision(.fractionLength(0))) + "đ"
    }

    /// Dạng rút gọn cho biểu đồ và nhãn nhỏ: 1250000 → "1,3tr"
    nonisolated var vndCompact: String {
        let value = abs(self)
        let sign = self < 0 ? "-" : ""
        let style = FloatingPointFormatStyle<Double>(locale: .vietnam).precision(.fractionLength(0...1))
        switch value {
        case 1_000_000_000...: return sign + (value / 1_000_000_000).formatted(style) + "tỷ"
        case 1_000_000...: return sign + (value / 1_000_000).formatted(style) + "tr"
        case 1_000...: return sign + (value / 1_000).formatted(style.precision(.fractionLength(0))) + "k"
        default: return sign + value.formatted(style.precision(.fractionLength(0))) + "đ"
        }
    }

    /// 0.35 → "35%"
    nonisolated var percentText: String {
        formatted(.percent.precision(.fractionLength(0)).locale(.vietnam))
    }
}

extension String {
    /// Tự thêm dấu chấm phân cách hàng nghìn khi gõ: 1250000 → 1.250.000
    var groupedVNDInput: String {
        let digits = String(filter { $0.isASCII && $0.isNumber }.prefix(12))
        return digits.isEmpty ? "" : (Double(digits) ?? 0).formatted(.number.locale(.vietnam))
    }

    /// "1.250.000" → 1250000
    var vndInputAmount: Double {
        Double(filter { $0.isASCII && $0.isNumber }) ?? 0
    }
}

extension Date {
    /// "Hôm nay", "Hôm qua" hoặc "Thứ Năm, 16 tháng 10"
    var relativeDayTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Hôm nay" }
        if calendar.isDateInYesterday(self) { return "Hôm qua" }
        return formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam))
    }
}

extension FinanceTransaction {
    /// "+25.000.000đ" hoặc "-55.000đ"
    var signedAmountText: String {
        (kind == .income ? "+" : "-") + amount.vnd
    }
}

enum Theme {
    static let brandGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.62, blue: 0.52), Color(red: 0.03, green: 0.36, blue: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let screenBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}
