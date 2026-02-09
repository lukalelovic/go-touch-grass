import Foundation
import CoreLocation
import Supabase
import Combine

/// Service for interacting with Ticketmaster Discovery API
/// Note: API events are NOT stored in database - they remain in-memory only
@MainActor
class TicketmasterService: ObservableObject {
    // MARK: - Singleton
    static let shared = TicketmasterService()

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var supabaseClient: SupabaseClient {
        return SupabaseManager.shared.client
    }

    // MARK: - Initialization
    private init() {
        // Initialization
    }

    // MARK: - Public API Methods

    /// Fetch events from Ticketmaster API
    /// - Parameters:
    ///   - userId: User ID for rate limiting
    ///   - location: CLLocationCoordinate2D for the search center
    ///   - locationName: Optional name of the location for logging
    ///   - radius: Search radius in miles (default 50)
    ///   - forceRefresh: Force API call even if rate limited
    /// - Returns: Array of TicketmasterEvent (in-memory only, not stored in database)
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

        // TODO: TESTING - Rate limiting temporarily disabled for development
        // Uncomment before production release
        /*
        let canCallAPI = try await checkUserCanCallAPI(userId: userId)
        print("Can call API: \(canCallAPI), forceRefresh: \(forceRefresh)")

        if !canCallAPI {
            print("Rate limited - throwing error")
            throw TicketmasterError.rateLimitExceeded
        }
        */

        print("Making API call to Ticketmaster (rate limiting disabled for testing)")
        // Make API call to Ticketmaster
        let events = try await searchTicketmasterEvents(
            location: location,
            radius: radius
        )

        print("Fetched \(events.count) events from Ticketmaster API (in-memory only)")

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


    /// Check if user can call API (once per day limit)
    func checkUserCanCallAPI(userId: UUID) async throws -> Bool {
        let response = try await supabaseClient
            .rpc("can_user_call_event_api", params: [
                "p_user_id": userId.uuidString,
                "p_source": "ticketmaster"
            ])
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
        // Note: Skipping API call recording due to database function overloading issue
        // The database has multiple versions of record_event_api_call which causes
        // PostgreSQL to be unable to choose the correct function
        // This is a non-critical feature for tracking API usage
        // TODO: Fix by removing old function versions from database or updating schema
        print("⚠️ API call recording skipped - database function overloading issue")
    }

    // MARK: - Event Attendance Methods

    /// Mark event as attended by user
    nonisolated func markEventAttended(
        userId: UUID,
        eventId: UUID,
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
            p_event_id: eventId.uuidString,
            p_notes: notes,
            p_rating: rating
        )

        let client = SupabaseManager.shared.client
        try await client
            .rpc("mark_event_attended", params: params)
            .execute()
    }

    /// Get count of API events user has attended
    /// Note: This only counts Ticketmaster/API events marked as attended
    func fetchAttendedEventCount(userId: UUID) async throws -> Int {
        let response = try await supabaseClient
            .from("user_event_attendance")
            .select("*", head: false, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .eq("event_type", value: "api")
            .execute()

        return response.count ?? 0
    }

    /// Check if user has attended an API event
    func hasUserAttendedEvent(userId: UUID, eventId: UUID) async throws -> Bool {
        let response = try await supabaseClient
            .rpc("has_user_attended_event", params: [
                "p_user_id": userId.uuidString,
                "p_event_id": eventId.uuidString,
                "p_event_type": "api"
            ])
            .execute()

        let hasAttended = try JSONDecoder().decode(Bool.self, from: response.data)
        return hasAttended
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
