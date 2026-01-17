//
//  User.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: UUID
    let username: String
    let email: String?
    let profilePictureUrl: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profilePictureUrl = "profile_picture_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        username: String,
        email: String? = nil,
        profilePictureUrl: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.profilePictureUrl = profilePictureUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUsers = [
        User(username: "outdoor_enthusiast", profilePictureUrl: "person.circle.fill"),
        User(username: "trail_runner", profilePictureUrl: "figure.run.circle.fill"),
        User(username: "nature_lover", profilePictureUrl: "leaf.circle.fill"),
        User(username: "adventure_seeker", profilePictureUrl: "mountain.2.circle.fill"),
        User(username: "mountain_climber", profilePictureUrl: "figure.hiking.circle.fill")
    ]
}
