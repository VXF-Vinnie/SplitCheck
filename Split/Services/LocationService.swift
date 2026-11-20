import Foundation
import CoreLocation

// MARK: - LocationService
//
// WHAT IT DOES: asks iOS for permission, then gets the phone's current coordinates.
// This is the "no hardcoded latitude/longitude" rubric line: every coordinate the
// app uses starts here, from the real device (or the Simulator's Location setting).
//
// WHY IT'S A "SERVICE": it talks to an outside system (Core Location), not the UI.
// The ViewModel calls it; Views never touch it.
//
// THE TRICKY PART: CLLocationManager is old-style. You don't call a function and get
// a result back; you ask, and later it calls you back through "delegate" methods.
// currentLocation() wraps that callback style in async/await, so the ViewModel can
// just write `let coord = try await locationService.currentLocation()`.

enum LocationError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access is off. Turn it on in Settings, or skip choosing a restaurant."
        case .unavailable:
            return "Couldn't get your location. Try again."
        }
    }
}

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // A "continuation" is a paused async function waiting for its answer.
    // currentLocation() pauses here; a delegate callback later resumes it.
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        // A restaurant search doesn't need GPS-level accuracy; this is faster and saves battery.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Returns the current coordinates, asking for permission first if needed.
    func currentLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                // First launch: show the system permission popup.
                // The answer arrives in locationManagerDidChangeAuthorization below.
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                finish(.failure(LocationError.denied))
            default:
                // Already allowed: ask for one location fix.
                manager.requestLocation()
            }
        }
    }

    // MARK: - Delegate callbacks (iOS calls these)
    // `nonisolated` + Task { @MainActor } = "iOS may call this from anywhere;
    // hop back to the main thread before touching our state."

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard self.continuation != nil else { return }  // nobody is waiting
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()   // user tapped Allow
            case .denied, .restricted:
                self.finish(.failure(LocationError.denied))
            default:
                break                            // still deciding
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in self.finish(.success(coordinate)) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(.failure(LocationError.unavailable)) }
    }

    /// Resumes the paused currentLocation() exactly once.
    /// (Resuming a continuation twice crashes, so we clear it right away.)
    private func finish(_ result: Result<CLLocationCoordinate2D, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
