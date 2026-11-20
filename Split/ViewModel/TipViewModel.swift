import Foundation
import Observation
import SwiftData

// MARK: - TipViewModel
// Tip screen logic. User enters a percent OR dollars; we calculate the other,
// so Bill always has both tipPercent and tipAmount.
// Tip is on the subtotal (before tax). Like tax: a percent tip follows the
// subtotal when items change; a dollar tip stays fixed.

@Observable
final class TipViewModel {
    let presets: [Decimal] = [18, 20, 25]
    var errorMessage: String?

    // Bill is a SwiftData model, so the View still updates when it changes.
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

        // VINCENT'S LINE (task 4): dollars -> percent, the reverse of the tax line.
        // $6 tip / $40 subtotal = 0.15, x 100 = 15%. Same zero guard as `ratio`.
        bill.tipPercent = subtotal > 0 ? (bill.tipAmount / subtotal * 100).roundedToCents() : 0

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
