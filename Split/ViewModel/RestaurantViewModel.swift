import Foundation
import Observation
import SwiftData
import MapKit
import SwiftUI

// MARK: - RestaurantViewModel
//
// The "brain" of the Select Restaurant screen. In MVVM terms:
//   - It OWNS the screen's state (results, loading, error, camera, selection).
//   - It CALLS the services (LocationService, RestaurantService).
//   - It WRITES the chosen restaurant into the Model (Bill.restaurant, saved by SwiftData).
//   - It never touches the View. The View observes it: because the class is
//     @Observable, changing `restaurants` or `errorMessage` makes SwiftUI redraw.
//
// Flow (matches the sequence diagram):
//   load(): getLocation -> fetch(near:) -> decode -> results -> View redraws
//   confirmSelection(): selected result -> Restaurant model -> bill.restaurant -> save()

@Observable
final class RestaurantViewModel {

    // MARK: State the View reads

    var restaurants: [RestaurantResult] = []
    var isLoading = false
    var errorMessage: String?
    /// The ID of the tapped pin or row. Shared by the map and the list so both highlight.
    var selectedID: Int?
    /// Filters the list by name (handy when 50 places come back).
    var searchText = ""

    /// Where the map is looking. Starts on the user's location; no coordinates typed in.
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    // MARK: Dependencies

    @ObservationIgnored private let locationService = LocationService()
    @ObservationIgnored private let restaurantService = RestaurantService()
    @ObservationIgnored private let bill: Bill
    @ObservationIgnored private let context: ModelContext

    init(bill: Bill, context: ModelContext) {
        self.bill = bill
        self.context = context
    }

    // MARK: Derived

    /// What the list shows: everything, or only names containing the search text.
    var filteredRestaurants: [RestaurantResult] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return restaurants }
        return restaurants.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var selectedRestaurant: RestaurantResult? {
        restaurants.first { $0.id == selectedID }
    }

    /// Name of the restaurant already saved on the bill, if any (shown on Edit Bill).
    var currentRestaurantName: String? { bill.restaurant?.name }

    // MARK: Actions

    /// Location -> API -> results. Called when the screen appears and by Retry.
    func load() async {
        isLoading = true
        errorMessage = nil
        // `defer` runs when the function exits, success or failure,
        // so the spinner can never get stuck on.
        defer { isLoading = false }

        do {
            let coordinate = try await locationService.currentLocation()

            // Zoom the map to roughly the 2 km search area around the user.
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 4000,
                longitudinalMeters: 4000
            ))

            restaurants = try await restaurantService.fetchRestaurants(near: coordinate)
        } catch {
            // LocationError and RestaurantError both carry a user-friendly message.
            restaurants = []
            errorMessage = error.localizedDescription
        }
    }

    /// Tapping a row: select it and center the map on it.
    func select(_ result: RestaurantResult) {
        selectedID = result.id
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: result.coordinate,
                latitudinalMeters: 800,
                longitudinalMeters: 800
            ))
        }
    }

    /// Saves the selected restaurant onto the bill. Returns false if nothing is selected.
    @discardableResult
    func confirmSelection() -> Bool {
        guard let result = selectedRestaurant else { return false }

        // Bill has one Restaurant. Replacing it would orphan the old one, so delete it.
        if let old = bill.restaurant {
            context.delete(old)
        }

        // Convert the API struct into our SwiftData model. Every value here,
        // including latitude/longitude, came from the API response.
        let restaurant = Restaurant(
            name: result.name,
            address: result.address,
            latitude: result.latitude,
            longitude: result.longitude
        )
        context.insert(restaurant)
        bill.restaurant = restaurant

        do {
            try context.save()
            return true
        } catch {
            errorMessage = "Couldn't save the restaurant: \(error.localizedDescription)"
            return false
        }
    }
}
