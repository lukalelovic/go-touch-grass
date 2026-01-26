import Foundation
import CoreLocation

// MARK: - Ticketmaster Event Model

/// Represents an event from the Ticketmaster API (cached in database)
struct TicketmasterEvent: Identifiable, Codable {
    let id: String // Ticketmaster event ID
    let name: String
    let description: String?
    let eventUrl: String?

    // Date/Time information
    let startDate: Date
    let endDate: Date?
    let timezone: String?

    // Location information
    let venueName: String?
    let venueAddress: String?
    let city: String?
    let state: String?
    let country: String?
    let postalCode: String?
    let latitude: Double?
    let longitude: Double?

    // Event details
    let category: String?
    let genre: String?
    let priceMin: Double?
    let priceMax: Double?
    let currency: String?

    // Images
    let imageUrl: String?
    let thumbnailUrl: String?

    // Metadata for caching
    let retrievedAt: Date?
    let searchLocationLat: Double?
    let searchLocationLong: Double?
    let searchRadiusMiles: Int?

    let createdAt: Date?

    // Computed properties
    var location: Location? {
        guard let lat = latitude, let long = longitude else { return nil }
        return Location(
            latitude: lat,
            longitude: long,
            name: venueName ?? city
        )
    }

    var clLocation: CLLocationCoordinate2D? {
        guard let lat = latitude, let long = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }

    var priceRange: String? {
        if let min = priceMin, let max = priceMax {
            let curr = currency ?? "USD"
            return "$\(Int(min)) - $\(Int(max)) \(curr)"
        } else if let min = priceMin {
            let curr = currency ?? "USD"
            return "From $\(Int(min)) \(curr)"
        }
        return nil
    }

    var fullAddress: String? {
        var components: [String] = []
        if let venue = venueName { components.append(venue) }
        if let address = venueAddress { components.append(address) }
        if let city = city { components.append(city) }
        if let state = state { components.append(state) }
        if let postal = postalCode { components.append(postal) }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case id
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
        case category
        case genre
        case priceMin = "price_min"
        case priceMax = "price_max"
        case currency
        case imageUrl = "image_url"
        case thumbnailUrl = "thumbnail_url"
        case retrievedAt = "retrieved_at"
        case searchLocationLat = "search_location_lat"
        case searchLocationLong = "search_location_long"
        case searchRadiusMiles = "search_radius_miles"
        case createdAt = "created_at"
    }
}

// MARK: - Ticketmaster API Response Models

/// Response from Ticketmaster Discovery API
struct TicketmasterAPIResponse: Codable {
    let embedded: EmbeddedEvents?

    enum CodingKeys: String, CodingKey {
        case embedded = "_embedded"
    }

    struct EmbeddedEvents: Codable {
        let events: [TicketmasterAPIEvent]?
    }
}

/// Event from Ticketmaster API (raw response)
struct TicketmasterAPIEvent: Codable {
    let id: String
    let name: String
    let description: String?
    let url: String?
    let dates: EventDates?
    let classifications: [Classification]?
    let priceRanges: [PriceRange]?
    let images: [EventImage]?
    let embedded: EmbeddedVenue?

    enum CodingKeys: String, CodingKey {
        case id, name, description, url, dates, classifications, images
        case priceRanges
        case embedded = "_embedded"
    }

    struct EventDates: Codable {
        let start: DateInfo?
        let end: DateInfo?
        let timezone: String?

        struct DateInfo: Codable {
            let localDate: String?
            let localTime: String?
            let dateTime: String?
        }
    }

    struct Classification: Codable {
        let segment: ClassificationInfo?
        let genre: ClassificationInfo?

        struct ClassificationInfo: Codable {
            let name: String?
        }
    }

    struct PriceRange: Codable {
        let min: Double?
        let max: Double?
        let currency: String?
    }

    struct EventImage: Codable {
        let url: String?
        let width: Int?
        let height: Int?
        let ratio: String?
    }

    struct EmbeddedVenue: Codable {
        let venues: [Venue]?

        struct Venue: Codable {
            let name: String?
            let address: VenueAddress?
            let city: VenueCity?
            let state: VenueState?
            let country: VenueCountry?
            let postalCode: String?
            let location: VenueLocation?

            struct VenueAddress: Codable {
                let line1: String?
            }

            struct VenueCity: Codable {
                let name: String?
            }

            struct VenueState: Codable {
                let name: String?
                let stateCode: String?
            }

            struct VenueCountry: Codable {
                let name: String?
                let countryCode: String?
            }

            struct VenueLocation: Codable {
                let latitude: String?
                let longitude: String?
            }
        }
    }

    /// Convert API event to database model
    func toTicketmasterEvent(searchLocation: CLLocationCoordinate2D?, searchRadius: Int?) -> TicketmasterEvent {
        // Parse date
        let startDate: Date
        if let dateTimeStr = dates?.start?.dateTime {
            startDate = ISO8601DateFormatter().date(from: dateTimeStr) ?? Date()
        } else if let localDate = dates?.start?.localDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            startDate = formatter.date(from: localDate) ?? Date()
        } else {
            startDate = Date()
        }

        let endDate: Date?
        if let dateTimeStr = dates?.end?.dateTime {
            endDate = ISO8601DateFormatter().date(from: dateTimeStr)
        } else {
            endDate = nil
        }

        // Get venue info
        let venue = embedded?.venues?.first
        let latitude = Double(venue?.location?.latitude ?? "")
        let longitude = Double(venue?.location?.longitude ?? "")

        // Get price range
        let priceRange = priceRanges?.first
        let priceMin = priceRange?.min
        let priceMax = priceRange?.max
        let currency = priceRange?.currency

        // Get images
        let sortedImages = images?.sorted { ($0.width ?? 0) > ($1.width ?? 0) }
        let imageUrl = sortedImages?.first?.url
        let thumbnailUrl = sortedImages?.last?.url

        // Get category and genre
        let category = classifications?.first?.segment?.name
        let genre = classifications?.first?.genre?.name

        return TicketmasterEvent(
            id: id,
            name: name,
            description: description,
            eventUrl: url,
            startDate: startDate,
            endDate: endDate,
            timezone: dates?.timezone,
            venueName: venue?.name,
            venueAddress: venue?.address?.line1,
            city: venue?.city?.name,
            state: venue?.state?.stateCode ?? venue?.state?.name,
            country: venue?.country?.countryCode ?? venue?.country?.name,
            postalCode: venue?.postalCode,
            latitude: latitude,
            longitude: longitude,
            category: category,
            genre: genre,
            priceMin: priceMin,
            priceMax: priceMax,
            currency: currency,
            imageUrl: imageUrl,
            thumbnailUrl: thumbnailUrl,
            retrievedAt: Date(),
            searchLocationLat: searchLocation?.latitude,
            searchLocationLong: searchLocation?.longitude,
            searchRadiusMiles: searchRadius,
            createdAt: Date()
        )
    }
}

// MARK: - User Event Attendance Model

/// Tracks which events a user has attended
struct UserEventAttendance: Identifiable, Codable {
    let id: Int
    let userId: UUID
    let eventId: String
    let attendedAt: Date
    let notes: String?
    let rating: Int?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventId = "event_id"
        case attendedAt = "attended_at"
        case notes
        case rating
        case createdAt = "created_at"
    }
}

// MARK: - API Call Tracking Model

/// Tracks API calls for rate limiting
struct UserEventAPICall: Identifiable, Codable {
    let id: Int
    let userId: UUID
    let searchLatitude: Double?
    let searchLongitude: Double?
    let searchLocationName: String?
    let searchRadiusMiles: Int?
    let calledAt: Date
    let eventsRetrieved: Int
    let success: Bool
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case searchLatitude = "search_latitude"
        case searchLongitude = "search_longitude"
        case searchLocationName = "search_location_name"
        case searchRadiusMiles = "search_radius_miles"
        case calledAt = "called_at"
        case eventsRetrieved = "events_retrieved"
        case success
        case errorMessage = "error_message"
    }
}
