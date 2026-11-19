import Foundation
import SwiftData

@Model
final class Item {
    var name: String
    var price: Decimal        // UNIT price (one burger), not price x quantity

    // How many of this item. The line total (price x quantity) is computed by
    // SplitCalculator.lineTotal, never stored, so it can't get out of sync.
    // Default of 1 = lightweight migration: items saved before this field existed
    // get 1 automatically, so old data loads without a crash or a migration plan.
    var quantity: Int = 1

    // SwiftData does NOT keep to-many arrays in insertion order.
    // The UI sorts by this so items don't shuffle after a relaunch.
    var createdAt: Date

    // Back-reference to the owning Bill (other end of Bill.items).
    var bill: Bill?

    // Decision 3: each Item holds the list of People sharing it.
    // Many-to-many: Person.items is the other end of this link.
    @Relationship(inverse: \Person.items)
    var people: [Person] = []

    init(name: String, price: Decimal, quantity: Int = 1, createdAt: Date = .now) {
        self.name = name
        self.price = price
        self.quantity = quantity
        self.createdAt = createdAt
    }
}
