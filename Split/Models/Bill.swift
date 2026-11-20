import Foundation
import SwiftData

@Model
final class Bill {
    var date: Date
    var tax: Decimal          // Decision 1: one bill-level tax amount (always DOLLARS)

    // How the user entered tax. If they typed a percent, we keep the rate so the
    // dollar amount can be recalculated when items change (10% of a bigger subtotal
    // is a bigger tax). Defaults keep old saved bills loading (lightweight migration).
    var taxIsPercent: Bool = true
    var taxRate: Decimal = 0  // e.g. 8.6 means 8.6%; only used when taxIsPercent

    // Same idea for tip: if the user picked a percent, the tip follows the subtotal.
    // If they typed exact dollars, the dollars stay fixed.
    var tipIsPercent: Bool = true

    // How the bill is divided. Stored as text because SwiftData saves simple types;
    // `splitMethod` below converts it to the SplitMethod enum for the rest of the app.
    var splitMethodRaw: String = "byItems"

    /// Computed (not saved): the enum version of splitMethodRaw.
    var splitMethod: SplitMethod {
        get { SplitMethod(rawValue: splitMethodRaw) ?? .byItems }
        set { splitMethodRaw = newValue.rawValue }
    }
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
