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

    init(id: UUID = UUID(), username: String, email: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUsers = [
        User(username: "outdoor_enthusiast"),
        User(username: "trail_runner"),
        User(username: "nature_lover"),
        User(username: "adventure_seeker"),
        User(username: "mountain_climber")
    ]
}
