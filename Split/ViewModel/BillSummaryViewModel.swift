//
//  BillSummaryViewModel.swift
//  Split
//
//  Created by Mia Nguyen on 11/20/26.
//

import Foundation
import Observation
import SwiftData

//bill summary logic: reads per-person shares from SplitCalculator (never does math itself),
//tracks paid progress, and flips the paid flag.
@Observable
final class BillSummaryViewModel {
    @ObservationIgnored let bill: Bill
    @ObservationIgnored private let context: ModelContext

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
    }

    var restaurant: Restaurant? { bill.restaurant }

    //what each person owes (items + proportional tax + proportional tip).
    var shares: [PersonShare] { SplitCalculator.shares(for: bill) }

    //the whole bill.
    var grandTotal: Decimal { SplitCalculator.grandTotal(bill) }

    //paid progress for the bar + "X of Y paid" label.
    var paidCount: Int { bill.people.filter { $0.isPaid }.count }
    var totalPeople: Int { bill.people.count }
    var paidFraction: Double {
        totalPeople == 0 ? 0 : Double(paidCount) / Double(totalPeople)
    }

    //flipped by the checkbox. Person Summary's "Mark as Paid" flips the same flag.
    func togglePaid(_ person: Person) {
        person.isPaid.toggle()
        try? context.save()
    }

    //bills save continuously; this just makes sure the latest state is on disk.
    func save() { try? context.save() }
}
