//
//  AssignItemsViewModel.swift
//  Split
//
//  Created by Mia Nguyen on 11/16/26.
//

import Foundation
import Observation
import SwiftData

//assign items screen logic: pick a person, check the items they shared.
//many-to-many: adding a person to item.people also adds the item to person.items.
@Observable
final class AssignItemsViewModel {
    @ObservationIgnored let bill: Bill
    @ObservationIgnored private let context: ModelContext

    //which person we're assigning items to right now.
    var selectedPersonID: PersistentIdentifier?

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
        selectedPersonID = bill.people.first?.persistentModelID
    }

    var people: [Person] {
        bill.people.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var items: [Item] {
        bill.items.sorted { $0.createdAt < $1.createdAt }
    }

    var selectedPerson: Person? {
        people.first { $0.persistentModelID == selectedPersonID }
    }

    //is the selected person on this item?
    func isAssigned(_ item: Item) -> Bool {
        guard let person = selectedPerson else { return false }
        return item.people.contains { $0.persistentModelID == person.persistentModelID }
    }

    //check/uncheck this item for the selected person.
    func toggle(_ item: Item) {
        guard let person = selectedPerson else { return }
        if let idx = item.people.firstIndex(where: { $0.persistentModelID == person.persistentModelID }) {
            item.people.remove(at: idx)
        } else {
            item.people.append(person)
        }
        try? context.save()
    }
    //the selected person's running items total (their share of each item they're on).
    var selectedPersonTotal: Decimal {
        guard let person = selectedPerson else { return 0 }
        var total = Decimal.zero
        for item in items where item.people.contains(where: { $0.persistentModelID == person.persistentModelID }) {
            total += SplitCalculator.lineTotal(item) / Decimal(item.people.count)
        }
        return total.roundedToCents()
    }

    //who's currently on this item, shown as a caption under its name.
    func sharedByText(_ item: Item) -> String {
        let names = item.people
            .map { $0.name.split(separator: " ").first.map(String.init) ?? $0.name }
            .sorted()
        switch names.count {
        case 0:  return "Unassigned"
        case 1:  return names[0]
        default: return "Shared by " + names.joined(separator: ", ")
        }
    }

    //items nobody is on. "By Items" can't charge these, so Next is blocked until it's empty.
    var unassignedItems: [Item] { bill.items.filter { $0.people.isEmpty } }

    //"Evenly" ignores assignment, so Next is allowed. "By Items" needs every item assigned.
    var canContinue: Bool {
        bill.splitMethod == .byItems ? unassignedItems.isEmpty : true
    }
}
