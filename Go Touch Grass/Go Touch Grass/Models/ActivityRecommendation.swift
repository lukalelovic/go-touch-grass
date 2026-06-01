//
//  ActivityRecommendation.swift
//  Go Touch Grass
//
//  Created by Claude on 2026-05-31.
//  Represents a personalized daily activity recommendation for a user
//

import Foundation

struct ActivityRecommendation: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let recommendationDate: Date
    let activityTemplateId: Int
    let cardPosition: Int
    let personalizedPrompt: String
    let personalizedChallenge: String?
    let activityTypeId: Int
    let estimatedDurationMinutes: Int?
    var wasLogged: Bool
    var loggedAt: Date?
    let createdAt: Date

    // Extended property for displaying activity type info
    var activityType: ActivityType?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recommendationDate = "recommendation_date"
        case activityTemplateId = "activity_template_id"
        case cardPosition = "card_position"
        case personalizedPrompt = "personalized_prompt"
        case personalizedChallenge = "personalized_challenge"
        case activityTypeId = "activity_type_id"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case wasLogged = "was_logged"
        case loggedAt = "logged_at"
        case createdAt = "created_at"
        // Note: activityType is populated separately from joined query
    }

    // MARK: - Helper Properties

    var durationDescription: String {
        guard let minutes = estimatedDurationMinutes else { return "Flexible" }

        if minutes < 30 {
            return "Quick (\(minutes) min)"
        } else if minutes < 60 {
            return "Medium (\(minutes) min)"
        } else {
            let hours = Double(minutes) / 60.0
            return "Long (\(String(format: "%.1f", hours)) hr)"
        }
    }

    var isAvailableToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(recommendationDate)
    }

    // For UI display
    var displayPrompt: String {
        personalizedPrompt
    }

    var displayChallenge: String? {
        personalizedChallenge
    }
}

// MARK: - Response from get_todays_recommendations function
struct RecommendationResponse: Codable {
    let id: UUID
    let cardPosition: Int
    let personalizedPrompt: String
    let personalizedChallenge: String?
    let activityTypeId: Int
    let activityTypeName: String
    let activityTypeIcon: String
    let estimatedDurationMinutes: Int?
    let wasLogged: Bool
    let loggedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case cardPosition = "card_position"
        case personalizedPrompt = "personalized_prompt"
        case personalizedChallenge = "personalized_challenge"
        case activityTypeId = "activity_type_id"
        case activityTypeName = "activity_type_name"
        case activityTypeIcon = "activity_type_icon"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case wasLogged = "was_logged"
        case loggedAt = "logged_at"
    }

    // Convert to ActivityRecommendation
    func toActivityRecommendation(userId: UUID, recommendationDate: Date = Date(), templateId: Int = 0) -> ActivityRecommendation {
        let activityType = ActivityType(
            id: activityTypeId,
            name: activityTypeName,
            icon: activityTypeIcon
        )

        var recommendation = ActivityRecommendation(
            id: id,
            userId: userId,
            recommendationDate: recommendationDate,
            activityTemplateId: templateId,
            cardPosition: cardPosition,
            personalizedPrompt: personalizedPrompt,
            personalizedChallenge: personalizedChallenge,
            activityTypeId: activityTypeId,
            estimatedDurationMinutes: estimatedDurationMinutes,
            wasLogged: wasLogged,
            loggedAt: loggedAt,
            createdAt: Date()
        )
        recommendation.activityType = activityType
        return recommendation
    }
}
