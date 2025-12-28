//
//  User.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation

// MARK: - User Model
struct User: Identifiable {
    let id: UUID
    let username: String
    let email: String?
    let profilePictureUrl: String?

    init(id: UUID = UUID(), username: String, email: String? = nil, profilePictureUrl: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.profilePictureUrl = profilePictureUrl
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
