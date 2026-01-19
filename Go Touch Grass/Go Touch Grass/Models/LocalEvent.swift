//
//  LocalEvent.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation

// MARK: - Local Event Model
struct LocalEvent: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let eventType: ActivityType
    let location: Location
    let date: Date
    let imageURL: String? // Placeholder for future image URLs
    let organizerName: String
    let attendeeCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        eventType: ActivityType,
        location: Location,
        date: Date,
        imageURL: String? = nil,
        organizerName: String,
        attendeeCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.eventType = eventType
        self.location = location
        self.date = date
        self.imageURL = imageURL
        self.organizerName = organizerName
        self.attendeeCount = attendeeCount
    }
}

// MARK: - Sample Events Data
extension LocalEvent {
    static let sampleEvents: [LocalEvent] = [
        LocalEvent(
            title: "Morning Trail Run",
            description: "Join us for a refreshing 5K trail run through beautiful forest paths. All fitness levels welcome!",
            eventType: ActivityType(id: 2, name: "Running", icon: "figure.run"),
            location: Location(latitude: 34.05, longitude: -118.25, name: "Griffith Park Trails"),
            date: Date().addingTimeInterval(86400), // Tomorrow
            organizerName: "LA Trail Runners",
            attendeeCount: 15
        ),
        LocalEvent(
            title: "Sunset Beach Yoga",
            description: "Relax and unwind with a peaceful yoga session as the sun sets over the ocean. Bring your own mat!",
            eventType: ActivityType(id: 11, name: "Other", icon: "figure.outdoor.cycle"),
            location: Location(latitude: 33.97, longitude: -118.45, name: "Santa Monica Beach"),
            date: Date().addingTimeInterval(172800), // 2 days from now
            organizerName: "Beachside Wellness",
            attendeeCount: 23
        ),
        LocalEvent(
            title: "Mountain Bike Adventure",
            description: "Intermediate level mountain biking through scenic canyon trails. Helmets required.",
            eventType: ActivityType(id: 3, name: "Cycling", icon: "bicycle"),
            location: Location(latitude: 34.12, longitude: -118.08, name: "Topanga State Park"),
            date: Date().addingTimeInterval(259200), // 3 days from now
            organizerName: "SoCal Mountain Bikers",
            attendeeCount: 12
        ),
        LocalEvent(
            title: "Community Hike & Picnic",
            description: "Family-friendly hike followed by a potluck picnic at the summit. Bring food to share!",
            eventType: ActivityType(id: 1, name: "Hiking", icon: "figure.hiking"),
            location: Location(latitude: 34.18, longitude: -118.35, name: "Runyon Canyon"),
            date: Date().addingTimeInterval(345600), // 4 days from now
            organizerName: "LA Hiking Club",
            attendeeCount: 31
        ),
        LocalEvent(
            title: "Open Water Swimming",
            description: "Supervised open water swimming session in the bay. Wetsuits recommended.",
            eventType: ActivityType(id: 4, name: "Swimming", icon: "figure.pool.swim"),
            location: Location(latitude: 33.75, longitude: -118.20, name: "Long Beach Marina"),
            date: Date().addingTimeInterval(432000), // 5 days from now
            organizerName: "Coastal Swimmers",
            attendeeCount: 8
        ),
        LocalEvent(
            title: "Rock Climbing Workshop",
            description: "Beginner-friendly outdoor climbing workshop. All equipment provided, no experience needed!",
            eventType: ActivityType(id: 5, name: "Climbing", icon: "figure.climbing"),
            location: Location(latitude: 34.28, longitude: -118.58, name: "Stoney Point"),
            date: Date().addingTimeInterval(518400), // 6 days from now
            organizerName: "Vertical Adventures",
            attendeeCount: 10
        ),
        LocalEvent(
            title: "Weekend Camping Trip",
            description: "Two-day camping adventure under the stars. Campfire stories and s'mores included!",
            eventType: ActivityType(id: 7, name: "Camping", icon: "tent.fill"),
            location: Location(latitude: 34.45, longitude: -118.95, name: "Leo Carrillo State Park"),
            date: Date().addingTimeInterval(604800), // 7 days from now
            organizerName: "Weekend Warriors",
            attendeeCount: 18
        ),
        LocalEvent(
            title: "Sunrise Kayaking Tour",
            description: "Paddle through calm waters as the sun rises. Perfect for photography enthusiasts!",
            eventType: ActivityType(id: 6, name: "Kayaking", icon: "figure.kayaking"),
            location: Location(latitude: 33.68, longitude: -118.01, name: "Newport Back Bay"),
            date: Date().addingTimeInterval(691200), // 8 days from now
            organizerName: "Paddle Paradise",
            attendeeCount: 14
        )
    ]
}
