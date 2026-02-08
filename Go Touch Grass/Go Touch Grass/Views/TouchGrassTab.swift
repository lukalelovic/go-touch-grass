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
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        NavigationStack {
            ZStack {
                colors.primaryBackground
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
                                    .foregroundColor(viewModel.selectedLocation != nil ? colors.accent : .gray)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Search Location")
                                        .font(.caption)
                                        .foregroundColor(colors.secondaryText)

                                    if let location = viewModel.selectedLocation {
                                        Text(location.name ?? "Unknown Location")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(colors.primaryText)
                                    } else {
                                        Text("Tap to select location")
                                            .font(.subheadline)
                                            .foregroundColor(colors.secondaryText)
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
                            .background(colors.cardBackground)
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
                            .foregroundColor(colors.secondaryText)
                        }
                    }
                    .padding()

                    // Loading indicator
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading events...")
                                .font(.caption)
                                .foregroundColor(colors.secondaryText)
                            Spacer()
                        }
                    }
                    // Error message
                    else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(colors.secondaryText)
                                Spacer()
                                Button("Dismiss") {
                                    viewModel.errorMessage = nil
                                }
                                .font(.caption)
                                .foregroundColor(colors.accent)
                            }
                            .padding()
                            .background(colors.cardBackground)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    // Events List
                    else if viewModel.filteredEvents.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: viewModel.selectedLocation == nil ? "mappin.slash" : "calendar.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(colors.tertiaryText)
                            Text(viewModel.selectedLocation == nil ? "Select a location" : "No events found")
                                .font(.title3)
                                .foregroundColor(colors.secondaryText)
                            Text(viewModel.selectedLocation == nil ? "Tap the location picker above to find events near you" : "Try selecting a different location")
                                .font(.caption)
                                .foregroundColor(colors.secondaryText)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredEvents) { event in
                                    NavigationLink(destination: LocalEventDetailView(event: event, viewModel: viewModel, themeManager: themeManager)) {
                                        LocalEventRowView(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await viewModel.refreshEvents()
                        }
                    }
                }
            }
            .navigationTitle("Touch Grass")
            .toolbarBackground(colors.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(selectedLocation: $viewModel.selectedLocation)
            }
            .alert("Daily Limit Reached", isPresented: $viewModel.showRateLimitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can only search for events once per day to conserve API usage.\n\nIf you've already searched a location today, those events are cached and available. For new locations, please try again tomorrow!")
            }
            .onChange(of: viewModel.selectedLocation) { oldValue, newValue in
                Task {
                    await viewModel.loadEvents()
                }
            }
            .onAppear {
                // Request user's location on first appear
                viewModel.requestUserLocation()
            }
        }
    }
}

// MARK: - Local Event Row View
struct LocalEventRowView: View {
    let event: LocalEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Map Preview
            Map(position: .constant(.region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: event.location.latitude,
                    longitude: event.location.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))) {
                Marker("", coordinate: CLLocationCoordinate2D(
                    latitude: event.location.latitude,
                    longitude: event.location.longitude
                ))
                .tint(.green)
            }
            .frame(height: 180)
            .allowsHitTesting(false)

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
                            if let icon = event.eventType.icon {
                                Image(systemName: icon)
                                    .font(.caption)
                            }
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

                    // Only show attendee count if >= 5
                    if event.attendeeCount >= 5 {
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
    @ObservedObject var viewModel: EventViewModel
    @ObservedObject var themeManager: ThemeManager
    @State private var showAttendanceConfirmation = false

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        ZStack {
            colors.primaryBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image Placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Group {
                                if let icon = event.eventType.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        )
                        .frame(height: 250)

                    VStack(alignment: .leading, spacing: 16) {
                        // Title and Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(colors.primaryText)

                            HStack(spacing: 6) {
                                if let icon = event.eventType.icon {
                                    Image(systemName: icon)
                                }
                                Text(event.eventType.rawValue)
                            }
                            .font(.subheadline)
                            .foregroundColor(colors.secondaryText)
                        }

                        Divider()
                            .background(colors.divider)

                        // Description
                        VStack(alignment: .leading, spacing: 4) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)
                            Text(event.description)
                                .font(.body)
                                .foregroundColor(colors.primaryText)
                        }

                        // Date & Time
                        VStack(alignment: .leading, spacing: 4) {
                            Text("When")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(formatFullDate(event.date))
                            }
                            .font(.body)
                            .foregroundColor(colors.primaryText)
                        }

                        // Location with Map
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)

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
                                .foregroundColor(colors.secondaryText)
                            }
                        }

                        // Organizer and Attendees
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Organizer")
                                    .font(.caption)
                                    .foregroundColor(colors.secondaryText)
                                Text(event.organizerName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(colors.primaryText)
                            }

                            Spacer()

                            // Only show attendee count if >= 5
                            if event.attendeeCount >= 5 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Attending")
                                        .font(.caption)
                                        .foregroundColor(colors.secondaryText)
                                    Text("\(event.attendeeCount) people")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(colors.primaryText)
                                }
                            }
                        }
                        .padding()
                        .background(colors.cardBackground)
                        .cornerRadius(12)

                        // Mark as Attended Button
                        Button(action: {
                            Task {
                                await viewModel.joinEvent(event)
                                showAttendanceConfirmation = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Attended")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.accent)
                            .cornerRadius(12)
                        }
                        .alert("Event Marked as Attended", isPresented: $showAttendanceConfirmation) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("This event has been added to your attended events list!")
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
