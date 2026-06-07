//
//  RecommendationViewModel.swift
//  Go Touch Grass
//
//  Created by Claude on 2026-05-31.
//  ViewModel for managing daily activity recommendations
//

import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class RecommendationViewModel: ObservableObject {
    @Published var todaysRecommendations: [ActivityRecommendation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var refreshCount = 0

    private let service = ActivityRecommendationService()
    private let maxRefreshesPerDay = 1

    // MARK: - Load Today's Recommendations

    func loadTodaysRecommendations() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📋 Loading today's recommendations...")

            // Try to fetch existing recommendations
            var recommendations = try await service.getTodaysRecommendations()

            // If no recommendations exist, generate them
            if recommendations.isEmpty {
                print("💡 No recommendations found, generating new ones...")
                guard let userId = SupabaseManager.shared.currentUser?.id else {
                    throw RecommendationError.notAuthenticated
                }

                recommendations = try await service.generateDailyRecommendations(for: userId)
            }

            todaysRecommendations = recommendations
            print("✅ Loaded \(recommendations.count) recommendations")

        } catch {
            print("❌ Error loading recommendations: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Manual Refresh

    func refreshRecommendations() async {
        guard refreshCount < maxRefreshesPerDay else {
            errorMessage = "You've reached the maximum number of refreshes for today. Check back tomorrow!"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            guard let userId = SupabaseManager.shared.currentUser?.id else {
                throw RecommendationError.notAuthenticated
            }

            print("🔄 Manually refreshing recommendations...")

            // TODO: In production, this would delete old recommendations and generate new ones
            // For MVP, we'll just regenerate
            let recommendations = try await service.generateDailyRecommendations(for: userId)

            todaysRecommendations = recommendations
            refreshCount += 1

            print("✅ Refreshed recommendations (count: \(refreshCount)/\(maxRefreshesPerDay))")

        } catch {
            print("❌ Error refreshing recommendations: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Log Activity

    func logActivity(_ recommendation: ActivityRecommendation) {
        guard !recommendation.wasLogged else { return }

        Task {
            do {
                guard let userId = SupabaseManager.shared.currentUser?.id else {
                    throw RecommendationError.notAuthenticated
                }

                print("📝 Logging activity for recommendation: \(recommendation.id)")

                // Mark recommendation as logged in database
                try await service.markRecommendationLogged(recommendationId: recommendation.id)

                // Create feed post similar to share activity
                let activityType = recommendation.activityType ?? ActivityType(
                    id: recommendation.activityTypeId,
                    name: "Outdoor Activity",
                    icon: nil
                )
                let prompt = recommendation.personalizedPrompt
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let notes = "did \(prompt) today! Now it's your turn!"

                let activity = try await SupabaseManager.shared.createActivity(
                    userId: userId,
                    activityType: activityType,
                    notes: notes,
                    location: nil,
                    timestamp: Date()
                )

                // Add to local store so feed updates immediately
                ActivityStore.shared.addActivity(activity)

                // Update local state
                if let index = todaysRecommendations.firstIndex(where: { $0.id == recommendation.id }) {
                    var updated = todaysRecommendations[index]
                    updated.wasLogged = true
                    updated.loggedAt = Date()
                    todaysRecommendations[index] = updated
                }

                print("✅ Activity logged and posted to feed")

            } catch {
                print("❌ Error logging activity: \(error)")
                errorMessage = "Failed to log activity: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helper Properties

    var canRefresh: Bool {
        refreshCount < maxRefreshesPerDay
    }

    var refreshesRemaining: Int {
        max(0, maxRefreshesPerDay - refreshCount)
    }

    var hasRecommendations: Bool {
        !todaysRecommendations.isEmpty
    }

    var completedCount: Int {
        todaysRecommendations.filter { $0.wasLogged }.count
    }

    var totalCount: Int {
        todaysRecommendations.count
    }
}
