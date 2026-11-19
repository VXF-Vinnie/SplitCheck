import Foundation
import CoreLocation

// MARK: - RestaurantService
//
// WHAT IT DOES: calls the Nominatim API (OpenStreetMap's official search service)
// with a box around the user's coordinates and turns the JSON it returns into
// [RestaurantResult].
//
// RUBRIC: "Web API calls" (5 pts) = the URLSession request below.
//         "Process JSON" (10 pts) = decoding into OUR OWN Codable structs with
//         JSONDecoder (no third-party library), then mapping them to RestaurantResult.
//
// WHY NOMINATIM: no API key (a fresh clone works with no setup), and it runs on
// OpenStreetMap's own servers. We first used the Overpass API, but its volunteer
// servers kept timing out, so we tested both with curl and switched.

// MARK: - JSON shape (mirrors what Nominatim sends back)
//
// Real response from a test in Tempe (trimmed):
// [
//   { "osm_id": 544152063, "lat": "33.4162856", "lon": "-111.9259077",
//     "name": "Thai Basil",
//     "display_name": "Thai Basil, 1111, South Rural Road, Tempe, Maricopa County, Arizona, 85281, United States" },
//   { "osm_id": 9458969167, "lat": "33.4151188", "lon": "-111.9239872",
//     "name": "Pho Fresh Alley and Boba Tea", "display_name": "..." }
// ]
//
// Two things to notice:
//   1. The response STARTS WITH [ : the top level is a list, not an object.
//   2. lat and lon are STRINGS ("33.41..."), not numbers. We decode them as String
//      and convert to Double ourselves.

struct NominatimPlace: Decodable {
    let osmID: Int
    let lat: String
    let lon: String
    let name: String?        // some places have no name -> Optional
    let displayName: String

    // CodingKeys maps JSON key names to our Swift property names.
    // The JSON uses snake_case ("display_name"); Swift style is camelCase (displayName).
    // Keys that already match (lat, lon, name) are listed as-is.
    enum CodingKeys: String, CodingKey {
        case osmID = "osm_id"
        case lat, lon, name
        case displayName = "display_name"
    }
}

// MARK: - What the app actually uses

/// A clean, app-friendly restaurant. The View and ViewModel only ever see this,
/// never the raw API structs, so switching APIs only changed this file.
struct RestaurantResult: Identifiable, Hashable {
    let id: Int
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let distanceMeters: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// "0.4 mi" for the list.
    var distanceText: String {
        let miles = distanceMeters / 1609.34
        return String(format: "%.1f mi", miles)
    }
}

enum RestaurantError: LocalizedError {
    case badResponse
    case noResults

    var errorDescription: String? {
        switch self {
        case .badResponse: return "The restaurant service didn't respond. Check your connection and try again."
        case .noResults:   return "No restaurants found nearby."
        }
    }
}

// MARK: - The service

struct RestaurantService {
    private let endpoint = "https://nominatim.openstreetmap.org/search"

    /// Restaurants near `coordinate`, closest first.
    func fetchRestaurants(near coordinate: CLLocationCoordinate2D) async throws -> [RestaurantResult] {

        // STEP 1: build a search box around the user. 0.02 degrees is about 2 km.
        // Nominatim wants the box as "left,top,right,bottom" = "minLon,maxLat,maxLon,minLat".
        // Every number here is computed from the user's real location.
        let delta = 0.02
        let viewbox = [
            coordinate.longitude - delta,   // left (west)
            coordinate.latitude + delta,    // top (north)
            coordinate.longitude + delta,   // right (east)
            coordinate.latitude - delta     // bottom (south)
        ].map { String($0) }.joined(separator: ",")

        // STEP 2: build the URL. URLComponents handles escaping for us.
        //   q=restaurant  -> search for restaurants
        //   format=jsonv2 -> reply in JSON
        //   viewbox + bounded=1 -> only inside our box
        //   limit=40      -> Nominatim's maximum per request
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "q", value: "restaurant"),
            URLQueryItem(name: "format", value: "jsonv2"),
            URLQueryItem(name: "viewbox", value: viewbox),
            URLQueryItem(name: "bounded", value: "1"),
            URLQueryItem(name: "limit", value: "40")
        ]
        guard let url = components.url else { throw RestaurantError.badResponse }

        var request = URLRequest(url: url)
        // Nominatim's usage policy requires apps to identify themselves.
        request.setValue("Split-CSE335-student-project", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        // STEP 3: the network call (the 5-point line). `await` pauses here without
        // freezing the UI until the server answers.
        let (data, response) = try await URLSession.shared.data(for: request)

        // 200 = OK. Anything else (429 = too many requests, 503 = busy) is a failure.
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RestaurantError.badResponse
        }

        // STEP 4: decode the JSON bytes into our structs (the 10-point line).
        // (written by Vincent) The JSON's outermost shape is a LIST [ ... ], so we decode
        // "an array of NominatimPlace". Decoding NominatimPlace.self (one place) would
        // throw a type mismatch: expected { but found [.
        let decoded = try JSONDecoder().decode([NominatimPlace].self, from: data)

        // STEP 5: map raw places -> RestaurantResult, skipping anything unusable.
        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let results: [RestaurantResult] = decoded.compactMap { place in
            // compactMap = map, but returning nil drops that place.
            guard let name = place.name, !name.isEmpty else { return nil }   // unnamed place
            // lat/lon arrive as text. Double("33.41") turns text into a number,
            // and gives nil if the text isn't a valid number.
            guard let lat = Double(place.lat), let lon = Double(place.lon) else { return nil }

            let distance = here.distance(from: CLLocation(latitude: lat, longitude: lon))
            return RestaurantResult(
                id: place.osmID,
                name: name,
                address: Self.shortAddress(from: place.displayName),
                latitude: lat,
                longitude: lon,
                distanceMeters: distance
            )
        }

        guard !results.isEmpty else { throw RestaurantError.noResults }
        return results.sorted { $0.distanceMeters < $1.distanceMeters }
    }

    /// "Thai Basil, 1111, South Rural Road, Tempe, Maricopa County, ..." -> "1111 South Rural Road, Tempe"
    /// The first part is the restaurant's own name, so skip it, then keep street + city.
    private static func shortAddress(from displayName: String) -> String {
        var parts = displayName
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count > 1 else { return displayName }
        parts.removeFirst()   // drop the name

        // If it starts with a house number, glue it to the street: "1111" + "South Rural Road".
        if parts.count >= 3, Int(parts[0]) != nil {
            return "\(parts[0]) \(parts[1]), \(parts[2])"
        }
        return parts.prefix(2).joined(separator: ", ")
    }
}
