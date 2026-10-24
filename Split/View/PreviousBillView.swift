//
//  PreviousBillView.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

import SwiftUI
import SwiftData

//the Previous Bills screen: a history list of every saved bill.
struct PreviousBillView: View {
    //shared navigation history, so tapping a bill can push into the editor.
    @Binding var path: NavigationPath

    //@Query automatically fetches all saved Bills and keeps this list live.
    //sorted newest-first by date.
    @Query(sort: \Bill.date, order: .reverse) private var bills: [Bill]

    //safety net: only show bills that actually have items, so a stray
    //empty bill never appears here.
    private var savedBills: [Bill] { bills.filter { !$0.items.isEmpty } }

    var body: some View {
        List {
            ForEach(savedBills) { bill in
                //tapping a past bill reopens it in the item editor.
                Button {
                    path.append(bill)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            //restaurant name if one was picked, otherwise a placeholder.
                            Text(bill.restaurant?.name ?? "Untitled bill")
                                .foregroundStyle(.primary)
                            //the bill's date.
                            Text(bill.date, format: .dateTime.month().day().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        //quick total = sum of this bill's item prices.
                        Text(bill.items.reduce(Decimal(0)) { $0 + $1.price },
                             format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Previous Bills")
        //empty state when no bills have been saved yet.
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
}
