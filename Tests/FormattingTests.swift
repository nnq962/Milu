import Foundation
import Testing
@testable import Milu

/// How money is written: in full ("1.250.000đ"), short where room is tight ("1,3tr"), and as it is
/// typed into an amount field.
struct FormattingTests {
    @Test(arguments: [
        (0.0, "0đ"),
        (1_250_000, "1.250.000đ"),
        (999, "999đ"),
        (-45_000, "-45.000đ"),
    ])
    func fullAmounts(amount: Double, text: String) {
        // The locale's own minus may differ; compare digits and grouping.
        #expect(amount.vnd.replacingOccurrences(of: "\u{2212}", with: "-") == text)
    }

    @Test(arguments: [
        (0.0, "0đ"),
        (950, "950đ"),
        (1_000, "1k"),
        (45_500, "46k"),
        (999_499, "999k"),
        // Not "1.000k": the next unit once it would round up to a thousand.
        (999_500, "1tr"),
        (1_250_000, "1,3tr"),
        (33_800_000, "33,8tr"),
        (999_949_999, "999,9tr"),
        (999_950_000, "1tỷ"),
        (2_500_000_000, "2,5tỷ"),
        (-1_250_000, "-1,3tr"),
    ])
    func shortAmounts(amount: Double, text: String) {
        #expect(amount.vndCompact == text)
    }

    @Test(arguments: [
        ("", ""),
        ("1250000", "1.250.000"),
        ("1.250.000", "1.250.000"),
        ("12a3", "123"),
        // No more than 12 digits.
        ("1234567890123", "123.456.789.012"),
    ])
    func amountsAsTyped(typed: String, shown: String) {
        #expect(typed.groupedVNDInput == shown)
    }

    @Test func typedAmountsReadBackAsNumbers() {
        #expect("1.250.000".vndInputAmount == 1_250_000)
        #expect("".vndInputAmount == 0)
    }

    @Test func searchIgnoresAccentsAndCase() {
        #expect("Tiết Kiệm".searchKey == "tiet kiem")
        #expect("Đi chợ".searchKey == "di cho")
    }
}
