//
//  HomeViewModel.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

import Foundation
import SwiftData

//ViewModel for the Home screen.
//@Observable lets SwiftUI watch it and refresh the view when its data changes.
@Observable
final class HomeViewModel {

    //called when the user taps "Start New Bill".
    //1. Makes a brand new empty Bill.
    //2. context.insert() tells SwiftData to start tracking/saving it.
    //3. Returns the bill so the view can navigate into it.
    func startNewBill(context: ModelContext) -> Bill {
        let bill = Bill()
        context.insert(bill)
        return bill
    }
}
