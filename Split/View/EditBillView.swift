//
//  EditBillView.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

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

    //shared navigation path so "Next: Add People" can push the next screen.
    @Binding var path: NavigationPath

    @State private var viewModel: EditBillViewModel
    @State private var editorMode: ItemEditorMode?
    @State private var taxIsPercent = true
    @State private var taxText = ""
    @State private var showRestaurantPicker = false
    @State private var showTipSheet = false

    init(bill: Bill, context: ModelContext, path: Binding<NavigationPath>) {
        _viewModel = State(initialValue: EditBillViewModel(bill: bill, context: context))
        _path = path
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
                                    if item.quantity > 1 {
                                        Text("\(item.quantity) × \(item.price.formatted(.currency(code: "USD")))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(SplitCalculator.lineTotal(item), format: .currency(code: "USD"))
                                    .foregroundStyle(.secondary)
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

                //--- Tax ---
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
                    Text(viewModel.bill.tax, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
                .onChange(of: taxText) { _, _ in applyTax() }
                .onChange(of: taxIsPercent) { _, _ in applyTax() }

                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                //--- Tip: tap to open the Tip sheet ---
                Button { showTipSheet = true } label: {
                    HStack {
                        Text("Tip").foregroundStyle(.primary)
                        Spacer()
                        if viewModel.bill.tipAmount > 0 {
                            Text("\(viewModel.bill.tipPercent.formatted(.number.precision(.fractionLength(0...1))))% · \(viewModel.bill.tipAmount.formatted(.currency(code: "USD")))")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Add tip").foregroundStyle(.orange)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Divider()

                //--- Total ---
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text(SplitCalculator.grandTotal(viewModel.bill), format: .currency(code: "USD"))
                        .font(.headline)
                }

                //--- Split method + per-person preview (fills in after people are added) ---
                SplitBreakdownView(bill: viewModel.bill, context: context)
                    .padding(.top, 8)

                Spacer(minLength: 10)
            }
            .padding()
        }
        .toolbar(.hidden, for: .navigationBar)
        .midnightScreen()
        //--- Next: Add People (wired). disabled until there's at least one item ---
        .safeAreaInset(edge: .bottom) {
            Button {
                path.append(BillRoute.addPeople(viewModel.bill))
            } label: {
                Text("Next: Add People")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.sortedItems.isEmpty)
            .opacity(viewModel.sortedItems.isEmpty ? 0.5 : 1)
            .padding()
        }
        .sheet(item: $editorMode) { mode in
            AddEditItemView(viewModel: viewModel, mode: mode)
        }
        .sheet(isPresented: $showRestaurantPicker) {
            SelectRestaurantView(bill: viewModel.bill, context: context)
        }
        .sheet(isPresented: $showTipSheet) {
            TipView(bill: viewModel.bill, context: context)
        }
        .onAppear {
            taxIsPercent = viewModel.bill.taxIsPercent
            let saved = taxIsPercent ? viewModel.bill.taxRate : viewModel.bill.tax
            taxText = saved == 0 ? "" : "\(saved)"
        }
        .onDisappear {
            if viewModel.bill.items.isEmpty {
                context.delete(viewModel.bill)
                try? context.save()
            }
        }
    }

    private func applyTax() {
        let value = Decimal(string: taxText) ?? 0
        viewModel.setTax(value, isPercent: taxIsPercent)
    }
}
