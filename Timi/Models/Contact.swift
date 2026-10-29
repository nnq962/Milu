import Foundation

/// The five relationships every install has (user choice 2026-10-29). Their raw value is the
/// relationship's id; ones the user adds get a UUID string (`Relationship`).
enum ContactRelationship: String, CaseIterable, Identifiable {
    case family, friend, colleague, acquaintance, other

    var id: Self { self }

    var title: String {
        switch self {
        case .family: "Gia đình"
        case .friend: "Bạn bè"
        case .colleague: "Đồng nghiệp"
        case .acquaintance: "Người quen"
        case .other: "Khác"
        }
    }

    var icon: String {
        switch self {
        case .family: "hugeicons-home-01"
        case .friend: "hugeicons-user-love-01"
        case .colleague: "hugeicons-briefcase-01"
        case .acquaintance: "hugeicons-handshake"
        case .other: "hugeicons-user"
        }
    }

    var relationship: Relationship {
        Relationship(id: rawValue, name: title, icon: icon)
    }
}

/// How the user knows a person: one of `ContactRelationship`, or one they added with its own name
/// and icon, which they can rename or delete (user choice 2026-10-29).
struct Relationship: Identifiable, Hashable {
    var id: String
    var name: String
    /// Asset name from `IconCatalog`.
    var icon: String

    var isBuiltIn: Bool { ContactRelationship(rawValue: id) != nil }

    static let maxNameLength = 20
}

/// A person in "Danh bạ" (Cài đặt): who a loan is with. A loan keeps the person's id
/// (`Loan.contactID`), so renaming someone here renames their loans too. Names are unique, so the
/// name typed on a loan finds its person.
struct Contact: Identifiable, Hashable {
    var id = UUID()
    var name: String
    /// A `Relationship` id: a `ContactRelationship` raw value or a UUID string.
    var relationshipID: String
    /// Made by the app from the name typed on a loan and not edited in Danh bạ since, so it goes
    /// with its last loan (user choice 2026-10-29). Saving the person in Danh bạ keeps them.
    var isAutoCreated = false

    static let maxNameLength = 40

    /// Trimmed, with runs of spaces inside made one, so twins are caught ("Minh  Trần").
    static func clean(_ name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// The same name: case aside, accents count ("Bán" is not "Bạn").
    static func sameName(_ one: String, _ other: String) -> Bool {
        one.compare(clean(other), options: .caseInsensitive) == .orderedSame
    }

    func hasName(_ other: String) -> Bool {
        Self.sameName(name, other)
    }
}
