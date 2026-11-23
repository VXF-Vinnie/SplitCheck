import Foundation
import Observation
import SwiftData

// Backs the split-method picker and the per-person breakdown (SplitBreakdownView).
// It doesn't do any math itself: it asks SplitCalculator, which reads the bill's
// saved split method. Changing the picker saves the new method to SwiftData.

@Observable
final class SplitViewModel {
    @ObservationIgnored let bill: Bill
    @ObservationIgnored private let context: ModelContext

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
    }

    //The picker binds to this. Setting it saves the choice on the bill.
    var method: SplitMethod {
        get { bill.splitMethod }
        set {
            bill.splitMethod = newValue
            try? context.save()
        }
    }

    //What each person owes, using the current method.
    var shares: [PersonShare] { SplitCalculator.shares(for: bill) }

    //Should always equal grandTotal (the owner absorbs the rounding cent).
    var sharesTotal: Decimal { shares.reduce(0) { $0 + $1.total } }
    var grandTotal: Decimal { SplitCalculator.grandTotal(bill) }

    //Items nobody is assigned to. In "By Items" mode these aren't charged to anyone,
    //so the screen warns about them. (Assign Items blocks Next until this is empty.)
    var unassignedItems: [Item] { bill.items.filter { $0.people.isEmpty } }
}
