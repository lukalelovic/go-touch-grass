//
//  UserActivityPreferences.swift
//  Go Touch Grass
//
//  Created by Claude on 2026-05-31.
//  Represents user preferences for the activity recommendation algorithm
//

import Foundation

struct UserActivityPreferences: Codable, Hashable {
    let userId: UUID
    var preferredActivityTypes: [Int] // Array of activity_type_id
    var fitnessLevel: Int // 1: Beginner, 2: Intermediate, 3: Advanced
    var preferredDurationMinutes: Int
    var lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case preferredActivityTypes = "preferred_activity_types"
        case fitnessLevel = "fitness_level"
        case preferredDurationMinutes = "preferred_duration_minutes"
        case lastUpdated = "last_updated"
    }

    // MARK: - Default Values

    static func defaultPreferences(for userId: UUID) -> UserActivityPreferences {
        UserActivityPreferences(
            userId: userId,
            preferredActivityTypes: [], // Empty = no preference (algorithm will learn)
            fitnessLevel: 2, // Intermediate by default
            preferredDurationMinutes: 30,
            lastUpdated: Date()
        )
    }

    // MARK: - Helper Properties

    var fitnessLevelName: String {
        switch fitnessLevel {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return "Unknown"
        }
    }

    var durationDescription: String {
        if preferredDurationMinutes < 30 {
            return "Short (\(preferredDurationMinutes) min)"
        } else if preferredDurationMinutes < 60 {
            return "Medium (\(preferredDurationMinutes) min)"
        } else {
            let hours = Double(preferredDurationMinutes) / 60.0
            return "Long (\(String(format: "%.1f", hours)) hr)"
        }
    }

    // MARK: - Mutating Methods

    mutating func addPreferredActivityType(_ typeId: Int) {
        if !preferredActivityTypes.contains(typeId) {
            preferredActivityTypes.append(typeId)
            lastUpdated = Date()
        }
    }

    mutating func removePreferredActivityType(_ typeId: Int) {
        preferredActivityTypes.removeAll { $0 == typeId }
        lastUpdated = Date()
    }

    mutating func updateFitnessLevel(_ level: Int) {
        guard level >= 1 && level <= 3 else { return }
        fitnessLevel = level
        lastUpdated = Date()
    }

    mutating func updatePreferredDuration(_ minutes: Int) {
        guard minutes > 0 else { return }
        preferredDurationMinutes = minutes
        lastUpdated = Date()
    }
}
