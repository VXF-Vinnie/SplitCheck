//
//  AddPeopleViewModel.swift
//  Split
//
//  Created by Mia Nguyen on 11/15/26.
//

import Foundation
import Observation
import SwiftData

//add people screen logic: add/remove people, block empty + duplicate names.
//the first person added is marked the bill owner (they absorb the rounding cent).
@Observable
final class AddPeopleViewModel {
    @ObservationIgnored let bill: Bill
    @ObservationIgnored private let context: ModelContext

    //shown by the view when a name is empty or a duplicate.
    var errorMessage: String?

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
    }

    //people on the bill, sorted by name so the list doesn't shuffle after a relaunch.
    var people: [Person] {
        bill.people.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var count: Int { bill.people.count }

    //add a person. returns false (and sets errorMessage) if the name is blank or a duplicate.
    @discardableResult
    func addPerson(name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Name can't be empty."
            return false
        }
        let exists = bill.people.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
        guard !exists else {
            errorMessage = "\(trimmed) is already on the bill."
            return false
        }
        //first person on the bill becomes the owner.
        let person = Person(name: trimmed, isOwner: bill.people.isEmpty)
        context.insert(person)
        bill.people.append(person)
        remember(trimmed)        //save the name for autocomplete next time
        errorMessage = nil
        save()
        return true
    }

    //upsert a name into the saved-people list (for autocomplete on future bills).
    private func remember(_ name: String) {
        let saved = (try? context.fetch(FetchDescriptor<SavedPerson>())) ?? []
        if let match = saved.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            match.lastUsed = .now
        } else {
            context.insert(SavedPerson(name: name))
        }
    }

    //remove a person. if they were the owner, hand owner to the first remaining person.
    func removePerson(_ person: Person) {
        let wasOwner = person.isOwner
        bill.people.removeAll { $0.persistentModelID == person.persistentModelID }
        context.delete(person)
        if wasOwner, let newOwner = bill.people.first {
            newOwner.isOwner = true
        }
        save()
    }

    private func save() { try? context.save() }
}
