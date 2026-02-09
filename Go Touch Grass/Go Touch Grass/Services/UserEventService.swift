//
//  UserEventService.swift
//  Go Touch Grass
//
//  Service for managing user-generated community events
//

import Foundation
import CoreLocation
import Supabase
import Combine

// MARK: - User Event Service

@MainActor
class UserEventService: ObservableObject {
    // MARK: - Singleton
    static let shared = UserEventService()

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var supabaseClient: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Create Event

    /// Create a new user-generated event
    func createEvent(
        name: String,
        description: String,
        eventUrl: String?,
        startDate: Date,
        endDate: Date?,
        location: CLLocationCoordinate2D,
        city: String,
        state: String?,
        country: String,
        venueName: String?,
        venueAddress: String?,
        postalCode: String?,
        activityTypeId: Int,
        visibility: EventVisibility,
        maxAttendees: Int?,
        requirements: String?,
        price: Double?,
        isFree: Bool
    ) async throws -> UserEvent {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw UserEventError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let request = CreateUserEventRequest(
            creatorId: userId,
            visibility: visibility.rawValue,
            name: name,
            description: description,
            eventUrl: eventUrl,
            startDate: isoFormatter.string(from: startDate),
            endDate: endDate.map { isoFormatter.string(from: $0) },
            timezone: TimeZone.current.identifier,
            venueName: venueName,
            venueAddress: venueAddress,
            city: city,
            state: state,
            country: country,
            postalCode: postalCode,
            latitude: location.latitude,
            longitude: location.longitude,
            activityTypeId: activityTypeId,
            maxAttendees: maxAttendees,
            requirements: requirements,
            price: price,
            currency: "USD",
            isFree: isFree
        )

        let response = try await supabaseClient
            .from("user_events")
            .insert(request)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let event = try decoder.decode(UserEvent.self, from: response.data)
        print("✅ Created event '\(event.name)' at (\(event.latitude), \(event.longitude)) scheduled for \(event.startDate)")
        return event
    }

    // MARK: - Fetch Events

    /// Fetch public events near a location
    func fetchNearbyPublicEvents(
        location: CLLocationCoordinate2D,
        radius: Double = 50.0 // miles
    ) async throws -> [UserEvent] {
        isLoading = true
        defer { isLoading = false }

        // Fetch all public upcoming events
        let response = try await supabaseClient
            .from("user_events")
            .select()
            .eq("visibility", value: "public")
            .eq("is_cancelled", value: false)
            .gte("start_date", value: ISO8601DateFormatter().string(from: Date()))
            .order("start_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let allEvents = try decoder.decode([UserEvent].self, from: response.data)
        print("🔍 Fetched \(allEvents.count) total public upcoming events from database")

        // Filter by distance
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let radiusInMeters = radius * 1609.34 // Convert miles to meters

        let nearbyEvents = allEvents.filter { event in
            let eventLocation = CLLocation(latitude: event.latitude, longitude: event.longitude)
            let distance = userLocation.distance(from: eventLocation)
            let distanceInMiles = distance / 1609.34
            let isNearby = distance <= radiusInMeters
            print("   Event '\(event.name)' is \(String(format: "%.1f", distanceInMiles)) miles away - \(isNearby ? "INCLUDED" : "EXCLUDED")")
            return isNearby
        }

        print("📍 Filtered to \(nearbyEvents.count) events within \(radius) miles")
        return nearbyEvents
    }

    /// Fetch events created by the current user
    func fetchMyCreatedEvents() async throws -> [UserEvent] {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw UserEventError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let response = try await supabaseClient
            .from("user_events")
            .select()
            .eq("creator_id", value: userId.uuidString)
            .order("start_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let events = try decoder.decode([UserEvent].self, from: response.data)
        return events
    }

    /// Fetch events the user has joined
    func fetchMyJoinedEvents() async throws -> [UserEvent] {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw UserEventError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // First, get the event IDs the user has joined
        let joinsResponse = try await supabaseClient
            .from("user_event_joins")
            .select("event_id")
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "going")
            .execute()

        struct JoinRecord: Decodable {
            let eventId: UUID

            enum CodingKeys: String, CodingKey {
                case eventId = "event_id"
            }
        }

        let decoder = JSONDecoder()
        let joins = try decoder.decode([JoinRecord].self, from: joinsResponse.data)
        let eventIds = joins.map { $0.eventId.uuidString }

        guard !eventIds.isEmpty else {
            return []
        }

        // Fetch the actual events
        let eventsResponse = try await supabaseClient
            .from("user_events")
            .select()
            .in("id", values: eventIds)
            .eq("is_cancelled", value: false)
            .order("start_date", ascending: true)
            .execute()

        decoder.dateDecodingStrategy = .iso8601
        let events = try decoder.decode([UserEvent].self, from: eventsResponse.data)
        return events
    }

    // MARK: - Join/Leave Events

    /// RSVP to an event
    func joinEvent(eventId: UUID, status: JoinStatus = .going) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw UserEventError.notAuthenticated
        }

        let params: [String: String] = [
            "p_user_id": userId.uuidString,
            "p_event_id": eventId.uuidString,
            "p_status": status.rawValue
        ]

        try await supabaseClient
            .rpc("join_user_event", params: params)
            .execute()
    }

    /// Leave/cancel RSVP to an event
    func leaveEvent(eventId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw UserEventError.notAuthenticated
        }

        try await supabaseClient
            .from("user_event_joins")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("event_id", value: eventId.uuidString)
            .execute()
    }

    /// Check if user has joined an event
    func hasJoinedEvent(eventId: UUID) async throws -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            return false
        }

        let params: [String: String] = [
            "p_user_id": userId.uuidString,
            "p_event_id": eventId.uuidString
        ]

        let response = try await supabaseClient
            .rpc("has_user_joined_event", params: params)
            .execute()

        let hasJoined = try JSONDecoder().decode(Bool.self, from: response.data)
        return hasJoined
    }

    /// Get attendee count for an event
    func getAttendeeCount(eventId: UUID) async throws -> Int {
        let params: [String: String] = [
            "p_event_id": eventId.uuidString
        ]

        let response = try await supabaseClient
            .rpc("get_user_event_attendee_count", params: params)
            .execute()

        let count = try JSONDecoder().decode(Int.self, from: response.data)
        return count
    }

    // MARK: - Update/Cancel Events

    /// Cancel an event (creator only)
    func cancelEvent(eventId: UUID, reason: String?) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw UserEventError.notAuthenticated
        }

        var params: [String: String] = [
            "p_event_id": eventId.uuidString,
            "p_user_id": userId.uuidString
        ]

        if let reason = reason {
            params["p_reason"] = reason
        }

        try await supabaseClient
            .rpc("cancel_user_event", params: params)
            .execute()
    }

    /// Update an event (creator only)
    /// Note: This is a simplified version - for production, create a proper UpdateEventRequest struct
    func updateEvent(
        eventId: UUID,
        name: String?,
        description: String?,
        startDate: Date?,
        endDate: Date?,
        maxAttendees: Int?,
        requirements: String?
    ) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw UserEventError.notAuthenticated
        }

        // For now, we'll need to update fields individually or create a proper update struct
        // This is a limitation of the Supabase Swift SDK's type safety
        // TODO: Create UpdateUserEventRequest struct for proper type-safe updates

        print("Event update requested for \(eventId)")
        // Implementation would require creating a proper Encodable update struct
        // Skipping for now as it requires more complex handling
    }
}

// MARK: - User Event Error

enum UserEventError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case eventNotFound
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .notAuthorized:
            return "You don't have permission to perform this action"
        case .eventNotFound:
            return "Event not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
