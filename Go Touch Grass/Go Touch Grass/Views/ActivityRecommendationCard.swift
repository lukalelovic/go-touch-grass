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
    
    @State private var isPressed = false

    var body: some View {
        let colors = AppColors()
        
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Activity type header
            HStack(spacing: AppSpacing.xxs) {
                if let activityType = recommendation.activityType,
                   let icon = activityType.icon {
                    Image(systemName: icon)
                        .font(.grassCaption)
                        .foregroundStyle(colors.accent)
                }

                Text(recommendation.activityType?.name ?? "Activity")
                    .font(.grassCaption)
                    .foregroundStyle(colors.secondaryText)
                    .textCase(.uppercase)

                Spacer()

                // Logged badge with glow
                if recommendation.wasLogged {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.grassCaption)
                        Text("Done")
                            .font(.grassCaption)
                    }
                    .foregroundStyle(colors.accent)
                    .padding(.horizontal, AppSpacing.xxs)
                    .padding(.vertical, AppSpacing.xxxs)
                    .background(
                        Capsule()
                            .fill(colors.accentGlow)
                    )
                }
            }

            // Activity prompt with enhanced typography
            Text(recommendation.personalizedPrompt)
                .font(.grassTitle3)
                .foregroundStyle(colors.primaryText)
                .lineLimit(3)
                .padding(.vertical, AppSpacing.xxxs)

            // Challenge with better styling
            if let challenge = recommendation.personalizedChallenge {
                HStack(spacing: AppSpacing.xxxs) {
                    Image(systemName: "target")
                        .font(.grassCaption)
                        .foregroundStyle(colors.accent)
                    
                    Text(challenge)
                        .font(.grassBody)
                        .foregroundStyle(colors.secondaryText)
                        .lineLimit(2)
                }
            }

            Divider()
                .background(colors.divider)
                .padding(.vertical, AppSpacing.xxxs)

            // Duration and action button
            HStack {
                // Duration badge with icon
                if let duration = recommendation.estimatedDurationMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.grassCaption)
                        Text("\(duration) min")
                            .font(.grassCaption)
                    }
                    .foregroundStyle(colors.tertiaryText)
                    .padding(.horizontal, AppSpacing.xxs)
                    .padding(.vertical, AppSpacing.xxxs)
                    .background(
                        Capsule()
                            .fill(colors.glassOverlay)
                    )
                }

                Spacer()

                // Enhanced button with animation
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()

                    // Mark Live Activity as complete
                    Task {
                        await LiveActivityManager.shared.markActivityCompleted()
                    }

                    onLog()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: recommendation.wasLogged ? "checkmark.circle.fill" : "leaf.fill")
                            .font(.grassBodyEmphasized)
                        Text(recommendation.wasLogged ? "Completed" : "Touch Grass")
                            .font(.grassBodyEmphasized)
                    }
                    .foregroundColor(recommendation.wasLogged ? colors.tertiaryText : colors.primaryText)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background {
                        if recommendation.wasLogged {
                            Capsule()
                                .fill(colors.divider)
                        } else {
                            Capsule()
                                .fill(colors.accentGradient)
                        }
                    }
                }
                .disabled(recommendation.wasLogged)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
            }
        }
        .padding(AppSpacing.sm)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(colors.cardGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(colors.glassOverlay)
                }
                .overlay {
                    if recommendation.wasLogged {
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(colors.accent.opacity(0.3), lineWidth: 1)
                    }
                }
                .shadow(
                    color: AppShadow.md.color,
                    radius: AppShadow.md.radius,
                    x: AppShadow.md.x,
                    y: AppShadow.md.y
                )
        }
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
