import Foundation
import SwiftData

@Model
final class Item {
    var name: String
    var price: Decimal

    // SwiftData does NOT keep to-many arrays in insertion order.
    // The UI sorts by this so items don't shuffle after a relaunch.
    var createdAt: Date

    // Back-reference to the owning Bill (other end of Bill.items).
    var bill: Bill?

    // Decision 3: each Item holds the list of People sharing it.
    // Many-to-many: Person.items is the other end of this link.
    @Relationship(inverse: \Person.items)
    var people: [Person] = []

    init(name: String, price: Decimal, createdAt: Date = .now) {
        self.name = name
        self.price = price
        self.createdAt = createdAt
    }
}
