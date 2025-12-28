//
//  UserStats.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/28/25.
//

import Foundation

// MARK: - User Stats Model (from user_stats view)
struct UserStats: Codable {
    let userId: UUID
    let username: String
    let userCreatedAt: Date

    // Activity statistics
    let totalActivities: Int
    let totalActiveDays: Int

    // Activity type breakdown (JSONB from database)
    let activitiesByType: [String: Int]

    // Social statistics
    let totalLikesReceived: Int
    let totalLikesGiven: Int

    // Date information
    let lastActivityDate: Date?
    let firstActivityDate: Date?

    // Badge progress
    let badgesUnlocked: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case userCreatedAt = "user_created_at"
        case totalActivities = "total_activities"
        case totalActiveDays = "total_active_days"
        case activitiesByType = "activities_by_type"
        case totalLikesReceived = "total_likes_received"
        case totalLikesGiven = "total_likes_given"
        case lastActivityDate = "last_activity_date"
        case firstActivityDate = "first_activity_date"
        case badgesUnlocked = "badges_unlocked"
    }
}

// MARK: - Helper Extensions
extension UserStats {
    // Get count for a specific activity type
    func activityCount(for activityType: ActivityType) -> Int {
        return activitiesByType[activityType.rawValue] ?? 0
    }

    // Get most performed activity type
    var mostPerformedActivity: (type: String, count: Int)? {
        guard let max = activitiesByType.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return (type: max.key, count: max.value)
    }

    // Calculate account age in days
    var accountAgeDays: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: userCreatedAt, to: Date()).day ?? 0
        return days
    }

    // Average activities per day
    var averageActivitiesPerDay: Double {
        let days = max(accountAgeDays, 1)
        return Double(totalActivities) / Double(days)
    }
}

// MARK: - Sample Data
extension UserStats {
    static let sampleStats = UserStats(
        userId: UUID(),
        username: "outdoor_enthusiast",
        userCreatedAt: Date().addingTimeInterval(-30 * 24 * 3600), // 30 days ago
        totalActivities: 15,
        totalActiveDays: 12,
        activitiesByType: [
            "Hiking": 5,
            "Running": 4,
            "Cycling": 3,
            "Walking": 2,
            "Swimming": 1
        ],
        totalLikesReceived: 23,
        totalLikesGiven: 18,
        lastActivityDate: Date().addingTimeInterval(-3600), // 1 hour ago
        firstActivityDate: Date().addingTimeInterval(-25 * 24 * 3600), // 25 days ago
        badgesUnlocked: 3
    )
}
