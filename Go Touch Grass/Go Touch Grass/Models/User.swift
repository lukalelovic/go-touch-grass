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
    let isPrivate: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profilePictureUrl = "profile_picture_url"
        case isPrivate = "is_private"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        profilePictureUrl = try container.decodeIfPresent(String.self, forKey: .profilePictureUrl)
        // Default to false if is_private doesn't exist in database (for existing users)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    init(
        id: UUID = UUID(),
        username: String,
        email: String? = nil,
        profilePictureUrl: String? = nil,
        isPrivate: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.profilePictureUrl = profilePictureUrl
        self.isPrivate = isPrivate
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
