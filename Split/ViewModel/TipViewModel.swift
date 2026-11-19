import Foundation
import Observation
import SwiftData

// MARK: - TipViewModel
//
// The Tip screen's logic. The user can pick a preset (18/20/25%), type a custom
// percent, or type an exact dollar amount. Whichever one they enter, we calculate
// the other, so Bill always has BOTH tipPercent and tipAmount filled in
// (that was "Decision 2" in the Bill model).
//
// Tip is calculated on the SUBTOTAL (food only), not on subtotal + tax.
// That's the common US convention and what most receipts' tip guides use.
//
// Same rule as tax:
//   - percent mode -> tipIsPercent = true, and EditBillViewModel recalculates the
//     dollars whenever items change (20% of a bigger bill is a bigger tip).
//   - dollar mode  -> tipIsPercent = false, and the dollars stay fixed.

@Observable
final class TipViewModel {
    let presets: [Decimal] = [18, 20, 25]
    var errorMessage: String?

    // The Bill is a SwiftData @Model, which is already observable, so SwiftUI
    // still redraws when bill.tipAmount changes even though we ignore it here.
    @ObservationIgnored private let bill: Bill
    @ObservationIgnored private let context: ModelContext

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
    }

    // MARK: Read

    var subtotal: Decimal { SplitCalculator.subtotal(bill) }
    var tax: Decimal { bill.tax }
    var tipPercent: Decimal { bill.tipPercent }
    var tipAmount: Decimal { bill.tipAmount }
    var tipIsPercent: Bool { bill.tipIsPercent }

    /// Subtotal + tax + tip: the "New Total" line.
    var newTotal: Decimal { SplitCalculator.grandTotal(bill) }

    /// Dollar amount shown under each preset button ("20%  $10.90").
    func amount(forPercent percent: Decimal) -> Decimal {
        (subtotal * percent / 100).roundedToCents()
    }

    /// Highlights the preset button that matches the current tip.
    func isSelected(_ preset: Decimal) -> Bool {
        bill.tipIsPercent && bill.tipPercent == preset
    }

    // MARK: Actions

    /// Preset button or custom percent field. Percent in, dollars calculated.
    @discardableResult
    func setPercent(_ percent: Decimal) -> Bool {
        guard percent >= 0, percent <= 100 else {
            errorMessage = "Tip percent must be between 0 and 100."
            return false
        }
        bill.tipIsPercent = true
        bill.tipPercent = percent
        // Same math as your tax line: subtotal x percent / 100, rounded once at the end.
        bill.tipAmount = amount(forPercent: percent)
        return save()
    }

    /// Custom dollar field. Dollars in, percent calculated (the reverse direction).
    @discardableResult
    func setAmount(_ dollars: Decimal) -> Bool {
        guard dollars >= 0 else {
            errorMessage = "Tip can't be negative."
            return false
        }
        bill.tipIsPercent = false
        bill.tipAmount = dollars.roundedToCents()

        // -------------------------------------------------------------------
        // YOUR TURN (1 line): work out what percent of the subtotal this tip is,
        // so the screen can show "Tip: 15% · $6.00" even when dollars were typed.
        //   It's the reverse of percent -> dollars:  $6 tip on a $40 subtotal = 15%.
        //   Think about your `ratio` line in SplitCalculator: part / whole, but then
        //   turn the fraction into a percent number (0.15 -> 15).
        //   Same divide-by-zero guard as `ratio`: if subtotal is 0, use 0.
        //   Shape: bill.tipPercent = ______ ? ______ : 0
        // Delete the #warning when done.
        #warning("YOUR TURN: set bill.tipPercent from the dollar amount")
        // -------------------------------------------------------------------

        return save()
    }

    // MARK: Helpers

    @discardableResult
    private func save() -> Bool {
        do {
            try context.save()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Couldn't save the tip: \(error.localizedDescription)"
            return false
        }
    }
}
