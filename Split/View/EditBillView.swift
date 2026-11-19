//
//  EditBillView.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

import SwiftUI
import SwiftData

struct EditBillView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var viewModel: EditBillViewModel
    @State private var editorMode: ItemEditorMode?
    //%/Amount toggle. Starts from what the bill saved (see .onAppear).
    @State private var taxIsPercent = true
    //what the user typed in the tax field, as text. The ViewModel turns it into
    //a Decimal and decides whether it's a percent or dollars.
    @State private var taxText = ""
    //opens the Select Restaurant sheet (map + API results).
    @State private var showRestaurantPicker = false

    init(bill: Bill, context: ModelContext) {
        _viewModel = State(initialValue: EditBillViewModel(bill: bill, context: context))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                //--- top bar: back + title + edit pencil (pencil is decorative) ---
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().stroke(Color.secondary.opacity(0.3)))
                    }
                    .buttonStyle(.plain)

                    Text("New Bill").font(.title2.bold())
                    Spacer()

                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.secondary.opacity(0.3)))
                }

                //--- Restaurant: tap to open the map sheet ---
                //shows the saved restaurant (from SwiftData) once one is picked.
                Button { showRestaurantPicker = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.bill.restaurant?.name ?? "Choose restaurant")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(viewModel.bill.restaurant?.address ?? "Find nearby places on a map")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3)))
                }
                .buttonStyle(.plain)

                //--- Items ---
                Text("Items").font(.headline)

                let items = viewModel.sortedItems
                if items.isEmpty {
                    Text("No items yet — tap + Add Item.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.persistentModelID) { index, item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).foregroundStyle(.primary)
                                    //only show "2 × $5.00" when there's more than one
                                    if item.quantity > 1 {
                                        Text("\(item.quantity) × \(item.price.formatted(.currency(code: "USD")))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                //line total = price × quantity (computed, not stored)
                                Text(SplitCalculator.lineTotal(item), format: .currency(code: "USD"))
                                    .foregroundStyle(.secondary)
                                //pencil opens the edit sheet for this item
                                Button { editorMode = .edit(item) } label: {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 32, height: 32)
                                        .background(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.3)))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 12)
                            if index < items.count - 1 { Divider() }
                        }
                    }
                }

                //--- dashed Add Item button ---
                Button { editorMode = .add } label: {
                    Text("+ Add Item")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                .foregroundStyle(Color.secondary.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)

                //--- Subtotal ---
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(viewModel.subtotal, format: .currency(code: "USD"))
                }

                //--- Tax: toggle picks what the field means, label shows dollars ---
                HStack(spacing: 12) {
                    Text("Tax")
                    Picker("", selection: $taxIsPercent) {
                        Text("%").tag(true)
                        Text("Amount").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 130)

                    TextField(taxIsPercent ? "8.6" : "0.00", text: $taxText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)

                    Spacer()
                    //always the DOLLAR amount, so the user can check the math
                    Text(viewModel.bill.tax, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
                //every keystroke or toggle flip goes to the ViewModel.
                //the View never does the % math itself (that's the ViewModel's job).
                .onChange(of: taxText) { _, _ in applyTax() }
                .onChange(of: taxIsPercent) { _, _ in applyTax() }

                //validation message from the ViewModel (e.g. "Tax can't be negative")
                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                Spacer(minLength: 10)
            }
            .padding()
        }
        .toolbar(.hidden, for: .navigationBar)
        //--- bottom button (Add People is Phase II, so no action yet) ---
        .safeAreaInset(edge: .bottom) {
            Button {
                //TODO: navigate to Add People once that screen exists
            } label: {
                Text("Next: Add People")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary))
            }
            .buttonStyle(.plain)
            .padding()
        }
        .sheet(item: $editorMode) { mode in
            AddEditItemView(viewModel: viewModel, mode: mode)
        }
        .sheet(isPresented: $showRestaurantPicker) {
            SelectRestaurantView(bill: viewModel.bill, context: context)
        }
        //load the saved tax mode/value so reopening a bill shows what was entered
        .onAppear {
            taxIsPercent = viewModel.bill.taxIsPercent
            let saved = taxIsPercent ? viewModel.bill.taxRate : viewModel.bill.tax
            taxText = saved == 0 ? "" : "\(saved)"
        }
        //delete the bill if the user leaves without adding items
        .onDisappear {
            if viewModel.bill.items.isEmpty {
                context.delete(viewModel.bill)
                try? context.save()
            }
        }
    }

    //turns the typed text into a number and hands it to the ViewModel.
    //empty field = 0 tax. Decimal(string:) returns nil for junk like "1.2.3".
    private func applyTax() {
        let value = Decimal(string: taxText) ?? 0
        viewModel.setTax(value, isPercent: taxIsPercent)
    }
}
