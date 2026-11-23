//
//  AddPeopleView.swift
//  Split
//
//  Created by Mia Nguyen on 11/15/26.
//

import SwiftUI
import SwiftData

//add the people splitting this bill. uses a List (table view) for the people.
struct AddPeopleView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    @State private var viewModel: AddPeopleViewModel
    @State private var nameText = ""

    //saved names from past bills, used for autocomplete.
    @Query(sort: \SavedPerson.lastUsed, order: .reverse) private var savedPeople: [SavedPerson]

    //saved names matching what's typed and not already on this bill.
    private var suggestions: [SavedPerson] {
        let q = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let onBill = Set(viewModel.people.map { $0.name.lowercased() })
        return savedPeople
            .filter { $0.name.localizedCaseInsensitiveContains(q) && !onBill.contains($0.name.lowercased()) }
            .prefix(6)
            .map { $0 }
    }

    init(bill: Bill, context: ModelContext, path: Binding<NavigationPath>) {
        _viewModel = State(initialValue: AddPeopleViewModel(bill: bill, context: context))
        _path = path
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            //--- header: back + title ---
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(Circle().stroke(Color.secondary.opacity(0.3)))
                }
                .buttonStyle(.plain)
                Text("Add People").font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal)

            //--- add-name row: field + "+" button ---
            HStack(spacing: 10) {
                TextField("First & last name", text: $nameText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addTapped() }
                Button {
                    addTapped()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 11).fill(Color.brandAccent))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            //--- autocomplete suggestions from saved names ---
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions) { s in
                            Button {
                                if viewModel.addPerson(name: s.name) { nameText = "" }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text(s.name)
                                }
                                .font(.caption)
                                .padding(.horizontal, 11).padding(.vertical, 7)
                                .background(Capsule().fill(Color.glowCard))
                                .overlay(Capsule().stroke(Color.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            //validation message (empty / duplicate)
            if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).padding(.horizontal)
            }

            //--- "People (N)" live count ---
            Text("People (\(viewModel.count))")
                .font(.headline)
                .padding(.horizontal)

            //--- list of people (table view): tap the X or swipe to delete ---
            List {
                ForEach(viewModel.people) { person in
                    HStack(spacing: 12) {
                        InitialsAvatar(name: person.name, size: 36)
                        Text(person.name)
                        if person.isOwner {
                            Text("owner")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().stroke(Color.secondary.opacity(0.4)))
                        }
                        Spacer()
                        //faded X so people know they can remove a name without discovering swipe.
                        Button {
                            viewModel.removePerson(person)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { viewModel.removePerson(viewModel.people[index]) }
                }
            }
            .listStyle(.plain)
            .overlay {
                if viewModel.people.isEmpty {
                    ContentUnavailableView("No people yet", systemImage: "person.2",
                        description: Text("Add everyone splitting this bill."))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .midnightScreen()
        //--- Next: stays disabled until at least one person is added ---
        .safeAreaInset(edge: .bottom) {
            Button {
                path.append(BillRoute.assignItems(viewModel.bill))
            } label: {
                Text("Next: Assign Items")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.count == 0)
            .opacity(viewModel.count == 0 ? 0.5 : 1)
            .padding()
        }
    }

    private func addTapped() {
        if viewModel.addPerson(name: nameText) { nameText = "" }
    }
}
