//
//  ActivityRecommendationCard.swift
//  Go Touch Grass
//
//  Created by Claude on 2026-05-31.
//  Card component for displaying a single activity recommendation
//

import SwiftUI

struct ActivityRecommendationCard: View {
    let recommendation: ActivityRecommendation
    let onLog: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let colors = AppColors()
        
        VStack(alignment: .leading, spacing: 12) {
            // Activity type header
            HStack(spacing: 8) {
                if let activityType = recommendation.activityType,
                   let icon = activityType.icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(colors.secondaryText)
                }

                Text(recommendation.activityType?.name ?? "Activity")
                    .font(.subheadline)
                    .foregroundStyle(colors.secondaryText)

                Spacer()

                // Logged badge
                if recommendation.wasLogged {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Done")
                            .font(.caption)
                    }
                    .foregroundStyle(colors.accent)
                }
            }

            // Activity prompt
            Text(recommendation.personalizedPrompt)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(colors.primaryText)
                .lineLimit(3)

            // Challenge (if exists)
            if let challenge = recommendation.personalizedChallenge {
                Text(challenge)
                    .font(.body)
                    .foregroundStyle(colors.secondaryText)
                    .lineLimit(2)
            }

            Divider()
                .background(colors.divider)

            // Duration and action button
            HStack {
                // Duration badge
                if let duration = recommendation.estimatedDurationMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(duration) min")
                            .font(.caption)
                    }
                    .foregroundStyle(colors.secondaryText)
                }

                Spacer()

                // Touched Grass button
                Button(action: onLog) {
                    HStack(spacing: 6) {
                        Image(systemName: recommendation.wasLogged ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.subheadline)
                        Text(recommendation.wasLogged ? "Completed" : "Touched Grass")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(recommendation.wasLogged ? .white.opacity(0.7) : colors.primaryBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(recommendation.wasLogged ? Color.gray : .white)
                    .cornerRadius(8)
                }
                .disabled(recommendation.wasLogged)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.cardBackground)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(recommendation.wasLogged ? colors.accent.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview("Recommendation Card - Not Logged") {
    ActivityRecommendationCard(
        recommendation: ActivityRecommendation(
            id: UUID(),
            userId: UUID(),
            recommendationDate: Date(),
            activityTemplateId: 1,
            cardPosition: 1,
            personalizedPrompt: "Go for a morning run!",
            personalizedChallenge: "Beat yesterday's pace",
            activityTypeId: 2,
            estimatedDurationMinutes: 30,
            wasLogged: false,
            loggedAt: nil,
            createdAt: Date(),
            activityType: ActivityType(id: 2, name: "Running", icon: "figure.run")
        ),
        onLog: {
            print("Log button tapped")
        }
    )
    .environmentObject(ThemeManager.shared)
    .padding()
    .background(AppColors().primaryBackground)
}

#Preview("Recommendation Card - Logged") {
    ActivityRecommendationCard(
        recommendation: ActivityRecommendation(
            id: UUID(),
            userId: UUID(),
            recommendationDate: Date(),
            activityTemplateId: 1,
            cardPosition: 1,
            personalizedPrompt: "Take a 15-minute nature walk!",
            personalizedChallenge: "Count different bird species",
            activityTypeId: 10,
            estimatedDurationMinutes: 15,
            wasLogged: true,
            loggedAt: Date(),
            createdAt: Date(),
            activityType: ActivityType(id: 10, name: "Walking", icon: "figure.walk")
        ),
        onLog: {
            print("Log button tapped")
        }
    )
    .environmentObject(ThemeManager.shared)
    .padding()
    .background(AppColors().primaryBackground)
}

#Preview("Multiple Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ActivityRecommendationCard(
                recommendation: ActivityRecommendation(
                    id: UUID(),
                    userId: UUID(),
                    recommendationDate: Date(),
                    activityTemplateId: 1,
                    cardPosition: 1,
                    personalizedPrompt: "Go for a morning run!",
                    personalizedChallenge: "Beat yesterday's pace",
                    activityTypeId: 2,
                    estimatedDurationMinutes: 30,
                    wasLogged: false,
                    loggedAt: nil,
                    createdAt: Date(),
                    activityType: ActivityType(id: 2, name: "Running", icon: "figure.run")
                ),
                onLog: {}
            )

            ActivityRecommendationCard(
                recommendation: ActivityRecommendation(
                    id: UUID(),
                    userId: UUID(),
                    recommendationDate: Date(),
                    activityTemplateId: 2,
                    cardPosition: 2,
                    personalizedPrompt: "Hike to a waterfall!",
                    personalizedChallenge: "Pack a snack for the destination",
                    activityTypeId: 1,
                    estimatedDurationMinutes: 90,
                    wasLogged: true,
                    loggedAt: Date(),
                    createdAt: Date(),
                    activityType: ActivityType(id: 1, name: "Hiking", icon: "figure.hiking")
                ),
                onLog: {}
            )

            ActivityRecommendationCard(
                recommendation: ActivityRecommendation(
                    id: UUID(),
                    userId: UUID(),
                    recommendationDate: Date(),
                    activityTemplateId: 3,
                    cardPosition: 3,
                    personalizedPrompt: "Do outdoor yoga!",
                    personalizedChallenge: "Find a quiet spot",
                    activityTypeId: 11,
                    estimatedDurationMinutes: 30,
                    wasLogged: false,
                    loggedAt: nil,
                    createdAt: Date(),
                    activityType: ActivityType(id: 11, name: "Other", icon: "figure.outdoor.cycle")
                ),
                onLog: {}
            )
        }
        .padding()
    }
    .environmentObject(ThemeManager.shared)
    .background(AppColors().primaryBackground)
}
