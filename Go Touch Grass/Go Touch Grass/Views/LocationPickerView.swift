//
//  LocationPickerView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: Location?

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search for a place", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            searchLocation()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Search Results List
                if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults, id: \.self) { item in
                            Button(action: {
                                selectLocation(item)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown")
                                        .font(.headline)

                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                } else if !searchText.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer()

                // Map Preview (if location selected)
                if let location = selectedLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Location")
                            .font(.headline)
                            .padding(.horizontal)

                        Map(position: $cameraPosition) {
                            Marker(location.name ?? "Selected Location", coordinate: CLLocationCoordinate2D(
                                latitude: location.latitude,
                                longitude: location.longitude
                            ))
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Text(location.name ?? "Unknown Location")
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Select Location")
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
        }
    }

    private func searchLocation() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            searchResults = response.mapItems
        }
    }

    private func selectLocation(_ mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate

        selectedLocation = Location(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            name: mapItem.name
        )

        // Update camera position to show selected location
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))

        // Clear search
        searchText = ""
        searchResults = []
    }
}
