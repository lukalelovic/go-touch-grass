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
