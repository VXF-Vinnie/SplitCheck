//
//  AddEditItemView.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

import SwiftUI
import Foundation

//tells the form which mode it's in. Identifiable so it can drive .sheet(item:).
//using .sheet(item:) fixes the "edit opens blank" bug by handing the exact item to the sheet.
enum ItemEditorMode: Identifiable {
    case add
    case edit(Item)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return "edit-\(ObjectIdentifier(item).hashValue)"
        }
    }
}

//the add/edit item form (a sheet inside the EditBill screen).
//one view does double duty: add mode vs. edit mode.
struct AddEditItemView: View {
    //lets us close the sheet when done.
    @Environment(\.dismiss) private var dismiss

    //reuse the same ViewModel from EditBillView for validation + save.
    let viewModel: EditBillViewModel
    //the mode decides add vs. edit (and which item we're editing).
    let mode: ItemEditorMode

    //the item name the user is typing.
    @State private var name: String = ""
    //raw digits the user has typed. these are read as cents, so "1299" = $12.99.
    @State private var amountDigits: String = ""
    //shows an alert if the ViewModel rejects the input.
    @State private var showError = false

    //the item being edited, or nil if adding.
    private var editingItem: Item? {
        if case .edit(let item) = mode { return item }
        return nil
    }
    private var isEditing: Bool { editingItem != nil }

    //turn the typed digits into dollars (digits are cents).
    private var priceDecimal: Decimal {
        Decimal(Int(amountDigits) ?? 0) / 100
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $name)

                HStack {
                    Text("Price")
                    Spacer()
                    //the visible "$0.00" is a plain label (not editable), so the
                    //$ and . can never be deleted. an invisible text field sits on
                    //top to capture the digits, which fill in from the right.
                    ZStack(alignment: .trailing) {
                        Text(priceDecimal.formatted(.currency(code: "USD")))
                            .foregroundStyle(amountDigits.isEmpty ? .secondary : .primary)
                        TextField("", text: $amountDigits)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.clear)      //hide the field's own text
                            .multilineTextAlignment(.trailing)
                            //keep digits only, cap the length so it can't overflow.
                            .onChange(of: amountDigits) { _, newValue in
                                amountDigits = String(newValue.filter(\.isNumber).prefix(9))
                            }
                    }
                    .frame(width: 130)
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert("Can't save item", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Check the name and price.")
            }
            //prefill when editing: turn the stored price back into cents digits.
            .onAppear {
                if let item = editingItem {
                    name = item.name
                    let totalCents = NSDecimalNumber(decimal: item.price * 100).intValue
                    amountDigits = totalCents == 0 ? "" : String(totalCents)
                }
            }
        }
    }

    //decides add vs. edit, then calls the ViewModel.
    private func save() {
        let ok = isEditing
            ? viewModel.editItem(editingItem!, name: name, price: priceDecimal)
            : viewModel.addItem(name: name, price: priceDecimal)
        if ok { dismiss() } else { showError = true }
    }
}
