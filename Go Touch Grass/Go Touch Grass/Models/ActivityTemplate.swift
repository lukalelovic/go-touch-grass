//
//  ActivityTemplate.swift
//  Go Touch Grass
//
//  Created by Claude on 2026-05-31.
//  Represents a reusable activity prompt template for the recommendation system
//

import Foundation

struct ActivityTemplate: Identifiable, Codable, Hashable {
    let id: Int
    let activityTypeId: Int
    let promptTemplate: String
    let challengeTemplate: String?
    let estimatedDurationMinutes: Int?
    let difficultyLevel: Int // 1: Easy, 2: Medium, 3: Hard
    let seasonTags: [String]? // nil = year-round, or ["spring", "summer", "fall", "winter"]
    let requiresEquipment: Bool
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case activityTypeId = "activity_type_id"
        case promptTemplate = "prompt_template"
        case challengeTemplate = "challenge_template"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case difficultyLevel = "difficulty_level"
        case seasonTags = "season_tags"
        case requiresEquipment = "requires_equipment"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Helper Properties

    var difficultyName: String {
        switch difficultyLevel {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return "Unknown"
        }
    }

    var isSeasonallyRelevant: Bool {
        guard let tags = seasonTags else { return true } // Year-round if no tags

        // Get current season
        let month = Calendar.current.component(.month, from: Date())
        let currentSeason: String

        switch month {
        case 3...5: currentSeason = "spring"
        case 6...8: currentSeason = "summer"
        case 9...11: currentSeason = "fall"
        default: currentSeason = "winter"
        }

        return tags.contains(currentSeason)
    }
}
