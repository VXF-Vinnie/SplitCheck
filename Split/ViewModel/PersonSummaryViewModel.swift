//
//  PersonSummaryViewModel.swift
//  Split
//
//  Created by Mia Nguyen on 11/21/26.
//

import Foundation
import Observation
import SwiftData

//one person's breakdown. pulls their PersonShare from SplitCalculator so the
//numbers match the Bill Summary exactly.
@Observable
final class PersonSummaryViewModel {
    @ObservationIgnored let person: Person
    @ObservationIgnored private let context: ModelContext

    init(person: Person, context: ModelContext) {
        self.person = person
        self.context = context
    }

    var bill: Bill? { person.bill }
    var splitMethod: SplitMethod { person.bill?.splitMethod ?? .byItems }

    //this person's row from the calculator (items total, tax share, tip share, total).
    var share: PersonShare? {
        guard let bill = person.bill else { return nil }
        return SplitCalculator.shares(for: bill)
            .first { $0.person.persistentModelID == person.persistentModelID }
    }

    //the items this person is on (By Items mode).
    var items: [Item] {
        person.items.sorted { $0.createdAt < $1.createdAt }
    }

    //this person's portion of one item = line total / number of people on it.
    func portion(of item: Item) -> Decimal {
        let count = max(item.people.count, 1)
        return (SplitCalculator.lineTotal(item) / Decimal(count)).roundedToCents()
    }

    //"Mark as Paid" — flips the same flag the Bill Summary checkbox uses.
    func togglePaid() {
        person.isPaid.toggle()
        try? context.save()
    }
}
