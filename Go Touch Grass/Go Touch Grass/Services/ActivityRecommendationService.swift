//
//  ActivityRecommendationService.swift
//  Go Touch Grass
//
//  Created by Claude on 2026-05-31.
//  Service for managing daily activity recommendations
//

import Foundation
import Supabase

// MARK: - Function Parameters for RPC calls

nonisolated struct GetRecommendationsParams: Encodable, Sendable {
    let p_user_id: String
}

nonisolated struct MarkLoggedParams: Encodable, Sendable {
    let p_recommendation_id: String
}

class ActivityRecommendationService {
    private let supabase = SupabaseManager.shared.client

    // MARK: - Fetch Today's Recommendations

    /// Fetch today's recommendations for the current user from the database
    func getTodaysRecommendations() async throws -> [ActivityRecommendation] {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw RecommendationError.notAuthenticated
        }

        print("📋 Fetching today's recommendations for user: \(userId)")

        // Call the database function get_todays_recommendations
        let params = GetRecommendationsParams(p_user_id: userId.uuidString)

        do {
            let response: [RecommendationResponse] = try await supabase
                .rpc("get_todays_recommendations", params: params)
                .execute()
                .value

            print("✅ Fetched \(response.count) recommendations")

            // Convert to ActivityRecommendation objects
            let recommendations = response.map { $0.toActivityRecommendation(userId: userId) }
            return recommendations.sorted { $0.cardPosition < $1.cardPosition }

        } catch {
            print("❌ Error fetching recommendations: \(error)")
            throw RecommendationError.fetchFailed(error)
        }
    }

    // MARK: - Mark Recommendation as Logged

    /// Mark a recommendation as logged (when user completes it)
    func markRecommendationLogged(recommendationId: UUID) async throws {
        print("📝 Marking recommendation \(recommendationId) as logged")

        let params = MarkLoggedParams(p_recommendation_id: recommendationId.uuidString)

        do {
            _ = try await supabase
                .rpc("mark_recommendation_logged", params: params)
                .execute()

            print("✅ Marked recommendation as logged")

        } catch {
            print("❌ Error marking recommendation as logged: \(error)")
            throw RecommendationError.updateFailed(error)
        }
    }

    // MARK: - Generate Daily Recommendations (MVP - Simple Version)

    /// Generate 5 daily recommendations for a user
    /// This is a simplified MVP version that selects random templates
    /// In production, this would use a more sophisticated algorithm
    func generateDailyRecommendations(for userId: UUID, date: Date = Date()) async throws -> [ActivityRecommendation] {
        print("🎲 Generating daily recommendations for user: \(userId)")

        // 1. Check if recommendations already exist for today
        let existing = try await checkExistingRecommendations(for: userId, date: date)
        if !existing.isEmpty {
            print("✅ Recommendations already exist for today")
            return existing
        }

        // 2. Fetch all active templates
        let templates = try await fetchActiveTemplates()
        guard templates.count >= 5 else {
            throw RecommendationError.insufficientTemplates
        }

        // 3. Get user preferences (if any)
        let preferences = try? await getUserPreferences(for: userId)

        // 4. Simple selection: pick 5 random templates with some variety
        let selectedTemplates = selectTemplates(from: templates, preferences: preferences, count: 5)

        // 5. Create recommendation records
        var recommendations: [ActivityRecommendation] = []

        for (index, template) in selectedTemplates.enumerated() {
            let recommendation = try await createRecommendation(
                userId: userId,
                template: template,
                position: index + 1,
                date: date
            )
            recommendations.append(recommendation)
        }

        print("✅ Generated \(recommendations.count) recommendations")
        return recommendations.sorted { $0.cardPosition < $1.cardPosition }
    }

    // MARK: - Private Helper Methods

    private func checkExistingRecommendations(for userId: UUID, date: Date) async throws -> [ActivityRecommendation] {
        let calendar = Calendar.current
        let dateString = ISO8601DateFormatter().string(from: calendar.startOfDay(for: date))

        do {
            let response = try await supabase
                .from("daily_activity_recommendations")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("recommendation_date", value: dateString)
                .execute()

            let recommendations: [ActivityRecommendation] = try JSONDecoder().decode(
                [ActivityRecommendation].self,
                from: response.data
            )

            return recommendations
        } catch {
            // If no recommendations exist, return empty array
            return []
        }
    }

    private func fetchActiveTemplates() async throws -> [ActivityTemplate] {
        do {
            let response = try await supabase
                .from("activity_templates")
                .select()
                .eq("is_active", value: true)
                .execute()

            let templates: [ActivityTemplate] = try JSONDecoder().decode(
                [ActivityTemplate].self,
                from: response.data
            )

            print("✅ Fetched \(templates.count) active templates")
            return templates

        } catch {
            print("❌ Error fetching templates: \(error)")
            throw RecommendationError.fetchFailed(error)
        }
    }

    private func getUserPreferences(for userId: UUID) async throws -> UserActivityPreferences? {
        do {
            let response = try await supabase
                .from("user_activity_preferences")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()

            let preferences = try JSONDecoder().decode(
                UserActivityPreferences.self,
                from: response.data
            )

            return preferences

        } catch {
            // If no preferences exist, return nil (use defaults)
            print("ℹ️ No preferences found for user, using defaults")
            return nil
        }
    }

    private func selectTemplates(
        from templates: [ActivityTemplate],
        preferences: UserActivityPreferences?,
        count: Int
    ) -> [ActivityTemplate] {
        // Simple MVP algorithm:
        // 1. Filter by season relevance
        // 2. Prefer user's preferred activity types
        // 3. Ensure variety (max 2 per activity type)
        // 4. Random selection within constraints

        var seasonalTemplates = templates.filter { $0.isSeasonallyRelevant }
        if seasonalTemplates.isEmpty {
            seasonalTemplates = templates
        }

        var selected: [ActivityTemplate] = []
        var activityTypeCounts: [Int: Int] = [:]

        // First, try to add preferred types
        if let prefs = preferences, !prefs.preferredActivityTypes.isEmpty {
            let preferredTemplates = seasonalTemplates.filter { template in
                prefs.preferredActivityTypes.contains(template.activityTypeId)
            }.shuffled()

            for template in preferredTemplates {
                let typeCount = activityTypeCounts[template.activityTypeId, default: 0]
                if typeCount < 2 && selected.count < count {
                    selected.append(template)
                    activityTypeCounts[template.activityTypeId] = typeCount + 1
                }
            }
        }

        // Fill remaining slots with variety
        let remainingTemplates = seasonalTemplates.filter { template in
            !selected.contains(where: { $0.id == template.id })
        }.shuffled()

        for template in remainingTemplates {
            if selected.count >= count { break }

            let typeCount = activityTypeCounts[template.activityTypeId, default: 0]
            if typeCount < 2 {
                selected.append(template)
                activityTypeCounts[template.activityTypeId] = typeCount + 1
            }
        }

        // If still not enough, just add random ones
        while selected.count < count && selected.count < templates.count {
            let remaining = templates.filter { template in
                !selected.contains(where: { $0.id == template.id })
            }
            if let random = remaining.randomElement() {
                selected.append(random)
            } else {
                break
            }
        }

        return selected
    }

    private func createRecommendation(
        userId: UUID,
        template: ActivityTemplate,
        position: Int,
        date: Date
    ) async throws -> ActivityRecommendation {
        // Create the recommendation record
        struct RecommendationInsert: Codable {
            let userId: String
            let recommendationDate: String
            let activityTemplateId: Int
            let cardPosition: Int
            let personalizedPrompt: String
            let personalizedChallenge: String?
            let activityTypeId: Int
            let estimatedDurationMinutes: Int?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case recommendationDate = "recommendation_date"
                case activityTemplateId = "activity_template_id"
                case cardPosition = "card_position"
                case personalizedPrompt = "personalized_prompt"
                case personalizedChallenge = "personalized_challenge"
                case activityTypeId = "activity_type_id"
                case estimatedDurationMinutes = "estimated_duration_minutes"
            }
        }

        let calendar = Calendar.current
        let dateString = ISO8601DateFormatter().string(from: calendar.startOfDay(for: date))

        let insert = RecommendationInsert(
            userId: userId.uuidString,
            recommendationDate: dateString,
            activityTemplateId: template.id,
            cardPosition: position,
            personalizedPrompt: template.promptTemplate, // MVP: no personalization yet
            personalizedChallenge: template.challengeTemplate,
            activityTypeId: template.activityTypeId,
            estimatedDurationMinutes: template.estimatedDurationMinutes
        )

        do {
            let response = try await supabase
                .from("daily_activity_recommendations")
                .insert(insert)
                .select()
                .single()
                .execute()

            let recommendation = try JSONDecoder().decode(
                ActivityRecommendation.self,
                from: response.data
            )

            return recommendation

        } catch {
            print("❌ Error creating recommendation: \(error)")
            throw RecommendationError.creationFailed(error)
        }
    }
}

// MARK: - Recommendation Errors

enum RecommendationError: LocalizedError {
    case notAuthenticated
    case fetchFailed(Error)
    case creationFailed(Error)
    case updateFailed(Error)
    case insufficientTemplates

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .fetchFailed(let error):
            return "Failed to fetch recommendations: \(error.localizedDescription)"
        case .creationFailed(let error):
            return "Failed to create recommendation: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update recommendation: \(error.localizedDescription)"
        case .insufficientTemplates:
            return "Not enough activity templates available"
        }
    }
}
