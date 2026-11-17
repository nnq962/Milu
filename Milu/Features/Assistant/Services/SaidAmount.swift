import Foundation

/// Money as people say it in Vietnamese, read on the phone: "60k", "60 nghìn", "1tr2", "1 triệu
/// 2", "1,5tr", "2 củ", "1 củ rưỡi", "2 trăm rưỡi", "1 tỷ", "60.000", "60000đ". Milu checks the
/// amount the model read against these, and asks when they differ, so a number it made up is
/// never put on a card (user choice 2026-11-17). Numbers said in words ("sáu mươi nghìn") are not
/// read: the model's is trusted then.
enum SaidAmount {
    /// The amount `text` says: the first one said with its unit or in full ("60k", "60.000"), else
    /// the first bare small number, taken as thousands ("35" is 35.000đ; "2 ly cà phê 35k" is 35k).
    static func parse(_ text: String) -> Double? {
        let found = amounts(in: text)
        return (found.first { $0.asSaid == nil } ?? found.first)?.value
    }

    /// Every amount `text` could mean: a bare number under 1.000 both as said and as thousands, as
    /// "35" for 35.000đ is how people say it, and a date's "15" may be one too.
    static func all(in text: String) -> Set<Double> {
        var values = Set<Double>()
        for amount in amounts(in: text) {
            values.insert(amount.value)
            if let said = amount.asSaid { values.insert(said) }
        }
        return values
    }

    private struct Amount {
        var value: Double
        /// The number as said, when `value` took it as thousands.
        var asSaid: Double?
    }

    private static let units: [String: Double] = [
        "k": 1_000, "nghin": 1_000, "ngan": 1_000,
        "tr": 1_000_000, "trieu": 1_000_000, "cu": 1_000_000,
        "ty": 1_000_000_000, "ti": 1_000_000_000,
        "tram": 100,
        "d": 1, "dong": 1, "vnd": 1,
    ]

    private static func amounts(in text: String) -> [Amount] {
        let (tokens, attached) = tokenize(text.searchKey.lowercased())
        var found: [Amount] = []
        var index = 0
        while index < tokens.count {
            guard isNumber(tokens[index]) else { index += 1; continue }
            let (value, next, explicit) = readGroup(tokens, attached: attached, from: index)
            index = next
            guard let value, value > 0 else { continue }
            // "35", "2 trăm rưỡi": no word of thousands or đồng, under 1.000, is in thousands.
            if !explicit, value < 1_000 {
                found.append(Amount(value: value * 1_000, asSaid: value))
            } else {
                found.append(Amount(value: value.rounded(), asSaid: nil))
            }
        }
        return found
    }

    /// One amount from `start`: a number, its unit, then what may follow it ("rưỡi", "1tr2"'s "2",
    /// "1 triệu 2 trăm nghìn"'s smaller part). Whether a unit of thousands or đồng was said.
    private static func readGroup(_ tokens: [String], attached: [Bool], from start: Int) -> (Double?, Int, Bool) {
        var index = start
        let numberToken = tokens[index]
        index += 1
        let unitToken = index < tokens.count ? tokens[index] : nil
        guard let unitToken, let unit = units[unitToken] else {
            return (number(numberToken, decimal: false), index, false)
        }
        index += 1
        guard var value = number(numberToken, decimal: unit > 1).map({ $0 * unit }) else { return (nil, index, true) }
        var explicit = unit != 100
        if unit > 1 {
            if index < tokens.count, tokens[index] == "ruoi" {
                value += unit / 2
                index += 1
            } else if index < tokens.count, isNumber(tokens[index]) {
                let after = index + 1 < tokens.count ? tokens[index + 1] : nil
                if let after, let smaller = units[after], smaller < unit, smaller > 1 {
                    // "1 triệu 2 trăm nghìn": the smaller part on its own, added.
                    let (part, next, partExplicit) = readGroup(tokens, attached: attached, from: index)
                    if let part {
                        // "1 triệu 2 trăm": hundreds of thousands, as said.
                        value += (!partExplicit && part < 1_000) ? part * 1_000 : part
                        index = next
                    }
                } else if after.map({ units[$0] == nil }) ?? true,
                          // Thousands only written as one ("2k5"): "35k 2 ly" is 35.000đ.
                          unit >= 1_000_000 || attached[index] {
                    // "1tr2", "1 triệu 200", "2k5": the next digits are tenths, hundredths... of it.
                    let digits = tokens[index].filter(\.isNumber)
                    if let tail = Double(digits), digits.count <= 3 {
                        value += tail * unit / pow(10, Double(digits.count))
                        index += 1
                    }
                }
            }
        }
        // "2 trăm rưỡi nghìn": hundreds, then thousands.
        if unit == 100, index < tokens.count, let thousands = units[tokens[index]], thousands == 1_000 {
            value *= thousands
            explicit = true
            index += 1
        }
        return (value, index, explicit)
    }

    /// Words and numbers apart: "1tr2" is "1", "tr", "2"; and whether each was written against the
    /// one before it, with no space ("2k5"'s "5").
    private static func tokenize(_ text: String) -> ([String], [Bool]) {
        var tokens: [String] = []
        var attached: [Bool] = []
        var current = ""
        var currentIsNumber = false
        var currentAttached = false
        func flush() {
            guard !current.isEmpty else { return }
            // A number ending in "." or "," ("60k." at a sentence's end) loses it.
            if currentIsNumber, let last = current.last, last == "." || last == "," { current.removeLast() }
            tokens.append(current)
            attached.append(currentAttached)
            current = ""
        }
        for character in text {
            let isNumber = character.isNumber
                || ((character == "." || character == ",") && currentIsNumber && !current.isEmpty)
            guard isNumber || character.isLetter else {
                flush()
                currentAttached = false
                continue
            }
            // From letters to digits or back with no space: the next token touches this one.
            if !current.isEmpty, isNumber != currentIsNumber {
                flush()
                currentAttached = true
            }
            currentIsNumber = isNumber
            current.append(character)
        }
        flush()
        return (tokens, attached)
    }

    private static func isNumber(_ token: String) -> Bool {
        token.first?.isNumber == true
    }

    /// "60.000" and "60,000" are sixty thousand; with a unit, "1,5" and "1.5" are one and a half.
    private static func number(_ token: String, decimal: Bool) -> Double? {
        if decimal { return Double(token.replacingOccurrences(of: ",", with: ".")) ?? JSONValue.string(token).number }
        return JSONValue.string(token).number
    }
}
