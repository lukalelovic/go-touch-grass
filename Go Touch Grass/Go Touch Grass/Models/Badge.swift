//
//  Badge.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/28/25.
//

import Foundation

// MARK: - Badge Category
enum BadgeCategory: String, Codable, CaseIterable {
    case activityCount = "activity_count"
    case activityType = "activity_type"
    case streak = "streak"
    case distance = "distance"
    case social = "social"
    case special = "special"

    var displayName: String {
        switch self {
        case .activityCount: return "Activity Count"
        case .activityType: return "Activity Type"
        case .streak: return "Streak"
        case .distance: return "Distance"
        case .social: return "Social"
        case .special: return "Special"
        }
    }
}

// MARK: - Badge Rarity
enum BadgeRarity: String, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"

    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .common: return (0.6, 0.6, 0.6) // Gray
        case .rare: return (0.0, 0.5, 1.0) // Blue
        case .epic: return (0.6, 0.0, 1.0) // Purple
        case .legendary: return (1.0, 0.8, 0.0) // Gold
        }
    }
}

// MARK: - Badge Criteria
struct BadgeCriteria: Codable {
    let type: String
    let count: Int?
    let activityTypeId: Int?
    let days: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case count
        case activityTypeId = "activity_type_id"
        case days
    }
}

// MARK: - Badge Model
struct Badge: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let category: BadgeCategory
    let icon: String?
    let criteria: BadgeCriteria
    let displayOrder: Int
    let rarity: BadgeRarity
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, icon, criteria, rarity
        case displayOrder = "display_order"
        case createdAt = "created_at"
    }
}

// MARK: - User Badge (Junction table)
struct UserBadge: Identifiable, Codable {
    let id: Int
    let userId: UUID
    let badgeId: Int
    let unlockedAt: Date
    let progress: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case badgeId = "badge_id"
        case unlockedAt = "unlocked_at"
        case progress
    }
}

// MARK: - Badge Progress (View model for UI)
struct BadgeProgress: Identifiable {
    let badge: Badge
    let isUnlocked: Bool
    let unlockedAt: Date?
    let progress: [String: Int]?

    var id: Int { badge.id }
}

// MARK: - Sample Data
extension Badge {
    static let sampleBadges: [Badge] = [
        Badge(
            id: 1,
            name: "First Steps",
            description: "Complete your first activity",
            category: .activityCount,
            icon: "figure.walk",
            criteria: BadgeCriteria(type: "total_activities", count: 1, activityTypeId: nil, days: nil),
            displayOrder: 1,
            rarity: .common,
            createdAt: Date()
        ),
        Badge(
            id: 2,
            name: "Getting Started",
            description: "Complete 5 activities",
            category: .activityCount,
            icon: "leaf.fill",
            criteria: BadgeCriteria(type: "total_activities", count: 5, activityTypeId: nil, days: nil),
            displayOrder: 2,
            rarity: .common,
            createdAt: Date()
        ),
        Badge(
            id: 3,
            name: "Committed",
            description: "Complete 25 activities",
            category: .activityCount,
            icon: "flame.fill",
            criteria: BadgeCriteria(type: "total_activities", count: 25, activityTypeId: nil, days: nil),
            displayOrder: 3,
            rarity: .rare,
            createdAt: Date()
        ),
        Badge(
            id: 4,
            name: "Peak Performer",
            description: "Complete 10 hiking activities",
            category: .activityType,
            icon: "mountain.2.fill",
            criteria: BadgeCriteria(type: "specific_activity", count: 10, activityTypeId: 1, days: nil),
            displayOrder: 10,
            rarity: .rare,
            createdAt: Date()
        ),
        Badge(
            id: 5,
            name: "Popular",
            description: "Receive 10 likes on your activities",
            category: .social,
            icon: "hand.thumbsup.fill",
            criteria: BadgeCriteria(type: "likes_received", count: 10, activityTypeId: nil, days: nil),
            displayOrder: 20,
            rarity: .common,
            createdAt: Date()
        )
    ]
}
