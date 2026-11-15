import Foundation

/// Text as VoiceOver should say it: a day "08/10" as "8 tháng 10" (not a fraction), money "5.000đ"
/// as "5.000 đồng" (not the letter "đ"), "↑ 12%" as "tăng 12%". Used where rows show such text
/// as it is (audit round 2, 2026-11-15: only some rows read them right).
enum SpokenText {
    static func of(_ text: String) -> String {
        Change.spoken(money(days(text)))
    }

    /// "06/11" → "6 tháng 11", "06/11/2025" → "6 tháng 11, 2025".
    static func days(_ text: String) -> String {
        text.replacing(/(\d{1,2})\/(\d{1,2})(?:\/(\d{4}))?/) { match in
            let day = "\(Int(match.1) ?? 0) tháng \(Int(match.2) ?? 0)"
            return match.3.map { "\(day), \($0)" } ?? day
        }
    }

    /// "5.000đ" → "5.000 đồng".
    static func money(_ text: String) -> String {
        text.replacing(/(\d)đ/) { "\($0.1) đồng" }
    }
}
