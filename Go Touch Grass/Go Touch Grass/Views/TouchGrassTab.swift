//
//  TouchGrassTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import SwiftUI
import MapKit

struct TouchGrassTab: View {
    @StateObject private var viewModel = EventViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.85, green: 0.93, blue: 0.85)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Location Picker Header
                    VStack(spacing: 12) {
                        Button(action: {
                            viewModel.showLocationPicker = true
                        }) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(viewModel.selectedLocation != nil ? Color(red: 0.1, green: 0.6, blue: 0.1) : .gray)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Search Location")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if let location = viewModel.selectedLocation {
                                        Text(location.name ?? "Unknown Location")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Tap to select location")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if viewModel.selectedLocation != nil {
                                    Button(action: {
                                        viewModel.selectedLocation = nil
                                        viewModel.filterEventsByLocation()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                        }

                        // Radius indicator
                        if viewModel.selectedLocation != nil {
                            HStack(spacing: 6) {
                                Image(systemName: "location.circle")
                                    .font(.caption)
                                Text("Showing events within 50 miles")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()

                    // Events List
                    if viewModel.filteredEvents.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No events found")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("Try selecting a different location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredEvents) { event in
                                    NavigationLink(destination: LocalEventDetailView(event: event)) {
                                        LocalEventRowView(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Touch Grass")
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(selectedLocation: $viewModel.selectedLocation)
            }
            .onChange(of: viewModel.selectedLocation) { oldValue, newValue in
                viewModel.filterEventsByLocation()
            }
        }
    }
}

// MARK: - Local Event Row View
struct LocalEventRowView: View {
    let event: LocalEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: event.eventType.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
                )
                .frame(height: 180)

            // Event Info
            VStack(alignment: .leading, spacing: 8) {
                // Title and Type
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        HStack(spacing: 4) {
                            Image(systemName: event.eventType.icon)
                                .font(.caption)
                            Text(event.eventType.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                }

                // Description
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Date, Location, and Attendees
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(formatDate(event.date))
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(event.location.name ?? "Unknown Location")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.attendeeCount) attending")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(Color(red: 0.2, green: 0.3, blue: 0.2))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Local Event Detail View
struct LocalEventDetailView: View {
    let event: LocalEvent

    var body: some View {
        ZStack {
            Color(red: 0.85, green: 0.93, blue: 0.85)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image Placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: event.eventType.icon)
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                        )
                        .frame(height: 250)

                    VStack(alignment: .leading, spacing: 16) {
                        // Title and Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)

                            HStack(spacing: 6) {
                                Image(systemName: event.eventType.icon)
                                Text(event.eventType.rawValue)
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }

                        Divider()

                        // Description
                        VStack(alignment: .leading, spacing: 4) {
                            Text("About")
                                .font(.headline)
                            Text(event.description)
                                .font(.body)
                        }

                        // Date & Time
                        VStack(alignment: .leading, spacing: 4) {
                            Text("When")
                                .font(.headline)
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(formatFullDate(event.date))
                            }
                            .font(.body)
                        }

                        // Location with Map
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)

                            Map(position: .constant(MapCameraPosition.region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: event.location.latitude,
                                        longitude: event.location.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            ))) {
                                Marker(event.location.name ?? "Event Location", coordinate: CLLocationCoordinate2D(
                                    latitude: event.location.latitude,
                                    longitude: event.location.longitude
                                ))
                            }
                            .frame(height: 200)
                            .cornerRadius(12)

                            if let locationName = event.location.name {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                    Text(locationName)
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }

                        // Organizer and Attendees
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Organizer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(event.organizerName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Attending")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(event.attendeeCount) people")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(12)

                        // Join Button
                        Button(action: {
                            // TODO: Implement join event functionality
                            // - Call API to register user for event
                            // - Update attendee count
                            // - Add event to user's calendar
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Join Event")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.1, green: 0.6, blue: 0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
