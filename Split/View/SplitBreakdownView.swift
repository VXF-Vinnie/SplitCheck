import SwiftUI
import SwiftData

// MARK: - SplitBreakdownView
// Split-method picker + one row per person (items, tax, tip, total).
// Reusable: Mia can put this in Bill Summary.
// Check the math in Xcode's canvas preview (Alex & Sam example) at the bottom.

struct SplitBreakdownView: View {
    @State private var viewModel: SplitViewModel

    init(bill: Bill, context: ModelContext) {
        _viewModel = State(initialValue: SplitViewModel(bill: bill, context: context))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Split").font(.headline)
                Spacer()
                Picker("Split method", selection: $viewModel.method) {
                    ForEach(SplitMethod.allCases) { method in
                        Text(method.label).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if viewModel.method == .byItems && !viewModel.unassignedItems.isEmpty
                && !viewModel.bill.people.isEmpty {
                Label("\(viewModel.unassignedItems.count) item(s) not assigned to anyone yet",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if viewModel.shares.isEmpty {
                Text("Add people to see what everyone owes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.shares) { share in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(share.person.name + (share.person.isOwner ? " (owner)" : ""))
                                .font(.body)
                            Text("Items \(money(share.itemsTotal)) · Tax \(money(share.taxShare)) · Tip \(money(share.tipShare))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(share.total, format: .currency(code: "USD"))
                            .font(.body.weight(.semibold))
                    }
                    Divider()
                }
                // Proof that nothing was lost to rounding.
                HStack {
                    Text("Everyone together").foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.sharesTotal, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
    }

    private func money(_ value: Decimal) -> String {
        value.formatted(.currency(code: "USD"))
    }
}

// MARK: - Preview data (Xcode canvas only, never in the real app)

#if DEBUG
/// The Alex & Sam example: a $20 appetizer shared, a $10 drink for Alex, $3 tax, $6 tip.
/// By Items should show Alex $26.00 (20 + 2 + 4) and Sam $13.00 (10 + 1 + 2).
/// Evenly should show $19.50 each (15 + 1.50 + 3).
struct SplitPreviewSample {
    let bill: Bill
    let container: ModelContainer

    static func alexAndSam() -> SplitPreviewSample {
        // In-memory database: nothing is written to disk.
        let container = try! ModelContainer(
            for: Bill.self, Item.self, Person.self, Restaurant.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let bill = Bill(tax: 3, tipPercent: 20, tipAmount: 6)
        context.insert(bill)

        let alex = Person(name: "Alex", isOwner: true)
        let sam = Person(name: "Sam")
        let appetizer = Item(name: "Appetizer", price: 20)
        let drink = Item(name: "Drink", price: 10)
        for person in [alex, sam] { context.insert(person); bill.people.append(person) }
        for item in [appetizer, drink] { context.insert(item); bill.items.append(item) }

        appetizer.people = [alex, sam]
        drink.people = [alex]

        return SplitPreviewSample(bill: bill, container: container)
    }
}

#Preview("Alex & Sam") {
    let sample = SplitPreviewSample.alexAndSam()
    SplitBreakdownView(bill: sample.bill, context: sample.container.mainContext)
        .padding()
        .modelContainer(sample.container)
}
#endif
