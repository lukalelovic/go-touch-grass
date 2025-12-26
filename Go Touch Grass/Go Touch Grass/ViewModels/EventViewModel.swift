//
//  EventViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine
import CoreLocation

@MainActor
class EventViewModel: ObservableObject {
    @Published var selectedLocation: Location?
    @Published var showLocationPicker = false
    @Published var events: [LocalEvent] = []
    @Published var filteredEvents: [LocalEvent] = []
    @Published var isLoading = false

    private let radiusMiles: Double = 50

    init() {
        loadEvents()
    }

    // MARK: - Public Methods

    func loadEvents() {
        // Load sample events
        events = LocalEvent.sampleEvents
        filteredEvents = events

        // TODO: Fetch events from external API
        // - Call events API (e.g., Eventbrite, Meetup, custom backend)
        // - Parse response into LocalEvent objects
        // - Update events array
        // isLoading = true
        // do {
        //     events = try await eventService.fetchEvents()
        //     filterEventsByLocation()
        // } catch {
        //     print("Error loading events: \(error)")
        // }
        // isLoading = false
    }

    func filterEventsByLocation() {
        guard let userLocation = selectedLocation else {
            filteredEvents = events
            return
        }

        // TODO: Implement actual distance-based filtering
        // Calculate distance and filter within 50 miles
        let userCLLocation = CLLocation(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude
        )

        filteredEvents = events.filter { event in
            let eventCLLocation = CLLocation(
                latitude: event.location.latitude,
                longitude: event.location.longitude
            )
            let distanceInMeters = userCLLocation.distance(from: eventCLLocation)
            let distanceInMiles = distanceInMeters / 1609.34
            return distanceInMiles <= radiusMiles
        }
    }

    func refreshEvents() async {
        // TODO: Implement pull-to-refresh
        // - Fetch latest events from API
        // - Update events array
        // - Re-apply location filter if set
    }

    func joinEvent(_ event: LocalEvent) {
        // TODO: Implement join event functionality
        // - Call API to register user for event
        // - Update attendee count
        // - Add event to user's calendar
        // - Show confirmation message
    }
}
