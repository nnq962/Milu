import Foundation

/// Danh bạ và mối quan hệ.
extension FinanceStore {
    /// "Danh bạ" A→Z as Vietnamese sorts names ("Dũng" before "Đức", "Anh" before "Ăn"), whatever
    /// language the phone is set to.
    var sortedContacts: [Contact] {
        contacts.sorted {
            $0.name.compare($1.name, options: [.caseInsensitive, .numeric], locale: .vietnam) == .orderedAscending
        }
    }

    func contact(id: Contact.ID) -> Contact? {
        contacts.first { $0.id == id }
    }

    /// The person with this name (case aside, accents count), as names are unique.
    func contact(named name: String) -> Contact? {
        contacts.first { $0.hasName(name) }
    }

    func loans(of contact: Contact) -> [Loan] {
        loans.filter { $0.contactID == contact.id }
    }

    /// Adds or changes a person. Their loans show the name, so a new one is written onto them too.
    func save(_ contact: Contact) {
        persist {
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = contact
            } else {
                contacts.append(contact)
            }
            database?.save(contact)
            for index in loans.indices where loans[index].contactID == contact.id && loans[index].name != contact.name {
                loans[index].name = contact.name
                database?.save(loans[index])
            }
        }
    }

    /// Only someone with no loans, settled ones included: a loan never loses who it is with (user
    /// choice 2026-10-29).
    func canDelete(_ contact: Contact) -> Bool {
        loans(of: contact).isEmpty
    }

    func delete(_ contact: Contact) {
        guard canDelete(contact) else { return }
        contacts.removeAll { $0.id == contact.id }
        database?.deleteContact(id: contact.id)
    }

    /// Every relationship to pick from: the built-in ones, those the user added, then "Khác" last.
    var relationships: [Relationship] {
        let builtIn = ContactRelationship.allCases.filter { $0 != .other }.map(\.relationship)
        return builtIn + customRelationships + [ContactRelationship.other.relationship]
    }

    /// "Khác" for an id that is gone, so a person always shows a relationship.
    func relationship(id: String) -> Relationship {
        ContactRelationship(rawValue: id)?.relationship
            ?? customRelationships.first { $0.id == id }
            ?? ContactRelationship.other.relationship
    }

    func contacts(in relationship: Relationship) -> [Contact] {
        contacts.filter { $0.relationshipID == relationship.id }
    }

    /// Adds or changes a relationship the user made.
    func save(_ relationship: Relationship) {
        guard !relationship.isBuiltIn else { return }
        if let index = customRelationships.firstIndex(where: { $0.id == relationship.id }) {
            customRelationships[index] = relationship
        } else {
            customRelationships.append(relationship)
        }
        database?.save(relationship)
    }

    /// Deletes a relationship the user made; the people in it move to "Khác" (user choice 2026-10-29).
    func delete(_ relationship: Relationship) {
        guard !relationship.isBuiltIn else { return }
        persist {
            for index in contacts.indices where contacts[index].relationshipID == relationship.id {
                contacts[index].relationshipID = ContactRelationship.other.rawValue
                database?.save(contacts[index])
            }
            customRelationships.removeAll { $0.id == relationship.id }
            database?.deleteRelationship(id: relationship.id)
        }
    }
}
