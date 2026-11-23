//
//  PersonSummaryView.swift
//  Split
//
//  Created by Mia Nguyen on 11/21/26.
//

import SwiftUI
import SwiftData

//one person's itemized breakdown + their tax/tip share + a Mark as Paid button.
struct PersonSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PersonSummaryViewModel

    init(person: Person, context: ModelContext) {
        _viewModel = State(initialValue: PersonSummaryViewModel(person: person, context: context))
    }

    var body: some View {
        List {
            //--- person header ---
            HStack(spacing: 12) {
                InitialsAvatar(name: viewModel.person.name, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.person.name).font(.headline)
                    Text(viewModel.person.isPaid ? "Paid" : "Owes")
                        .font(.caption)
                        .foregroundStyle(viewModel.person.isPaid ? .green : .secondary)
                }
                Spacer()
            }

            //--- items ---
            Section("Items") {
                if viewModel.splitMethod == .evenly {
                    //evenly mode doesn't use item assignment; explain the equal share.
                    Text("This bill is split evenly — everyone pays an equal share of all items.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if viewModel.items.isEmpty {
                    Text("No items assigned to this person.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.items) { item in
                        HStack {
                            Text(item.name)
                            //"Shared ×N" tag when more than one person is on the item.
                            if item.people.count > 1 {
                                Text("Shared ×\(item.people.count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().stroke(Color.secondary.opacity(0.4)))
                            }
                            Spacer()
                            Text(viewModel.portion(of: item), format: .currency(code: "USD"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            //--- breakdown (from the calculator) ---
            if let share = viewModel.share {
                Section("Breakdown") {
                    row("Items", share.itemsTotal)
                    row("Tax share", share.taxShare)
                    row("Tip share", share.tipShare)
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(share.total, format: .currency(code: "USD")).font(.headline)
                    }
                }
            }
        }
        .listRowBackground(Color.glowCard)
        .navigationTitle(viewModel.person.name)
        .navigationBarTitleDisplayMode(.inline)
        .midnightScreen()
        //--- Mark as Paid / Unpaid ---
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.togglePaid()
            } label: {
                Text(viewModel.person.isPaid ? "Mark as Unpaid" : "Mark as Paid")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(viewModel.person.isPaid ? Color.secondary : Color.brandAccent))
            }
            .buttonStyle(.plain)
            .padding()
        }
    }

    //one label + dollar amount row.
    private func row(_ label: String, _ amount: Decimal) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(amount, format: .currency(code: "USD")).foregroundStyle(.secondary)
        }
    }
}
