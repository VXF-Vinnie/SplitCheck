//
//  HomeView.swift
//  Split
//
//  Created by Mia Nguyen on 10/23/26.
//

import SwiftUI
import SwiftData

//the Welcome / Home screen. matches the mockup layout.
//functional: Start New Bill, See all, and tapping a recent bill.
//decorative (no action yet): the top menu + icon buttons.
struct HomeView: View {
    //swiftData context, used when creating a new bill.
    @Environment(\.modelContext) private var context
    //shared navigation history from ContentView.
    @Binding var path: NavigationPath
    //this screen's ViewModel.
    @State private var viewModel = HomeViewModel()

    //all saved bills, newest first, used for the Previous Bills preview.
    @Query(sort: \Bill.date, order: .reverse) private var allBills: [Bill]

    //show up to 3 recent non-empty bills on the home screen.
    private var recentBills: [Bill] {
        Array(allBills.filter { !$0.items.isEmpty }.prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                //--- top bar (decorative for now) ---
                HStack {
                    //menu grid icon
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.3)))

                    Spacer()

                    //two round icon buttons (search + notifications)
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .frame(width: 40, height: 40)
                        .background(Circle().stroke(Color.secondary.opacity(0.3)))
                    Image(systemName: "bell")
                        .foregroundStyle(.secondary)
                        .frame(width: 40, height: 40)
                        .background(Circle().stroke(Color.secondary.opacity(0.3)))
                }

                //--- Start New Bill card (functional) ---
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
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary))
                }
                .buttonStyle(.plain)

                //--- Unsettled Bills (empty state for now) ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("Unsettled Bills")
                        .font(.headline)

                    VStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .background(Circle().stroke(Color.secondary.opacity(0.3)))
                        Text("No unsettled bills right now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                    )
                }

                //--- Previous Bills preview (functional) ---
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Previous Bills")
                            .font(.headline)
                        Spacer()
                        Button("See all") {
                            path.append(HomeRoute.previousBills)
                        }
                        .font(.subheadline)
                    }

                    if recentBills.isEmpty {
                        //placeholder card when there are no saved bills yet
                        Text("No bills yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.secondary.opacity(0.25)))
                    } else {
                        ForEach(recentBills) { bill in
                            Button {
                                path.append(bill)
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bill.restaurant?.name ?? "Untitled bill")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(bill.date, format: .dateTime.month().day().year())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(bill.items.reduce(Decimal(0)) { $0 + $1.price },
                                         format: .currency(code: "USD"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.secondary.opacity(0.25)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        //hide the nav bar on Home so the custom top row matches the mockup.
        //pushed screens (EditBill, PreviousBill) still get their own nav bar + back button.
        .toolbar(.hidden, for: .navigationBar)
    }
}
