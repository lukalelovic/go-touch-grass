import Foundation
import CoreLocation
import Supabase
import Combine

// MARK: - RPC Parameter Structs
// Note: Using dictionaries instead of Encodable structs to avoid main actor isolation issues

/// Service for interacting with Ticketmaster Discovery API and caching events
@MainActor
class TicketmasterService: ObservableObject {
    // MARK: - Singleton
    static let shared = TicketmasterService()

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var supabaseClient: SupabaseClient {
        return SupabaseManager().client
    }

    // MARK: - Initialization
    private init() {
        // Initialization
    }

    // MARK: - Public API Methods

    /// Fetch events from Ticketmaster API or return cached events if within 24 hours
    /// - Parameters:
    ///   - location: CLLocationCoordinate2D for the search center
    ///   - radius: Search radius in miles (default 50)
    ///   - forceRefresh: Force API call even if cached data exists
    /// - Returns: Array of TicketmasterEvent
    func fetchEvents(
        for userId: UUID,
        location: CLLocationCoordinate2D,
        locationName: String? = nil,
        radius: Int = 50,
        forceRefresh: Bool = false
    ) async throws -> [TicketmasterEvent] {
        isLoading = true
        defer { isLoading = false }

        print("fetchEvents called for user \(userId), location: \(location.latitude), \(location.longitude)")

        // Check rate limit one more time (ViewModel also checks, but this is a safety check)
        let canCallAPI = try await checkUserCanCallAPI(userId: userId)
        print("Can call API: \(canCallAPI), forceRefresh: \(forceRefresh)")

        if !canCallAPI {
            print("Rate limited - throwing error")
            throw TicketmasterError.rateLimitExceeded
        }

        print("Making API call to Ticketmaster")
        // Make API call to Ticketmaster
        let events = try await searchTicketmasterEvents(
            location: location,
            radius: radius
        )

        print("Caching \(events.count) events to database")
        // Cache events in database
        try await cacheEvents(events)

        // Record API call for rate limiting
        try await recordAPICall(
            userId: userId,
            location: location,
            locationName: locationName,
            radius: radius,
            eventsRetrieved: events.count,
            success: true
        )

        return events
    }

    /// Get cached events from database
    func fetchCachedEvents(
        location: CLLocationCoordinate2D,
        radius: Int = 50
    ) async throws -> [TicketmasterEvent] {
        // Query events within radius that are still upcoming
        let response = try await supabaseClient
            .from("ticketmaster_events")
            .select()
            .gte("start_date", value: ISO8601DateFormatter().string(from: Date()))
            .order("start_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Debug: Print raw database response
        #if DEBUG
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("Database response for cached events: \(jsonString.prefix(500))")
        }
        #endif

        do {
            let events = try decoder.decode([TicketmasterEvent].self, from: response.data)
            print("Successfully decoded \(events.count) cached events from database")
            return filterEventsByDistance(events, location: location, radius: radius)
        } catch {
            print("Error decoding cached events: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(error)")
                }
            }
            throw TicketmasterError.decodingError(error)
        }
    }

    private func filterEventsByDistance(_ events: [TicketmasterEvent], location: CLLocationCoordinate2D, radius: Int) -> [TicketmasterEvent] {
        // Filter by distance (simple radius filter)
        return events.filter { event in
            guard let eventLat = event.latitude, let eventLong = event.longitude else {
                return false
            }

            let eventLocation = CLLocation(latitude: eventLat, longitude: eventLong)
            let searchLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let distanceInMeters = eventLocation.distance(from: searchLocation)
            let distanceInMiles = distanceInMeters / 1609.34

            return distanceInMiles <= Double(radius)
        }
    }

    // MARK: - Ticketmaster API Methods

    /// Search for events using Ticketmaster Discovery API
    private func searchTicketmasterEvents(
        location: CLLocationCoordinate2D,
        radius: Int = 50
    ) async throws -> [TicketmasterEvent] {
        // Build URL
        var components = URLComponents(string: "\(TicketmasterConfig.baseURL)/events.json")!

        components.queryItems = [
            URLQueryItem(name: "apikey", value: TicketmasterConfig.apiKey),
            URLQueryItem(name: "latlong", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "unit", value: "miles"),
            URLQueryItem(name: "sort", value: "date,asc"),
            URLQueryItem(name: "size", value: "100") // Max results per page
        ]

        guard let url = components.url else {
            throw TicketmasterError.invalidURL
        }

        // Make request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TicketmasterError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TicketmasterError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()

        // Debug: Print raw response for troubleshooting
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Ticketmaster API Response: \(jsonString.prefix(500))")
        }
        #endif

        do {
            let apiResponse = try decoder.decode(TicketmasterAPIResponse.self, from: data)

            guard let apiEvents = apiResponse.embedded?.events else {
                print("No events found in API response")
                return []
            }

            print("Successfully decoded \(apiEvents.count) events from Ticketmaster API")

            // Convert to TicketmasterEvent models
            let events = apiEvents.map { apiEvent in
                apiEvent.toTicketmasterEvent(
                    searchLocation: location,
                    searchRadius: radius
                )
            }

            return events
        } catch {
            print("Error decoding Ticketmaster API response: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(error)")
                }
            }
            throw TicketmasterError.decodingError(error)
        }
    }

    // MARK: - Database Methods

    /// Cache events in Supabase
    private func cacheEvents(_ events: [TicketmasterEvent]) async throws {
        guard !events.isEmpty else { return }

        print("Attempting to cache \(events.count) events...")

        // Batch upsert all events at once for better performance
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let eventsData = try encoder.encode(events)

            print("Encoded events data, size: \(eventsData.count) bytes")

            // Debug: Print first 500 chars of encoded data
            #if DEBUG
            if let jsonString = String(data: eventsData, encoding: .utf8) {
                print("Encoded JSON preview: \(jsonString.prefix(500))")
            }
            #endif

            // Upsert all events at once
            // Note: Not using .select() because we don't need the response data
            let response = try await supabaseClient
                .from("ticketmaster_events")
                .upsert(eventsData)
                .execute()

            print("Successfully cached \(events.count) events to database")
            print("Cache response status: \(response.response.statusCode)")

            // Debug: Check response headers and body
            #if DEBUG
            print("Cache response data size: \(response.data.count) bytes")
            if let responseBody = String(data: response.data, encoding: .utf8) {
                print("Cache response body: '\(responseBody)'")
            } else {
                print("Cache response body could not be decoded as UTF-8")
                print("Cache response raw bytes: \(response.data.map { String(format: "%02x", $0) }.joined())")
            }

            // Check HTTP headers
            if let httpResponse = response.response as? HTTPURLResponse {
                print("Cache response headers: \(httpResponse.allHeaderFields)")
            }
            #endif
        } catch {
            print("Failed to cache events: \(error)")
            print("Error type: \(type(of: error))")
            print("Error details: \(error.localizedDescription)")

            if let urlError = error as? URLError {
                print("URL Error code: \(urlError.code.rawValue)")
                print("URL Error description: \(urlError.localizedDescription)")
            }

            // Print the full error for debugging
            print("Full error: \(String(describing: error))")

            // Don't throw - caching failure shouldn't prevent showing events to user
        }
    }

    /// Check if user can call API (once per day limit)
    func checkUserCanCallAPI(userId: UUID) async throws -> Bool {
        let response = try await supabaseClient
            .rpc("can_user_call_event_api", params: ["p_user_id": userId.uuidString])
            .execute()

        let canCall = try JSONDecoder().decode(Bool.self, from: response.data)
        return canCall
    }

    /// Record API call for rate limiting
    nonisolated private func recordAPICall(
        userId: UUID,
        location: CLLocationCoordinate2D,
        locationName: String?,
        radius: Int,
        eventsRetrieved: Int,
        success: Bool,
        errorMessage: String? = nil
    ) async throws {
        struct Params: Encodable {
            let p_user_id: String
            let p_search_lat: Double
            let p_search_long: Double
            let p_search_location_name: String
            let p_search_radius: Int
            let p_events_retrieved: Int
            let p_success: Bool
            let p_error_message: String
        }

        let params = Params(
            p_user_id: userId.uuidString,
            p_search_lat: location.latitude,
            p_search_long: location.longitude,
            p_search_location_name: locationName ?? "",
            p_search_radius: radius,
            p_events_retrieved: eventsRetrieved,
            p_success: success,
            p_error_message: errorMessage ?? ""
        )

        let client = SupabaseManager().client
        try await client
            .rpc("record_event_api_call", params: params)
            .execute()
    }

    // MARK: - Event Attendance Methods

    /// Mark event as attended by user
    nonisolated func markEventAttended(
        userId: UUID,
        eventId: String,
        notes: String? = nil,
        rating: Int? = nil
    ) async throws {
        struct Params: Encodable {
            let p_user_id: String
            let p_event_id: String
            let p_notes: String?
            let p_rating: Int?
        }

        let params = Params(
            p_user_id: userId.uuidString,
            p_event_id: eventId,
            p_notes: notes,
            p_rating: rating
        )

        let client = SupabaseManager().client
        try await client
            .rpc("mark_event_attended", params: params)
            .execute()
    }

    /// Get user's attended events
    func fetchAttendedEvents(userId: UUID) async throws -> [TicketmasterEvent] {
        let response = try await supabaseClient
            .from("user_event_attendance")
            .select("""
                *,
                ticketmaster_events(*)
            """)
            .eq("user_id", value: userId.uuidString)
            .order("attended_at", ascending: false)
            .execute()

        // Parse the response
        // Note: This is simplified - you may need to parse the joined data differently
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let attendanceRecords = try decoder.decode([UserEventAttendance].self, from: response.data)

        // Fetch full event details for each attended event
        var events: [TicketmasterEvent] = []
        for record in attendanceRecords {
            let eventResponse = try await supabaseClient
                .from("ticketmaster_events")
                .select()
                .eq("id", value: record.eventId)
                .single()
                .execute()

            if let event = try? decoder.decode(TicketmasterEvent.self, from: eventResponse.data) {
                events.append(event)
            }
        }

        return events
    }

    /// Get count of events user has attended
    func fetchAttendedEventCount(userId: UUID) async throws -> Int {
        let response = try await supabaseClient
            .rpc("get_user_attended_event_count", params: ["p_user_id": userId.uuidString])
            .execute()

        let count = try JSONDecoder().decode(Int.self, from: response.data)
        return count
    }

    /// Check if user has attended an event
    func hasUserAttendedEvent(userId: UUID, eventId: String) async throws -> Bool {
        let response = try await supabaseClient
            .rpc("has_user_attended_event", params: [
                "p_user_id": userId.uuidString,
                "p_event_id": eventId
            ])
            .execute()

        let hasAttended = try JSONDecoder().decode(Bool.self, from: response.data)
        return hasAttended
    }

    // MARK: - Pro Tier Features (Placeholder)

    /// Get recommended events based on user's activity history
    /// This will be implemented later for Pro-tier users
    func fetchRecommendedEvents(
        userId: UUID,
        location: CLLocationCoordinate2D,
        radius: Int = 50
    ) async throws -> [TicketmasterEvent] {
        // TODO: Implement recommendation algorithm
        // For now, just return cached events
        return try await fetchCachedEvents(location: location, radius: radius)
    }
}

// MARK: - Error Types

enum TicketmasterError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rateLimitExceeded
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Ticketmaster API URL"
        case .invalidResponse:
            return "Invalid response from Ticketmaster API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Try again tomorrow."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
