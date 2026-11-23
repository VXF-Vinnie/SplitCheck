import SwiftUI
import SwiftData
import MapKit

//SelectRestaurantView
//
// Opened as a sheet from Edit Bill ("Choose restaurant").
// Top half: MapKit map with the user's dot and a pin per restaurant.
// Bottom half: a List of the same restaurants, closest first (List = our table view).
// Tapping a pin or a row selects it; "Use this restaurant" saves it to the bill.
//
// This View has no logic of its own: it reads the ViewModel's state and forwards taps.

struct SelectRestaurantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RestaurantViewModel

    init(bill: Bill, context: ModelContext) {
        _viewModel = State(initialValue: RestaurantViewModel(bill: bill, context: context))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                map
                    .frame(height: 280)

                content
            }
            .navigationTitle("Choose Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search by name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }   // restaurant is optional
                }
            }
            .safeAreaInset(edge: .bottom) { confirmButton }
            // .task runs load() when the sheet appears, and cancels it if the sheet closes.
            .task { await viewModel.load() }
        }
    }

    //Map

    private var map: some View {
        // `selection:` links pin taps to viewModel.selectedID through each Marker's .tag.
        Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedID) {
            UserAnnotation()   // the blue "you are here" dot
            ForEach(viewModel.filteredRestaurants) { result in
                Marker(result.name, systemImage: "fork.knife", coordinate: result.coordinate)
                    .tint(result.id == viewModel.selectedID ? .orange : .red)
                    .tag(result.id)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    //Loading / error / list

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Finding restaurants near you…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            // Location denied, no internet, server busy, or nothing nearby.
            ContentUnavailableView {
                Label("No restaurants", systemImage: "fork.knife.circle")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
                Button("Skip for now") { dismiss() }
            }
        } else {
            List(viewModel.filteredRestaurants) { result in
                Button { viewModel.select(result) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name).font(.body).foregroundStyle(.primary)
                            Text(result.address).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(result.distanceText).font(.caption).foregroundStyle(.secondary)
                        if result.id == viewModel.selectedID {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }

    //Confirm

    private var confirmButton: some View {
        Button {
            if viewModel.confirmSelection() { dismiss() }
        } label: {
            Text(viewModel.selectedRestaurant.map { "Use \($0.name)" } ?? "Select a restaurant")
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.selectedRestaurant == nil ? Color.secondary : Color.primary))
        }
        .buttonStyle(.plain)
        // Disabled until something is selected: the "Next stays disabled" rule.
        .disabled(viewModel.selectedRestaurant == nil)
        .padding()
        .background(.bar)
    }
}
