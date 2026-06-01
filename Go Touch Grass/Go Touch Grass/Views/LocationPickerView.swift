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

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search for a location", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                // Map view
                Map(coordinateRegion: $region, annotationItems: selectedLocation.map { [$0] } ?? []) { location in
                    MapMarker(coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                }
                .edgesIgnoringSafeArea(.bottom)
                .onTapGesture { coordinate in
                    // Create location from tap
                    selectedLocation = Location(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        name: searchText.isEmpty ? "Selected Location" : searchText
                    )
                }

                // Current location button
                Button {
                    // Request current location
                    requestCurrentLocation()
                } label: {
                    Label("Use Current Location", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
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
        }
    }

    private func requestCurrentLocation() {
        // This is a simplified version
        // In a real implementation, you would use CLLocationManager
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()

        if let location = locationManager.location {
            selectedLocation = Location(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: "Current Location"
            )
            region.center = location.coordinate
        }
    }
}

// Extension to make Map work with tap gestures
extension View {
    func onTapGesture(perform action: @escaping (CLLocationCoordinate2D) -> Void) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    // Convert tap location to coordinate
                    // Note: This is a simplified version
                    // A proper implementation would use MapReader
                    let coordinate = CLLocationCoordinate2D(
                        latitude: 37.7749,
                        longitude: -122.4194
                    )
                    action(coordinate)
                }
        )
    }
}
