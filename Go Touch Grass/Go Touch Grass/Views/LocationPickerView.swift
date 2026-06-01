//
//  LocationPickerView.swift
//  Go Touch Grass
//
//  Simple location picker for activity sharing
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: Location?

    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    TextField("Search for a location", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: searchText) { newValue in
                            searchForLocation(query: newValue)
                        }

                    if isSearching {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                }
                .padding()

                // Search Results List
                if !searchResults.isEmpty && !searchText.isEmpty {
                    List(searchResults, id: \.self) { mapItem in
                        Button(action: {
                            selectSearchResult(mapItem)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mapItem.name ?? "Unknown")
                                    .font(.headline)
                                if let address = mapItem.placemark.title {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                } else {
                    // Map view
                    Map(coordinateRegion: $region, annotationItems: selectedLocation.map { [$0] } ?? []) { location in
                        MapMarker(coordinate: CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ), tint: .green)
                    }
                    .edgesIgnoringSafeArea(.bottom)

                    // Current location button
                    Button {
                        requestCurrentLocation()
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedLocation == nil)
                }
            }
            .onAppear {
                LocationManager.shared.requestLocationPermission()
            }
        }
    }

    private func searchForLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false

            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }

            searchResults = response?.mapItems ?? []
        }
    }

    private func selectSearchResult(_ mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate
        selectedLocation = Location(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            name: mapItem.name
        )

        // Update map region
        region.center = coordinate

        // Clear search
        searchText = ""
        searchResults = []
    }

    private func requestCurrentLocation() {
        // Request location permission if needed
        LocationManager.shared.requestLocationPermission()

        // Use the current location from the shared LocationManager
        LocationManager.shared.requestLocation()

        // Use a short delay to allow the location to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let coordinate = LocationManager.shared.currentLocation {
                selectedLocation = Location(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    name: "Current Location"
                )
                region.center = coordinate
            }
        }
    }
}
