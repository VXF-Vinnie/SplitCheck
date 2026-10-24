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
    //decorative tax-mode toggle for now (tax entry isn't wired yet).
    @State private var taxIsPercent = true

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
                                Text(item.name).foregroundStyle(.primary)
                                Spacer()
                                Text(item.price, format: .currency(code: "USD"))
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

                //--- Tax with %/Amount toggle (visual only for now) ---
                HStack(spacing: 12) {
                    Text("Tax")
                    Picker("", selection: $taxIsPercent) {
                        Text("%").tag(true)
                        Text("Amount").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                    Spacer()
                    Text(viewModel.bill.tax, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
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
        //delete the bill if the user leaves without adding items
        .onDisappear {
            if viewModel.bill.items.isEmpty {
                context.delete(viewModel.bill)
                try? context.save()
            }
        }
    }
}
