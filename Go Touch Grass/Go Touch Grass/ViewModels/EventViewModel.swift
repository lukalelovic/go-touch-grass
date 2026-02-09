//
//  EventViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine
import CoreLocation
import Auth

@MainActor
class EventViewModel: ObservableObject {
    @Published var selectedLocation: Location?
    @Published var showLocationPicker = false
    @Published var events: [LocalEvent] = []
    @Published var ticketmasterEvents: [TicketmasterEvent] = []
    @Published var userEvents: [UserEvent] = []
    @Published var filteredEvents: [LocalEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var canRefreshAPI = true
    @Published var lastAPICallTime: Date?
    @Published var showRateLimitAlert = false

    // Filter controls
    @Published var radiusMiles: Double = 50
    @Published var selectedEventType: ActivityType? = nil {
        didSet {
            applyFilters()
        }
    }
    @Published var showFilters = false

    // Computed property to get unique activity types from current events
    var availableActivityTypes: [ActivityType] {
        let types = Set(events.map { $0.eventType })
        return Array(types).sorted { $0.name < $1.name }
    }

    // Debounce radius changes to avoid excessive reloads
    private var radiusUpdateTask: Task<Void, Never>?

    func updateRadius(_ newRadius: Double) {
        radiusMiles = newRadius

        // Cancel previous task
        radiusUpdateTask?.cancel()

        // Debounce: only reload after user stops dragging for 0.5 seconds
        radiusUpdateTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }
            await refreshEventsWithNewRadius()
        }
    }
    private let ticketmasterService = TicketmasterService.shared
    private let userEventService = UserEventService.shared
    private let supabaseManager = SupabaseManager.shared
    private let locationManager = LocationManager.shared

    init() {
        // Don't auto-load events on init - wait for location selection
        setupLocationObserver()
    }

    private func setupLocationObserver() {
        // Observe location changes and auto-populate selectedLocation
        Task { @MainActor in
            // Use Combine to observe location changes
            for await location in locationManager.$currentLocation.values {
                if let location = location, selectedLocation == nil {
                    // Auto-populate with user's current location
                    await setLocationFromCoordinates(location, city: locationManager.currentCity)
                    break // Only set once on initial load
                }
            }
        }
    }

    private func setLocationFromCoordinates(_ coordinate: CLLocationCoordinate2D, city: String?) async {
        // Create a Location object from coordinates
        let location = Location(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            name: city ?? "Current Location"
        )

        selectedLocation = location
        print("🌍 Auto-populated location from device:")
        print("   City: \(location.name ?? "Unknown")")
        print("   Coordinates: lat=\(location.latitude), long=\(location.longitude)")
    }

    // MARK: - Public Methods

    func requestUserLocation() {
        // Request location permission and start location updates
        print("Requesting user location...")
        locationManager.requestLocationPermission()
        locationManager.requestLocation()
    }

    func loadEvents() async {
        print("loadEvents called - selectedLocation: \(selectedLocation?.name ?? "nil")")

        // Fetch both Ticketmaster and user-generated events if user is logged in
        guard let userId = supabaseManager.currentUser?.id else {
            // No events if not logged in
            print("No user logged in - clearing events")
            events = []
            filteredEvents = []
            return
        }

        guard let location = selectedLocation else {
            // Don't clear events when location is nil
            // Keep showing the last loaded events until user selects a new location
            print("No location selected - keeping existing events")
            return
        }

        print("User logged in (\(userId)), fetching events for location")

        // Fetch both API events and user events concurrently
        async let ticketmaster = fetchTicketmasterEventsAsync(userId: userId, location: location, forceRefresh: false)
        async let userGenerated = fetchUserEventsAsync(location: location)

        await ticketmaster
        await userGenerated

        // Combine and sort all events
        combineAndSortEvents()
    }

    private func fetchTicketmasterEventsAsync(userId: UUID, location: Location, forceRefresh: Bool) async {
        await fetchTicketmasterEvents(userId: userId, location: location, forceRefresh: forceRefresh)
    }

    private func fetchUserEventsAsync(location: Location) async {
        do {
            let clLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            print("🔍 Searching for user events near \(location.name ?? "Unknown") at coordinates (\(location.latitude), \(location.longitude)) within \(radiusMiles) miles")
            userEvents = try await userEventService.fetchNearbyPublicEvents(location: clLocation, radius: radiusMiles)
            print("📍 Fetched \(userEvents.count) user-generated events")
        } catch {
            print("Error fetching user events: \(error)")
            // Don't fail the whole load if user events fail
            userEvents = []
        }
    }

    private func combineAndSortEvents() {
        // Convert Ticketmaster events using existing conversion method
        convertTicketmasterToLocalEvents()

        // Add user events as LocalEvent
        let userLocalEvents = userEvents.compactMap { userEvent -> LocalEvent? in
            let location = Location(
                latitude: userEvent.latitude,
                longitude: userEvent.longitude,
                name: userEvent.venueName ?? userEvent.city
            )

            // Map activity type ID to ActivityType
            let activityType = mapUserEventActivityType(userEvent.activityTypeId)

            return LocalEvent(
                id: userEvent.id,
                title: userEvent.name,
                description: userEvent.description,
                eventType: activityType,
                location: location,
                date: userEvent.startDate,
                imageURL: nil,
                organizerName: "Community Event", // Could fetch creator name from users table
                attendeeCount: 0, // Could fetch from user_event_joins if needed
                isUserGenerated: true
            )
        }

        // Combine all events
        var allLocalEvents = events // Ticketmaster events already converted (isUserGenerated = false)
        allLocalEvents.append(contentsOf: userLocalEvents)

        // Filter out past events (only show upcoming events)
        let now = Date()
        let upcomingEvents = allLocalEvents.filter { $0.date > now }

        // Sort: user-generated events first, then by date (soonest first)
        let sortedEvents = upcomingEvents.sorted { event1, event2 in
            // If one is user-generated and the other isn't, user-generated comes first
            if event1.isUserGenerated != event2.isUserGenerated {
                return event1.isUserGenerated
            }
            // Otherwise, sort by soonest date
            return event1.date < event2.date
        }

        events = sortedEvents

        print("📊 Combined events: \(userLocalEvents.count) community + \(ticketmasterEvents.count) Ticketmaster = \(sortedEvents.count) upcoming events")

        // Apply filters
        applyFilters()
    }

    private func applyFilters() {
        var filtered = events

        // Filter by event type if selected
        if let eventType = selectedEventType {
            filtered = filtered.filter { $0.eventType == eventType }
        }

        // Note: Radius filtering is already applied during fetch in UserEventService
        // and TicketmasterService, so we don't need to re-filter here

        filteredEvents = filtered
        print("🔍 Applied filters: \(filtered.count) events match criteria (type: \(selectedEventType?.rawValue ?? "all"))")
    }

    private func mapUserEventActivityType(_ activityTypeId: Int) -> ActivityType {
        // Map database activity type IDs to ActivityType
        switch activityTypeId {
        case 1: return ActivityType(id: 1, name: "Running", icon: "figure.run", createdAt: nil)
        case 2: return ActivityType(id: 2, name: "Walking", icon: "figure.walk", createdAt: nil)
        case 3: return ActivityType(id: 3, name: "Hiking", icon: "figure.hiking", createdAt: nil)
        case 4: return ActivityType(id: 4, name: "Biking", icon: "bicycle", createdAt: nil)
        case 5: return ActivityType(id: 5, name: "Kayaking", icon: "figure.outdoor.cycle", createdAt: nil)
        case 6: return ActivityType(id: 6, name: "Climbing", icon: "figure.climbing", createdAt: nil)
        case 7: return ActivityType(id: 7, name: "Swimming", icon: "figure.pool.swim", createdAt: nil)
        default: return ActivityType(id: 8, name: "Other", icon: "star.fill", createdAt: nil)
        }
    }


    func fetchTicketmasterEvents(
        userId: UUID,
        location: Location,
        forceRefresh: Bool = false
    ) async {
        print("fetchTicketmasterEvents called - userId: \(userId), location: \(location.name ?? "Unknown"), forceRefresh: \(forceRefresh)")
        print("📍 Retrieving events for city: \(location.name ?? "Unknown Location")")
        print("📍 Coordinates: lat=\(location.latitude), long=\(location.longitude)")
        print("📍 Search radius: \(radiusMiles) miles")

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let clLocation = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )

            // TODO: TESTING - Rate limiting temporarily disabled for development
            // Uncomment before production release
            /*
            if !forceRefresh {
                let canCallAPI = try await ticketmasterService.checkUserCanCallAPI(userId: userId)
                print("Pre-check: Can call API: \(canCallAPI)")

                if !canCallAPI {
                    print("Rate limited - showing alert")
                    showRateLimitAlert = true
                    // No cached events available - API events are in-memory only
                    errorMessage = "You've reached your daily API limit. Try again tomorrow!"
                    return
                }
            }
            */

            ticketmasterEvents = try await ticketmasterService.fetchEvents(
                for: userId,
                location: clLocation,
                locationName: location.name,
                radius: Int(radiusMiles),
                forceRefresh: forceRefresh
            )

            lastAPICallTime = Date()
            print("Successfully fetched \(ticketmasterEvents.count) events")

            // Convert to LocalEvent for display
            convertTicketmasterToLocalEvents()
            print("Converted to \(events.count) local events")
        } catch TicketmasterError.rateLimitExceeded {
            print("Rate limit exceeded (from service) - showing alert")
            showRateLimitAlert = true
            errorMessage = "You've reached your daily API limit. Try again tomorrow!"
        } catch {
            print("Error fetching events: \(error)")
            errorMessage = "Failed to fetch events: \(error.localizedDescription)"
        }
    }

    private func convertTicketmasterToLocalEvents() {
        // Convert TicketmasterEvent to LocalEvent for display
        let convertedEvents = ticketmasterEvents.compactMap { ticketmasterEvent -> LocalEvent? in
            guard let location = ticketmasterEvent.location else { return nil }

            // Map Ticketmaster categories to ActivityType
            let activityType = mapCategoryToActivityType(ticketmasterEvent.sourceCategory, genre: ticketmasterEvent.genre)

            // Filter out events that don't match any of our known categories
            // Only keep events with recognized category types (not generic "Event" or unknown categories)
            guard activityType.name != "Event" else {
                print("Filtering out event with unrecognized category: \(ticketmasterEvent.name)")
                return nil
            }

            // Create better description fallback
            var description = ticketmasterEvent.description
            if description == nil || description?.isEmpty == true {
                // Build description from available info
                var parts: [String] = []

                if let category = ticketmasterEvent.sourceCategory {
                    parts.append(category)
                }
                if let genre = ticketmasterEvent.genre {
                    parts.append(genre)
                }
                if let venue = ticketmasterEvent.venueName {
                    parts.append("at \(venue)")
                }
                if let city = ticketmasterEvent.city {
                    parts.append("in \(city)")
                }

                description = parts.isEmpty ? "Event details coming soon" : parts.joined(separator: " ")
            }

            return LocalEvent(
                id: UUID(),
                title: ticketmasterEvent.name,
                description: description ?? "Event details coming soon",
                eventType: activityType,
                location: location,
                date: ticketmasterEvent.startDate,
                imageURL: ticketmasterEvent.thumbnailUrl,
                organizerName: ticketmasterEvent.venueName ?? "Unknown Organizer",
                attendeeCount: 0, // We can fetch this from attendance table if needed
                isUserGenerated: false
            )
        }

        events = convertedEvents
        filterEventsByLocation()
    }

    private func mapCategoryToActivityType(_ category: String?, genre: String?) -> ActivityType {
        // Map Ticketmaster categories and genres to ActivityType
        // Only return recognized categories - unrecognized events will be filtered out
        let categoryLower = category?.lowercased() ?? ""
        let genreLower = genre?.lowercased() ?? ""

        // Sports
        if categoryLower.contains("sports") || genreLower.contains("sports") ||
           genreLower.contains("basketball") || genreLower.contains("football") ||
           genreLower.contains("baseball") || genreLower.contains("soccer") ||
           genreLower.contains("hockey") || genreLower.contains("tennis") ||
           genreLower.contains("golf") || genreLower.contains("racing") ||
           genreLower.contains("mma") || genreLower.contains("wrestling") {
            return ActivityType(id: 1, name: "Sports", icon: "sportscourt.fill", createdAt: nil)
        }

        // Music/Concert
        if categoryLower.contains("music") || genreLower.contains("music") ||
           genreLower.contains("concert") || genreLower.contains("rock") ||
           genreLower.contains("pop") || genreLower.contains("jazz") ||
           genreLower.contains("classical") || genreLower.contains("hip-hop") ||
           genreLower.contains("country") || genreLower.contains("r&b") ||
           genreLower.contains("electronic") || genreLower.contains("indie") {
            return ActivityType(id: 2, name: "Concert", icon: "music.note", createdAt: nil)
        }

        // Arts & Theatre
        if categoryLower.contains("arts") || categoryLower.contains("theatre") ||
           genreLower.contains("theatre") || genreLower.contains("theater") ||
           genreLower.contains("musical") || genreLower.contains("comedy") ||
           genreLower.contains("dance") || genreLower.contains("ballet") ||
           genreLower.contains("opera") || genreLower.contains("circus") {
            return ActivityType(id: 3, name: "Arts & Theatre", icon: "theatermasks.fill", createdAt: nil)
        }

        // Family
        if categoryLower.contains("family") || genreLower.contains("family") ||
           genreLower.contains("children") || genreLower.contains("kids") {
            return ActivityType(id: 4, name: "Family Event", icon: "figure.2.and.child.holdinghands", createdAt: nil)
        }

        // Festival
        if genreLower.contains("festival") || categoryLower.contains("festival") ||
           genreLower.contains("fair") {
            return ActivityType(id: 5, name: "Festival", icon: "party.popper.fill", createdAt: nil)
        }

        // Unrecognized category - return generic "Event" which will be filtered out
        return ActivityType(id: 11, name: "Event", icon: "calendar", createdAt: nil)
    }

    func filterEventsByLocation() {
        guard let userLocation = selectedLocation else {
            filteredEvents = events
            return
        }

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

    func refreshEventsWithNewRadius() async {
        // Reload events when radius changes (without API rate limit check)
        guard let location = selectedLocation else {
            return
        }
        await loadEvents()
    }

    func refreshEvents() async {
        print("refreshEvents called")

        guard let userId = supabaseManager.currentUser?.id,
              let location = selectedLocation else {
            print("refreshEvents: No user or location")
            return
        }

        // TODO: TESTING - Rate limiting temporarily disabled for development
        // Uncomment before production release
        /*
        print("Checking if user can call API...")

        do {
            let canRefresh = try await ticketmasterService.checkUserCanCallAPI(userId: userId)
            print("Can refresh API: \(canRefresh)")

            if !canRefresh {
                print("Setting showRateLimitAlert to true")
                showRateLimitAlert = true
                print("showRateLimitAlert is now: \(showRateLimitAlert)")
                errorMessage = "You've reached your daily API limit. Try again tomorrow!"
                return
            }
        } catch {
            print("Error checking refresh availability: \(error)")
            errorMessage = "Failed to check refresh availability: \(error.localizedDescription)"
            return
        }
        */

        print("Refreshing events (rate limiting disabled for testing)")
        await fetchTicketmasterEvents(
            userId: userId,
            location: location,
            forceRefresh: true
        )
    }

    func joinEvent(_ event: LocalEvent) async {
        guard let userId = supabaseManager.currentUser?.id else {
            errorMessage = "You must be logged in to attend events"
            return
        }

        // Find the corresponding Ticketmaster event
        guard let ticketmasterEvent = ticketmasterEvents.first(where: { $0.name == event.title }) else {
            errorMessage = "Event not found"
            return
        }

        do {
            try await ticketmasterService.markEventAttended(
                userId: userId,
                eventId: ticketmasterEvent.id,
                notes: nil,
                rating: nil
            )

            // Show success message or update UI
            errorMessage = nil
        } catch {
            errorMessage = "Failed to mark event as attended: \(error.localizedDescription)"
        }
    }

    // MARK: - Event Attendance Methods

    func fetchAttendedEvents() async -> [TicketmasterEvent] {
        // Note: Since API events are no longer cached in database,
        // we can't fetch full attended event details anymore
        // This would need to be refactored to store minimal info
        // or removed entirely
        return []
    }

    func fetchAttendedEventCount() async -> Int {
        guard let userId = supabaseManager.currentUser?.id else {
            return 0
        }

        do {
            return try await ticketmasterService.fetchAttendedEventCount(userId: userId)
        } catch {
            errorMessage = "Failed to fetch event count: \(error.localizedDescription)"
            return 0
        }
    }
}
