//
//  BillThumbnail.swift
//  Split
//
//  Created by Mia Nguyen on 11/22/26.
//

import SwiftUI

//the small square on a bill row: the restaurant's map, or a fork/knife placeholder.
struct BillThumbnail: View {
    let bill: Bill
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let r = bill.restaurant {
                RestaurantMapThumbnail(restaurant: r)   //reused from BillSummaryView
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.15))
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: size * 0.4))
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
