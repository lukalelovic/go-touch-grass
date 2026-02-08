//
//  LocationManager.swift
//  Go Touch Grass
//
//  Manages user location services and geocoding
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentCity: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: - Singleton
    static let shared = LocationManager()

    // MARK: - Initialization
    override private init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update when user moves 100 meters
    }

    // MARK: - Public Methods

    /// Request location permission from user
    func requestLocationPermission() {
        print("Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }

    /// Start updating user location
    func startUpdatingLocation() {
        print("Starting location updates...")

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location not authorized, requesting permission...")
            requestLocationPermission()
            return
        }

        locationManager.startUpdatingLocation()
    }

    /// Stop updating user location
    func stopUpdatingLocation() {
        print("Stopping location updates...")
        locationManager.stopUpdatingLocation()
    }

    /// Get a single location update
    func requestLocation() {
        print("Requesting single location update...")

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location not authorized, requesting permission...")
            requestLocationPermission()
            return
        }

        locationManager.requestLocation()
    }

    /// Reverse geocode location to get city name
    private func reverseGeocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to get city name"
                    return
                }

                if let placemark = placemarks?.first {
                    // Try to get the most specific location name
                    if let city = placemark.locality {
                        self.currentCity = city
                        print("Current city: \(city)")
                    } else if let subLocality = placemark.subLocality {
                        self.currentCity = subLocality
                        print("Current sub-locality: \(subLocality)")
                    } else if let administrativeArea = placemark.administrativeArea {
                        self.currentCity = administrativeArea
                        print("Current administrative area: \(administrativeArea)")
                    }
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            authorizationStatus = status
            print("Location authorization changed: \(status.rawValue)")

            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location authorized, requesting location...")
                requestLocation()
            case .denied, .restricted:
                print("Location access denied or restricted")
                errorMessage = "Location access is required to find events near you"
            case .notDetermined:
                print("Location permission not determined")
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }

            print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            currentLocation = location.coordinate

            // Reverse geocode to get city name
            reverseGeocodeLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location manager error: \(error.localizedDescription)")

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    errorMessage = "Location access denied. Please enable in Settings."
                case .locationUnknown:
                    errorMessage = "Unable to determine location. Please try again."
                default:
                    errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to get location"
            }
        }
    }
}
