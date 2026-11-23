//
//  AssignItemsView.swift
//  Split
//
//  Created by Mia Nguyen on 11/18/26.
//

import SwiftUI
import SwiftData

//assign each item to the people who shared it. items list uses a List (table view).
struct AssignItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    @State private var viewModel: AssignItemsViewModel

    init(bill: Bill, context: ModelContext, path: Binding<NavigationPath>) {
        _viewModel = State(initialValue: AssignItemsViewModel(bill: bill, context: context))
        _path = path
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            //--- header ---
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(Circle().stroke(Color.secondary.opacity(0.3)))
                }
                .buttonStyle(.plain)
                Text("Assign Items").font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal)

            //--- person selector: tap an avatar to assign items to that person ---
            Text("Select an avatar").font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.people) { person in
                        let selected = person.persistentModelID == viewModel.selectedPersonID
                        VStack(spacing: 5) {
                            InitialsAvatar(name: person.name, size: 46)
                                .overlay(
                                    Circle().stroke(Color.brandAccent, lineWidth: selected ? 3 : 0)
                                )
                            Text(person.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundStyle(selected ? .primary : .secondary)
                        }
                        .frame(width: 60)
                        .onTapGesture { viewModel.selectedPersonID = person.persistentModelID }
                    }
                }
                .padding(.horizontal)
            }

            //hint + running total for the selected person
            HStack {
                Text("Check the items this person shared")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.selectedPersonTotal, format: .currency(code: "USD"))
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal)

            //--- items list (table view) with a checkmark for the selected person ---
            List {
                ForEach(viewModel.items) { item in
                    Button {
                        viewModel.toggle(item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).foregroundStyle(.primary)
                                if item.quantity > 1 {
                                    Text("\(item.quantity) × \(item.price.formatted(.currency(code: "USD")))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                //shows who's checked on this item right now
                                Text(viewModel.sharedByText(item))
                                    .font(.caption2)
                                    .foregroundStyle(item.people.isEmpty ? .orange : .secondary)
                            }
                            Spacer()
                            Text(SplitCalculator.lineTotal(item), format: .currency(code: "USD"))
                                .foregroundStyle(.secondary)
                            Image(systemName: viewModel.isAssigned(item) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.isAssigned(item) ? Color.brandAccent : Color.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)

            //warning: items nobody is on yet (By Items mode only)
            if viewModel.bill.splitMethod == .byItems && !viewModel.unassignedItems.isEmpty {
                Label("\(viewModel.unassignedItems.count) item(s) not assigned yet",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
                    .padding(.horizontal)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .midnightScreen()
        //--- Next: blocked until every item is assigned (By Items mode) ---
        .safeAreaInset(edge: .bottom) {
            Button {
                path.append(BillRoute.billSummary(viewModel.bill))
            } label: {
                Text("Next: View Summary")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.5)
            .padding()
        }
    }
}
