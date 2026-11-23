import Foundation
import Observation
import SwiftData

//The Timeline calls this "BillViewModel"; it is named EditBillViewModel
//so it matches the MVVM diagram (Merge 1 checks that names match).
@Observable
final class EditBillViewModel {
    let bill: Bill

    //Shown by the view when validation or saving fails.
    var errorMessage: String?

    @ObservationIgnored
    private let context: ModelContext

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
    }

    //Read

    //Stable display order (SwiftData arrays are unordered).
    var sortedItems: [Item] {
        bill.items.sorted { $0.createdAt < $1.createdAt }
    }

    //Sum of price x quantity, before tax and tip.
    //Delegates to SplitCalculator so Edit Bill and the summaries can never disagree.
    var subtotal: Decimal {
        SplitCalculator.subtotal(bill)
    }

    //Add

    @discardableResult
    func addItem(name: String, price: Decimal, quantity: Int = 1) -> Bool {
        guard let cleanName = validate(name: name, price: price) else { return false }

        let item = Item(name: cleanName, price: price, quantity: quantity)
        context.insert(item)
        bill.items.append(item)
        recalculateTax()   // subtotal changed, so a percent tax must change too
        recalculateTip()   // ...and so must a percent tip
        return save()
    }

    //Edit

    @discardableResult
    func editItem(_ item: Item, name: String, price: Decimal, quantity: Int = 1) -> Bool {
        guard let cleanName = validate(name: name, price: price) else { return false }

        item.name = cleanName
        item.price = price
        item.quantity = quantity
        recalculateTax()
        recalculateTip()
        return save()
    }

    //Delete

    func deleteItem(_ item: Item) {
        bill.items.removeAll { $0.persistentModelID == item.persistentModelID }
        context.delete(item)
        recalculateTax()
        recalculateTip()
        save()
    }

    //Convenience for SwiftUI `List` + `.onDelete`, which hands back row offsets.
    func deleteItems(at offsets: IndexSet) {
        let current = sortedItems
        for index in offsets {
            deleteItem(current[index])
        }
    }

    // MARK: - Tax

    //Called by the Tax field. `input` means a percent (8.6) or dollars (4.30)
    //depending on the %/Amount toggle. Returns false and sets errorMessage if invalid.
    @discardableResult
    func setTax(_ input: Decimal, isPercent: Bool) -> Bool {
        guard input >= 0 else {
            errorMessage = "Tax can't be negative."
            return false
        }
        //Sanity cap to catch typos like 86 instead of 8.6. No US sales tax is near 30%.
        if isPercent && input > 30 {
            errorMessage = "Tax rate looks too high. Enter a percent like 8.6."
            return false
        }

        bill.taxIsPercent = isPercent
        if isPercent {
            bill.taxRate = input       // remember the rate...
            recalculateTax()           // ...and turn it into dollars
        } else {
            bill.tax = input.roundedToCents()  // dollars typed directly; a fixed amount
        }
        return save()
    }

    //Keeps a percent-based tax correct when the subtotal changes.
    //Example: 10% on $40 = $4.00. Add a $20 item -> 10% on $60 = $6.00.
    //In Amount mode we do nothing: a dollar figure copied off a receipt doesn't change.
    private func recalculateTax() {
        guard bill.taxIsPercent else { return }

        //(written by Vincent) Percent means "per hundred": 8.25% = 8.25 / 100 = 0.0825.
        //$40 subtotal x 8.25 / 100 = $3.30.
        // Round ONCE, at the end, on the dollar result. Rounding the rate first
        // (0.0825 -> 0.08) would give $3.20, which is wrong.
        bill.tax = (subtotal * bill.taxRate / 100).roundedToCents()
    }

    //Same rule as tax: a percent tip follows the subtotal; a fixed-dollar tip doesn't.
    //(TipViewModel sets the tip; this only keeps it correct when items change.)
    private func recalculateTip() {
        guard bill.tipIsPercent else { return }
        bill.tipAmount = (subtotal * bill.tipPercent / 100).roundedToCents()
    }

    //Helpers

    //Returns the trimmed name if the input is valid, otherwise sets errorMessage.
    private func validate(name: String, price: Decimal) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Item name can't be empty."
            return nil
        }
        guard price > 0 else {
            errorMessage = "Price must be greater than $0."
            return nil
        }
        return trimmed
    }

    //SwiftData autosaves, but not instantly. Saving explicitly means a
    //force-quit right after an edit (Thursday's test) won't lose data.
    @discardableResult
    private func save() -> Bool {
        do {
            try context.save()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
            return false
        }
    }
}
