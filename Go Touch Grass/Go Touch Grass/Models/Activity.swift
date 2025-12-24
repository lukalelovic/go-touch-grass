//
//  Activity.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation

// MARK: - Activity Model
struct Activity: Identifiable {
    let id: UUID
    let user: User
    let activityType: ActivityType
    let timestamp: Date
    let notes: String?
    let location: Location?

    init(
        id: UUID = UUID(),
        user: User,
        activityType: ActivityType,
        timestamp: Date = Date(),
        notes: String? = nil,
        location: Location? = nil
    ) {
        self.id = id
        self.user = user
        self.activityType = activityType
        self.timestamp = timestamp
        self.notes = notes
        self.location = location
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
