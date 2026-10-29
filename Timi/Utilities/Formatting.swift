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
    /// "Hôm nay, 14/5", "Hôm qua, 13/5" hoặc "Thứ Hai, 12/5"
    var transactionDayTitle: String {
        let calendar = Calendar.current
        let prefix = calendar.isDateInToday(self) ? "Hôm nay"
            : calendar.isDateInYesterday(self) ? "Hôm qua"
            : formatted(.dateTime.weekday(.wide).locale(.vietnam)).capitalized(with: .vietnam)
        // Another year says which: "Thứ Ba, 27/10/2025".
        let year = calendar.isDate(self, equalTo: .now, toGranularity: .year) ? "" : "/\(calendar.component(.year, from: self))"
        return "\(prefix), \(dayMonth)\(year)"
    }

    /// "22/5"
    var dayMonth: String {
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: self))/\(calendar.component(.month, from: self))"
    }

    /// "Hạn 22/5 · còn 8 ngày", "Hạn 22/5 · hôm nay" hoặc "Hạn 22/5 · quá hạn 2 ngày"
    var dueDescription: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                           to: calendar.startOfDay(for: self)).day ?? 0
        let remaining = days > 0 ? "còn \(days) ngày" : days == 0 ? "hôm nay" : "quá hạn \(-days) ngày"
        return "Hạn \(dayMonth) · \(remaining)"
    }

    /// "Hôm nay", "Hôm qua" hoặc "Thứ Năm, 16 tháng 10"
    var relativeDayTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Hôm nay" }
        if calendar.isDateInYesterday(self) { return "Hôm qua" }
        return formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam))
    }
}

extension String {
    /// "thứ tư, 28 tháng 10" → "Thứ tư, 28 tháng 10".
    var capitalizedFirstLetter: String { prefix(1).uppercased() + dropFirst() }

    /// Lower case without Vietnamese accents, to match what is typed: "Tiết kiệm" → "tiet kiem".
    var searchKey: String {
        lowercased().replacingOccurrences(of: "đ", with: "d")
            .folding(options: .diacriticInsensitive, locale: .vietnam)
    }
}
