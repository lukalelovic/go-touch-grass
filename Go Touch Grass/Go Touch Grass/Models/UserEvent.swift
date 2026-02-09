//
//  UserEvent.swift
//  Go Touch Grass
//
//  Model for user-generated community events
//

import Foundation
import CoreLocation

// MARK: - User Event Model

/// Represents a community event created by users
struct UserEvent: Identifiable, Codable, Sendable {
    let id: UUID
    let creatorId: UUID
    let visibility: EventVisibility

    // Event details
    let name: String
    let description: String
    let eventUrl: String?

    // Date/Time
    let startDate: Date
    let endDate: Date?
    let timezone: String?

    // Location
    let venueName: String?
    let venueAddress: String?
    let city: String
    let state: String?
    let country: String
    let postalCode: String?
    let latitude: Double
    let longitude: Double

    // Categorization
    let activityTypeId: Int

    // Capacity and requirements
    let maxAttendees: Int?
    let requirements: String?

    // Pricing
    let price: Double?
    let currency: String
    let isFree: Bool

    // Status
    let isCancelled: Bool
    let cancelledAt: Date?
    let cancellationReason: String?

    let createdAt: Date
    let updatedAt: Date

    // Computed properties
    var location: Location {
        Location(
            latitude: latitude,
            longitude: longitude,
            name: venueName ?? city
        )
    }

    var fullAddress: String? {
        var components: [String] = []
        if let venue = venueName { components.append(venue) }
        if let address = venueAddress { components.append(address) }
        components.append(city)
        if let state = state { components.append(state) }
        if let postal = postalCode { components.append(postal) }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    var isPast: Bool {
        startDate < Date()
    }

    var isUpcoming: Bool {
        startDate > Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case visibility
        case name
        case description
        case eventUrl = "event_url"
        case startDate = "start_date"
        case endDate = "end_date"
        case timezone
        case venueName = "venue_name"
        case venueAddress = "venue_address"
        case city
        case state
        case country
        case postalCode = "postal_code"
        case latitude
        case longitude
        case activityTypeId = "activity_type_id"
        case maxAttendees = "max_attendees"
        case requirements
        case price
        case currency
        case isFree = "is_free"
        case isCancelled = "is_cancelled"
        case cancelledAt = "cancelled_at"
        case cancellationReason = "cancellation_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Event Visibility Enum

enum EventVisibility: String, Codable, Sendable {
    case `public` = "public"
    case `private` = "private"
}

// MARK: - User Event Join Model

/// Represents a user's RSVP to a community event
struct UserEventJoin: Identifiable, Codable, Sendable {
    let id: Int
    let userId: UUID
    let eventId: UUID
    let joinedAt: Date
    let status: JoinStatus
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventId = "event_id"
        case joinedAt = "joined_at"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Join Status Enum

enum JoinStatus: String, Codable, Sendable {
    case going = "going"
    case maybe = "maybe"
    case notGoing = "not_going"

    var displayName: String {
        switch self {
        case .going: return "Going"
        case .maybe: return "Maybe"
        case .notGoing: return "Not Going"
        }
    }
}

// MARK: - Create User Event Request

struct CreateUserEventRequest: Encodable {
    let creatorId: UUID
    let visibility: String
    let name: String
    let description: String
    let eventUrl: String?
    let startDate: String
    let endDate: String?
    let timezone: String?
    let venueName: String?
    let venueAddress: String?
    let city: String
    let state: String?
    let country: String
    let postalCode: String?
    let latitude: Double
    let longitude: Double
    let activityTypeId: Int
    let maxAttendees: Int?
    let requirements: String?
    let price: Double?
    let currency: String
    let isFree: Bool

    enum CodingKeys: String, CodingKey {
        case creatorId = "creator_id"
        case visibility
        case name
        case description
        case eventUrl = "event_url"
        case startDate = "start_date"
        case endDate = "end_date"
        case timezone
        case venueName = "venue_name"
        case venueAddress = "venue_address"
        case city
        case state
        case country
        case postalCode = "postal_code"
        case latitude
        case longitude
        case activityTypeId = "activity_type_id"
        case maxAttendees = "max_attendees"
        case requirements
        case price
        case currency
        case isFree = "is_free"
    }
}
