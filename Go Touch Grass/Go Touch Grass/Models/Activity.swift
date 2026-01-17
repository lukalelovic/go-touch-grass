//
//  Activity.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation

// MARK: - Activity Model
struct Activity: Identifiable, Codable {
    let id: UUID
    let user: User
    let activityType: ActivityType
    let timestamp: Date
    let notes: String?
    let location: Location?
    let likeCount: Int?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case email
        case profilePictureUrl = "profile_picture_url"
        case activityTypeName = "activity_type_name"
        case activityTypeIcon = "activity_type_icon"
        case notes
        case timestamp
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case locationName = "location_name"
        case likeCount = "like_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        user: User,
        activityType: ActivityType,
        timestamp: Date = Date(),
        notes: String? = nil,
        location: Location? = nil,
        likeCount: Int? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.user = user
        self.activityType = activityType
        self.timestamp = timestamp
        self.notes = notes
        self.location = location
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder to handle the database view structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)

        // Decode user from flattened structure
        let userId = try container.decode(UUID.self, forKey: .userId)
        let username = try container.decode(String.self, forKey: .username)
        let email = try container.decodeIfPresent(String.self, forKey: .email)
        let profilePictureUrl = try container.decodeIfPresent(String.self, forKey: .profilePictureUrl)

        user = User(
            id: userId,
            username: username,
            email: email,
            profilePictureUrl: profilePictureUrl
        )

        // Decode activity type from flattened structure
        let activityTypeName = try container.decode(String.self, forKey: .activityTypeName)
        let activityTypeIcon = try container.decodeIfPresent(String.self, forKey: .activityTypeIcon)

        activityType = ActivityType(rawValue: activityTypeName) ?? .other

        timestamp = try container.decode(Date.self, forKey: .timestamp)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        // Decode location from flattened structure
        let latitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
        let longitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
        let locationName = try container.decodeIfPresent(String.self, forKey: .locationName)

        if let latitude = latitude, let longitude = longitude {
            location = Location(
                latitude: latitude,
                longitude: longitude,
                name: locationName
            )
        } else {
            location = nil
        }

        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    // Custom encoder for creating activities
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(user.id, forKey: .userId)
        try container.encode(activityType.rawValue, forKey: .activityTypeName)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(timestamp, forKey: .timestamp)

        if let location = location {
            try container.encode(location.latitude, forKey: .locationLatitude)
            try container.encode(location.longitude, forKey: .locationLongitude)
            try container.encodeIfPresent(location.name, forKey: .locationName)
        }
    }
}

// MARK: - Sample Hardcoded Data
extension Activity {
    static let sampleActivities: [Activity] = [
        Activity(
            user: User.sampleUsers[0],
            activityType: .hiking,
            timestamp: Date().addingTimeInterval(-3600),
            notes: "Beautiful sunrise hike at the peak! The view was absolutely worth the early wake-up.",
            location: Location(latitude: 34.0, longitude: -118.0, name: "Mountain Trail")
        ),
        Activity(
            user: User.sampleUsers[1],
            activityType: .running,
            timestamp: Date().addingTimeInterval(-7200),
            notes: "Morning 5K run through the park. Feeling energized!",
            location: Location(latitude: 34.1, longitude: -118.1, name: "City Park")
        ),
        Activity(
            user: User.sampleUsers[2],
            activityType: .cycling,
            timestamp: Date().addingTimeInterval(-10800),
            notes: "30 mile bike ride along the coast. Perfect weather today.",
            location: Location(latitude: 33.9, longitude: -118.2, name: "Coastal Path")
        ),
        Activity(
            user: User.sampleUsers[3],
            activityType: .swimming,
            timestamp: Date().addingTimeInterval(-14400),
            notes: "Refreshing swim at the beach!",
            location: Location(latitude: 33.8, longitude: -118.3, name: "Sunset Beach")
        ),
        Activity(
            user: User.sampleUsers[4],
            activityType: .climbing,
            timestamp: Date().addingTimeInterval(-18000),
            notes: "Finally conquered that difficult route I've been working on for weeks!",
            location: Location(latitude: 34.2, longitude: -117.9, name: "Rock Climbing Gym")
        ),
        Activity(
            user: User.sampleUsers[0],
            activityType: .walking,
            timestamp: Date().addingTimeInterval(-21600),
            notes: "Evening walk with the dog. Found a new trail!",
            location: Location(latitude: 34.05, longitude: -118.05, name: "Neighborhood Trail")
        ),
        Activity(
            user: User.sampleUsers[2],
            activityType: .camping,
            timestamp: Date().addingTimeInterval(-86400),
            notes: "Weekend camping trip under the stars. No cell service, just nature.",
            location: Location(latitude: 35.0, longitude: -119.0, name: "National Forest Campground")
        )
    ]
}
