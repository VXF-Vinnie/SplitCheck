import Foundation
import Observation
import SwiftData

/// The Timeline calls this "BillViewModel"; it is named EditBillViewModel
/// so it matches the MVVM diagram (Merge 1 checks that names match).
@Observable
final class EditBillViewModel {
    let bill: Bill

    /// Shown by the view when validation or saving fails.
    var errorMessage: String?

    @ObservationIgnored
    private let context: ModelContext

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
    }

    // MARK: - Read

    /// Stable display order (SwiftData arrays are unordered).
    var sortedItems: [Item] {
        bill.items.sorted { $0.createdAt < $1.createdAt }
    }

    /// Sum of item prices, before tax and tip.
    var subtotal: Decimal {
        bill.items.reduce(0) { $0 + $1.price }
    }

    // MARK: - Add

    @discardableResult
    func addItem(name: String, price: Decimal) -> Bool {
        guard let cleanName = validate(name: name, price: price) else { return false }

        let item = Item(name: cleanName, price: price)
        context.insert(item)
        bill.items.append(item)
        return save()
    }

    // MARK: - Edit

    @discardableResult
    func editItem(_ item: Item, name: String, price: Decimal) -> Bool {
        guard let cleanName = validate(name: name, price: price) else { return false }

        item.name = cleanName
        item.price = price
        return save()
    }

    // MARK: - Delete

    func deleteItem(_ item: Item) {
        bill.items.removeAll { $0.persistentModelID == item.persistentModelID }
        context.delete(item)
        save()
    }

    /// Convenience for SwiftUI `List` + `.onDelete`, which hands back row offsets.
    func deleteItems(at offsets: IndexSet) {
        let current = sortedItems
        for index in offsets {
            deleteItem(current[index])
        }
    }

    // MARK: - Helpers

    /// Returns the trimmed name if the input is valid, otherwise sets errorMessage.
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

    /// SwiftData autosaves, but not instantly. Saving explicitly means a
    /// force-quit right after an edit (Thursday's test) won't lose data.
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
