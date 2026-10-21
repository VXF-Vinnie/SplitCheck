import Foundation
import SwiftData

@Model
final class Bill {
    var date: Date
    var tax: Decimal          // Decision 1: one bill-level tax amount
    var tipPercent: Decimal   // Decision 2: store both...
    var tipAmount: Decimal    // ...and compute whichever the user didn't enter

    // Composition (filled diamond): deleting a Bill deletes its Items.
    // `inverse` tells SwiftData that Item.bill is the other end of this same link.
    @Relationship(deleteRule: .cascade, inverse: \Item.bill)
    var items: [Item] = []

    // Composition: deleting a Bill deletes its People.
    @Relationship(deleteRule: .cascade, inverse: \Person.bill)
    var people: [Person] = []

    // Bill 1 -> 1 Restaurant (Decision 4). Optional because the bill exists
    // before the user picks a restaurant on the Location screen.
    @Relationship(deleteRule: .cascade)
    var restaurant: Restaurant?

    init(
        date: Date = .now,
        tax: Decimal = 0,
        tipPercent: Decimal = 0,
        tipAmount: Decimal = 0,
        restaurant: Restaurant? = nil
    ) {
        self.date = date
        self.tax = tax
        self.tipPercent = tipPercent
        self.tipAmount = tipAmount
        self.restaurant = restaurant
    }
}
