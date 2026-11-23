import Foundation
import SwiftData

@Model
final class Person {
    var name: String
    var isPaid: Bool


    // An explicit flag, because array order isn't reliable in SwiftData.
    var isOwner: Bool

    // Back reference to the owning Bill (other end of Bill.people).
    var bill: Bill?

    // Other end of Item.people (inverse is declared on the Item side).
    var items: [Item] = []

    init(name: String, isPaid: Bool = false, isOwner: Bool = false) {
        self.name = name
        self.isPaid = isPaid
        self.isOwner = isOwner
    }
}
