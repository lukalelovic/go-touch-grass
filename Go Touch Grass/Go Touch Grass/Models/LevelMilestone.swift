//
//  LevelMilestone.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/28/25.
//

import Foundation

// MARK: - Level Milestone Model
struct LevelMilestone: Identifiable, Codable {
    let id: Int
    let milestoneLevel: Int
    let name: String
    let description: String?
    let icon: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case milestoneLevel = "milestone_level"
        case name
        case description
        case icon
        case createdAt = "created_at"
    }
}

// MARK: - User Level Info (aggregated from views)
struct UserLevelInfo: Codable {
    let userId: UUID
    let username: String
    let totalActivities: Int

    // Current level = total activities (1:1 mapping)
    let currentLevel: Int

    // Current milestone info (highest reached)
    let currentMilestoneLevel: Int?
    let milestoneName: String?
    let milestoneDescription: String?
    let milestoneIcon: String?

    // Next milestone info
    let nextMilestoneLevel: Int?
    let nextMilestoneName: String?
    let nextMilestoneIcon: String?
    let activitiesToNextMilestone: Int
    let progressToNextMilestone: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case totalActivities = "total_activities"
        case currentLevel = "current_level"
        case currentMilestoneLevel = "current_milestone_level"
        case milestoneName = "milestone_name"
        case milestoneDescription = "milestone_description"
        case milestoneIcon = "milestone_icon"
        case nextMilestoneLevel = "next_milestone_level"
        case nextMilestoneName = "next_milestone_name"
        case nextMilestoneIcon = "next_milestone_icon"
        case activitiesToNextMilestone = "activities_to_next_milestone"
        case progressToNextMilestone = "progress_to_next_milestone"
    }
}

// MARK: - Sample Data
extension LevelMilestone {
    static let milestones: [LevelMilestone] = [
        LevelMilestone(
            id: 1,
            milestoneLevel: 1,
            name: "Sprout",
            description: "Taking your first steps outdoors",
            icon: "leaf.fill",
            createdAt: Date()
        ),
        LevelMilestone(
            id: 2,
            milestoneLevel: 5,
            name: "Seedling",
            description: "Starting to grow",
            icon: "leaf.circle.fill",
            createdAt: Date()
        ),
        LevelMilestone(
            id: 3,
            milestoneLevel: 10,
            name: "Grass Toucher",
            description: "Getting comfortable outside",
            icon: "tree.fill",
            createdAt: Date()
        ),
        LevelMilestone(
            id: 4,
            milestoneLevel: 25,
            name: "Enthusiast",
            description: "A regular outdoor enthusiast",
            icon: "tree.circle.fill",
            createdAt: Date()
        ),
        LevelMilestone(
            id: 5,
            milestoneLevel: 50,
            name: "Explorer",
            description: "Exploring new paths",
            icon: "figure.hiking",
            createdAt: Date()
        ),
        LevelMilestone(
            id: 6,
            milestoneLevel: 75,
            name: "Naturalist",
            description: "Dedicated to outdoor life",
            icon: "globe.americas.fill",
            createdAt: Date()
        ),
        LevelMilestone(
            id: 7,
            milestoneLevel: 100,
            name: "Trailblazer",
            description: "Master of outdoor activities",
            icon: "mountain.2.fill",
            createdAt: Date()
        ),
        LevelMilestone(
            id: 8,
            milestoneLevel: 500,
            name: "Legend",
            description: "An inspiration to all",
            icon: "sparkles",
            createdAt: Date()
        )
    ]

    // Helper to get milestone for a given level
    static func milestoneFor(level: Int) -> LevelMilestone? {
        return milestones
            .filter { $0.milestoneLevel <= level }
            .max(by: { $0.milestoneLevel < $1.milestoneLevel })
    }

    // Helper to get next milestone for a given level
    static func nextMilestoneFor(level: Int) -> LevelMilestone? {
        return milestones
            .filter { $0.milestoneLevel > level }
            .min(by: { $0.milestoneLevel < $1.milestoneLevel })
    }
}

extension UserLevelInfo {
    // Helper to calculate progress percentage
    var progressPercentage: Int {
        Int(progressToNextMilestone)
    }

    // Display text for current status
    var levelDisplayText: String {
        if let milestoneName = milestoneName {
            return "Level \(currentLevel) - \(milestoneName)"
        } else {
            return "Level \(currentLevel)"
        }
    }

    // Display text for next milestone
    var nextMilestoneDisplayText: String? {
        guard let nextMilestoneName = nextMilestoneName,
              let nextMilestoneLevel = nextMilestoneLevel else {
            return nil
        }
        return "\(activitiesToNextMilestone) to \(nextMilestoneName) (Level \(nextMilestoneLevel))"
    }
}
