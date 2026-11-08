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
        // The bounds where the smaller unit would round up to a thousand of itself: 999.600đ is
        // "1tr", not "1.000k" (calendar review 2026-11-04).
        switch value {
        case 999_950_000...: return sign + (value / 1_000_000_000).formatted(style) + "tỷ"
        case 999_500...: return sign + (value / 1_000_000).formatted(style) + "tr"
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
    /// "Hôm nay, 14/05", "Hôm qua, 13/05" hoặc "Thứ Hai, 12/05"
    var transactionDayTitle: String {
        let calendar = Calendar.current
        let prefix = calendar.isDateInToday(self) ? "Hôm nay"
            : calendar.isDateInYesterday(self) ? "Hôm qua"
            : formatted(.dateTime.weekday(.wide).locale(.vietnam)).capitalized(with: .vietnam)
        // Another year says which: "Thứ Ba, 27/10/2025".
        let year = calendar.isDate(self, equalTo: .now, toGranularity: .year) ? "" : "/\(calendar.component(.year, from: self))"
        return "\(prefix), \(dayMonth)\(year)"
    }

    /// The one short date of the app: "06/11", "06/11/2025" in another year (user choice
    /// 2026-11-08: dd/mm everywhere; before, "6/11").
    var shortDay: String {
        let calendar = Calendar.current
        let sameYear = calendar.isDate(self, equalTo: .now, toGranularity: .year)
        return sameYear ? dayMonth : "\(dayMonth)/\(calendar.component(.year, from: self))"
    }

    /// "22/05": two digits each, as every date of the app (user choice 2026-11-08).
    var dayMonth: String {
        let calendar = Calendar.current
        return String(format: "%02d/%02d", calendar.component(.day, from: self), calendar.component(.month, from: self))
    }

    /// Whole days from today to this date: 0 today, negative once past.
    var daysFromToday: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                       to: calendar.startOfDay(for: self)).day ?? 0
    }

    /// "Còn 8 ngày", "Hôm nay" hoặc "Quá hạn 2 ngày"
    var dueCountdown: String {
        let days = daysFromToday
        return days > 0 ? "Còn \(days) ngày" : days == 0 ? "Hôm nay" : "Quá hạn \(-days) ngày"
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
