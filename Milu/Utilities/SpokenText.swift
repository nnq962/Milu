import Foundation

/// Text as VoiceOver should say it: a day "08/10" as "8 tháng 10" (not a fraction), money "5.000đ"
/// as "5.000 đồng" (not the letter "đ"), "↑ 12%" as "tăng 12%". Used where rows show such text
/// as it is (audit round 2, 2026-11-15: only some rows read them right).
enum SpokenText {
    static func of(_ text: String) -> String {
        Change.spoken(money(days(text)))
    }

    /// "06/11" → "6 tháng 11", "06/11/2025" → "6 tháng 11, 2025", "10/2025" → "10 năm 2025".
    /// Only the app's own way of writing a day: two digits each, a real day and month. A user's
    /// "1/2 tiền nhà", "Quỹ 50/50" or "Gym 24/7" stays as typed (audit round 4, 2026-11-16).
    static func days(_ text: String) -> String {
        // What comes before is caught and put back: Swift's patterns cannot look behind.
        let months = text.replacing(/(^|[^\d\/])(\d{1,2})\/(\d{4})(?!\d)/) { match in
            "\(match.1)\(Int(match.2) ?? 0) năm \(match.3)"
        }
        return months.replacing(/(^|[^\d\/])(\d{2})\/(\d{2})(?:\/(\d{4}))?(?!\d)/) { match in
            guard let day = Int(match.2), let month = Int(match.3), (1...31).contains(day), (1...12).contains(month)
            else { return String(match.0) }
            let spoken = "\(day) tháng \(month)"
            return "\(match.1)" + (match.4.map { "\(spoken), \($0)" } ?? spoken)
        }
    }

    /// "5.000đ" → "5.000 đồng".
    static func money(_ text: String) -> String {
        text.replacing(/(\d)đ/) { "\($0.1) đồng" }
    }
}
