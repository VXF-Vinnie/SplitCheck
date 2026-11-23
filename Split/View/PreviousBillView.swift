//
//  PreviousBillView.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

import SwiftUI
import SwiftData

//the Previous Bills screen: every saved bill. Edit button enables delete; tap reopens Bill Summary.
struct PreviousBillView: View {
    @Environment(\.modelContext) private var context
    @Binding var path: NavigationPath

    @Query(sort: \Bill.date, order: .reverse) private var bills: [Bill]

    private var savedBills: [Bill] { bills.filter { !$0.items.isEmpty } }

    var body: some View {
        List {
            ForEach(savedBills) { bill in
                Button {
                    path.append(BillRoute.billSummary(bill))
                } label: {
                    HStack(spacing: 12) {
                        BillThumbnail(bill: bill)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(bill.restaurant?.name ?? "Untitled bill")
                                .foregroundStyle(.primary)
                            Text(bill.date, format: .dateTime.month().day().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(SplitCalculator.grandTotal(bill), format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteBills)
        }
        .navigationTitle("Previous Bills")
        .toolbar { EditButton() }   //tap "Edit" to delete bills (swipe works too)
        .midnightScreen()
        .overlay {
            if savedBills.isEmpty {
                ContentUnavailableView(
                    "No bills yet",
                    systemImage: "clock",
                    description: Text("Bills you create will appear here.")
                )
            }
        }
    }

    //delete removes the bill and (via SwiftData cascade) its items and people.
    private func deleteBills(at offsets: IndexSet) {
        for index in offsets { context.delete(savedBills[index]) }
        try? context.save()
    }
}
