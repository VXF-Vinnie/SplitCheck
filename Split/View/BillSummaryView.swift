//
//  BillSummaryView.swift
//  Split
//
//  Created by Mia Nguyen on 11/21/26.
//

import SwiftUI
import SwiftData
import MapKit

//the split breakdown: restaurant banner, total + paid progress, and each person
//with their total and a paid checkbox. people list uses a List (table view).
struct BillSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    @State private var viewModel: BillSummaryViewModel

    init(bill: Bill, context: ModelContext, path: Binding<NavigationPath>) {
        _viewModel = State(initialValue: BillSummaryViewModel(bill: bill, context: context))
        _path = path
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            //--- header ---
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(Circle().stroke(Color.secondary.opacity(0.3)))
                }
                .buttonStyle(.plain)
                Text("Bill Summary").font(.title2.bold())
                Spacer()
                //edit bill: reopens the New Bill screen (items / tax / tip) for this bill.
                Button {
                    path.append(viewModel.bill)
                } label: {
                    Text("Edit Bill").font(.subheadline.weight(.medium))
                }
            }
            .padding([.horizontal, .top])

            List {
                //--- restaurant banner with a small map thumbnail (real saved coordinates) ---
                if let r = viewModel.restaurant {
                    HStack(spacing: 12) {
                        RestaurantMapThumbnail(restaurant: r)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.name).font(.subheadline.weight(.semibold))
                            Text(r.address).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        Spacer()
                    }
                }

                //--- total + paid progress ---
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(viewModel.grandTotal, format: .currency(code: "USD")).font(.headline)
                    }
                    ProgressView(value: viewModel.paidFraction)
                    Text("\(viewModel.paidCount) of \(viewModel.totalPeople) paid")
                        .font(.caption).foregroundStyle(.secondary)
                }

                //--- each person: tap the row for their summary; tap the box to mark paid ---
                Section("People") {
                    ForEach(viewModel.shares) { share in
                        HStack(spacing: 12) {
                            Button {
                                path.append(BillRoute.personSummary(share.person))
                            } label: {
                                HStack(spacing: 12) {
                                    InitialsAvatar(name: share.person.name, size: 38)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(share.person.name).foregroundStyle(.primary)
                                        Text(share.person.isPaid ? "Paid" : "Owes")
                                            .font(.caption)
                                            .foregroundStyle(share.person.isPaid ? .green : .secondary)
                                    }
                                    Spacer()
                                    Text(share.total, format: .currency(code: "USD"))
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.togglePaid(share.person)
                            } label: {
                                Image(systemName: share.person.isPaid ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(share.person.isPaid ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if viewModel.shares.isEmpty {
                    Text("No people added yet.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .listRowBackground(Color.glowCard)
        }
        .toolbar(.hidden, for: .navigationBar)
        .midnightScreen()
        //--- Save Bill: everything is already saved; this returns Home ---
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.save()
                path = NavigationPath()   //pop all the way back to Home
            } label: {
                Text("Save Bill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent))
            }
            .buttonStyle(.plain)
            .padding()
        }
    }
}

//small non-interactive map showing the saved restaurant's real coordinates.
//uses the Restaurant's stored latitude/longitude — no hardcoded values.
struct RestaurantMapThumbnail: View {
    let restaurant: Restaurant

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
    }

    var body: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(center: coordinate,
                               span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        ), interactionModes: []) {
            Marker(restaurant.name, coordinate: coordinate)
        }
        .allowsHitTesting(false)
    }
}
