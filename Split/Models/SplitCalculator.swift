import Foundation
import SwiftData

// MARK: - SplitCalculator
//
// WHY THIS FILE EXISTS (say this in Phase III):
// This is pure business logic: it takes a Bill and returns what each person owes.
// It has no SwiftUI and no saving in it, so it belongs to the MODEL layer of MVVM.
// Because it's a plain function of its input, it's easy to unit test, and every
// screen that shows money (Bill Summary, Person Summary, Tip) gets the same answer.
//
// ALGORITHM (the whole thing in four steps):
//   1. Items: each item's line total (price x quantity) is divided evenly among
//      the people assigned to it. A person's "items total" is the sum of their pieces.
//   2. Tax and tip are split PROPORTIONALLY: if you ate 30% of the subtotal,
//      you pay 30% of the tax and 30% of the tip.
//   3. Every number is rounded to cents.
//   4. Rounding can make the pieces add up to a cent more or less than the real
//      total. That leftover goes to the bill owner, so the shares always add up exactly.

/// How the bill is divided. Shown in the split-method picker.
enum SplitMethod: String, CaseIterable, Identifiable {
    case byItems = "By Items"
    case evenly = "Evenly"

    var id: Self { self }
}

/// One person's breakdown. Bill Summary and Person Summary display these.
/// A plain struct (not a SwiftData @Model) because it's computed, never saved.
struct PersonShare: Identifiable {
    let person: Person
    var itemsTotal: Decimal
    var taxShare: Decimal
    var tipShare: Decimal

    /// What this person actually pays.
    var total: Decimal { itemsTotal + taxShare + tipShare }

    var id: PersistentIdentifier { person.persistentModelID }
}

enum SplitCalculator {

    /// Price x quantity for one item row.
    static func lineTotal(_ item: Item) -> Decimal {
        item.price * Decimal(item.quantity)
    }

    /// Sum of all line totals, before tax and tip.
    static func subtotal(_ bill: Bill) -> Decimal {
        bill.items.reduce(0) { $0 + lineTotal($1) }
    }

    /// Subtotal + tax + tip, rounded to cents. The shares must add up to this.
    static func grandTotal(_ bill: Bill) -> Decimal {
        (subtotal(bill) + bill.tax + bill.tipAmount).roundedToCents()
    }

    /// The main entry point: what each person on the bill owes.
    static func shares(for bill: Bill, method: SplitMethod = .byItems) -> [PersonShare] {
        let people = bill.people
        guard !people.isEmpty else { return [] }

        let subtotal = subtotal(bill)

        // STEP 1: unrounded items total per person, keyed by the person's ID.
        // We keep full precision here and round only at the end, otherwise
        // rounding errors pile up across many items.
        var rawItems: [PersistentIdentifier: Decimal] = [:]

        switch method {
        case .evenly:
            // Everyone pays the same slice of the subtotal, regardless of what they ordered.
            let slice = subtotal / Decimal(people.count)
            for person in people { rawItems[person.persistentModelID] = slice }

        case .byItems:
            for item in bill.items {
                // An item nobody is assigned to can't be charged to anyone.
                // AssignItems blocks Next until every item is assigned, so this is a safety net.
                guard !item.people.isEmpty else { continue }
                let piece = lineTotal(item) / Decimal(item.people.count)
                for person in item.people {
                    rawItems[person.persistentModelID, default: 0] += piece
                }
            }
        }

        // STEPS 2 + 3: proportional tax and tip, then round.
        var result: [PersonShare] = people.map { person in
            let itemsRaw = rawItems[person.persistentModelID] ?? 0

            // Proportional split (written by Vincent). The core idea of the app:
            // whatever fraction of the food you ate, you pay that fraction of tax and tip.
            // Example: Alex has $20 of a $30 subtotal -> ratio 2/3 -> pays 2/3 of $3 tax = $2.
            // The denominator is the WHOLE subtotal (including this person), so every
            // ratio is between 0 and 1 and all ratios add up to exactly 1.
            // Guard: a bill with no items has subtotal 0; use 0 instead of dividing by zero.
            let ratio: Decimal = subtotal > 0 ? itemsRaw / subtotal : 0
            // Multiply by the tip in DOLLARS (tipAmount), not the percent:
            // 2/3 of $6 means something, 2/3 of "20%" doesn't.
            let taxRaw: Decimal = ratio * bill.tax
            let tipRaw: Decimal = ratio * bill.tipAmount

            return PersonShare(
                person: person,
                itemsTotal: itemsRaw.roundedToCents(),
                taxShare: taxRaw.roundedToCents(),
                tipShare: tipRaw.roundedToCents()
            )
        }

        // STEP 4: fix the rounding leftover (usually -1, 0 or +1 cent).
        let sumOfShares = result.reduce(0) { $0 + $1.total }
        let leftover = grandTotal(bill) - sumOfShares
        if leftover != 0 {
            // Owner absorbs it. If nobody is flagged as owner, use the first person
            // so the totals still add up.
            let ownerIndex = result.firstIndex { $0.person.isOwner } ?? 0
            // Put it in tax so the person's item list still matches their items total.
            result[ownerIndex].taxShare += leftover
        }

        return result
    }
}

// MARK: - Decimal rounding

extension Decimal {
    /// Rounds to 2 decimal places, half up (12.345 -> 12.35).
    /// Decimal (not Double) is used for money because Double can't store 0.10 exactly.
    func roundedToCents() -> Decimal {
        var input = self
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .plain)
        return output
    }
}
