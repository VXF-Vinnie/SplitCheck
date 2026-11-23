//
//  HomeView.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

import SwiftUI
import SwiftData

//home screen: start a new bill, see unsettled bills, and recent previous bills.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Binding var path: NavigationPath
    let isFirstTime: Bool
    @AppStorage("userName") private var userName = ""
    @State private var viewModel = HomeViewModel()

    @Query(sort: \Bill.date, order: .reverse) private var allBills: [Bill]

    //unsettled = has people and someone still hasn't paid. tap -> Bill Summary to mark paid.
    private var unsettledBills: [Bill] {
        allBills.filter { !$0.items.isEmpty && !$0.people.isEmpty && $0.people.contains { !$0.isPaid } }
    }

    //previous = has items and is NOT unsettled (no people, or everyone paid). newest 3.
    private var recentBills: [Bill] {
        Array(allBills.filter { bill in
            !bill.items.isEmpty && (bill.people.isEmpty || bill.people.allSatisfy { $0.isPaid })
        }.prefix(3))
    }

    //total still owed across every bill that has people (sum of unpaid shares).
    private var outstanding: Decimal {
        allBills.reduce(Decimal.zero) { sum, bill in
            guard !bill.items.isEmpty, !bill.people.isEmpty else { return sum }
            let unpaid = SplitCalculator.shares(for: bill)
                .filter { !$0.person.isPaid }
                .reduce(Decimal.zero) { $0 + $1.total }
            return sum + unpaid
        }.roundedToCents()
    }

    //how many saved bills in total.
    private var totalBills: Int { allBills.filter { !$0.items.isEmpty }.count }

    //one overview tile (big number + label) for the row under Start New Bill.
    private func statTile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.glowCard))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
    }

    //a wide card for an unsettled bill: restaurant, paid progress, avatars, Open.
    private func unsettledCard(_ bill: Bill) -> some View {
        let people = bill.people.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let paid = people.filter { $0.isPaid }.count
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.restaurant?.name ?? "Untitled bill")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(SplitCalculator.grandTotal(bill).formatted(.currency(code: "USD"))) · \(paid) of \(people.count) paid")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            //overlapping avatars + overflow count
            HStack(spacing: -8) {
                ForEach(people.prefix(3)) { person in
                    InitialsAvatar(name: person.name, size: 30)
                        .overlay(Circle().stroke(Color(red: 0.09, green: 0.10, blue: 0.13), lineWidth: 2))
                }
                if people.count > 3 {
                    Text("+\(people.count - 3)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.18)))
                        .overlay(Circle().stroke(Color(red: 0.09, green: 0.10, blue: 0.13), lineWidth: 2))
                }
                Spacer(minLength: 0)
            }

            Button {
                path.append(BillRoute.billSummary(bill))
            } label: {
                Text("Open")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 11).fill(Color.brandAccent))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.glowCard))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                VStack(alignment: .leading, spacing: 2) {
                    Text("Split").font(.largeTitle.bold())
                    if !userName.isEmpty {
                        Text(isFirstTime ? "Welcome to Split, \(userName)" : "Welcome back, \(userName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                //--- Start New Bill ---
                Button {
                    let bill = viewModel.startNewBill(context: context)
                    path.append(bill)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Bill")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("Start New Bill")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.title3.bold())
                            .foregroundStyle(.black)
                            .padding(10)
                            .background(Circle().fill(.white))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.brandAccent))
                }
                .buttonStyle(.plain)

                //--- Overview tiles ---
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Overview").font(.headline)
                        Text("A quick look at what's owed").font(.caption2).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 10) {
                        statTile(outstanding.formatted(.currency(code: "USD")), "Outstanding")
                        statTile("\(unsettledBills.count)", "Unsettled")
                        statTile("\(totalBills)", "Total bills")
                    }
                }

                //--- Unsettled Bills (real data) ---
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unsettled Bills").font(.headline)
                        Text("Bills where someone still owes").font(.caption2).foregroundStyle(.secondary)
                    }

                    if unsettledBills.isEmpty {
                        emptyCard("No unsettled bills right now")
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(unsettledBills) { bill in
                                    unsettledCard(bill)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                }

                //--- Previous Bills (real data) ---
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Previous Bills").font(.headline)
                            Spacer()
                            Button("See all") { path.append(HomeRoute.previousBills) }
                                .font(.subheadline)
                        }
                        Text("Settled and past bills").font(.caption2).foregroundStyle(.secondary)
                    }

                    if recentBills.isEmpty {
                        emptyCard("No bills yet")
                    } else {
                        ForEach(recentBills) { bill in
                            billRow(bill) { path.append(BillRoute.billSummary(bill)) }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .toolbar(.hidden, for: .navigationBar)
        .midnightScreen()
    }

    //a tappable bill row card (restaurant/date/total).
    private func billRow(_ bill: Bill, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                BillThumbnail(bill: bill)
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.restaurant?.name ?? "Untitled bill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(bill.date, format: .dateTime.month().day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(SplitCalculator.grandTotal(bill), format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.glowCard))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    //a dashed placeholder card for empty sections.
    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            )
    }
}
