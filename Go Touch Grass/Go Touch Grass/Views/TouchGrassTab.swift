//
//  TouchGrassTab.swift
//  Go Touch Grass
//
//  Rewritten on 2026-05-31 for the Touch Grass Tab Overhaul
//  Displays personalized daily activity recommendations
//

import SwiftUI
import WidgetKit

struct TouchGrassTab: View {
    @StateObject private var viewModel = RecommendationViewModel()
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let colors = AppColors()

        NavigationStack {
            ZStack {
                // Nature background
                NatureBackgroundView()

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        // Header with enhanced typography
                        headerView(colors: colors)

                        // Progress indicator
                        if viewModel.hasRecommendations {
                            progressView(colors: colors)
                        }

                        // Daily activity card (1 per day)
                        if viewModel.isLoading {
                            loadingView()
                        } else if let error = viewModel.errorMessage {
                            errorView(error: error, colors: colors)
                        } else if viewModel.hasRecommendations {
                            recommendationCardsView()
                        } else {
                            emptyStateView(colors: colors)
                        }

                        // Refresh button
                        if viewModel.hasRecommendations && viewModel.canRefresh {
                            refreshButton(colors: colors)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.loadTodaysRecommendations()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadTodaysRecommendations()

                    // Get first recommendation for widget and Live Activity
                    if let firstRec = viewModel.todaysRecommendations.first {
                        // Update widget data in shared storage
                        updateWidgetData(recommendation: firstRec)

                        // Start Live Activity if not completed
                        if !firstRec.wasLogged {
                            await LiveActivityManager.shared.startLiveActivity(
                                recommendationId: firstRec.id.uuidString,
                                activityType: firstRec.activityType?.name ?? "Activity",
                                prompt: firstRec.personalizedPrompt,
                                icon: firstRec.activityType?.icon ?? "leaf.fill",
                                duration: firstRec.estimatedDurationMinutes
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preview Text

    @ViewBuilder
    private func previewText(colors: AppColors) -> some View {
        HStack(spacing: AppSpacing.xxxs) {
            if viewModel.completedCount > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.grassCaption)
                    .foregroundStyle(colors.accent)
                Text("Nice work! You've touched grass today!")
                    .font(.grassSubheadline)
                    .foregroundStyle(colors.accent)
            } else {
                Image(systemName: "leaf.fill")
                    .font(.grassCaption)
                    .foregroundStyle(colors.secondaryText)
                Text("Get outside — you've got \(viewModel.totalCount) activities waiting!")
                    .font(.grassSubheadline)
                    .foregroundStyle(colors.secondaryText)
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private func headerView(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("Today's Activities")
                .font(.grassTitle)
                .foregroundStyle(colors.primaryText)

            Text(formattedDate())
                .font(.grassSubheadline)
                .foregroundStyle(colors.secondaryText)

            if viewModel.hasRecommendations {
                previewText(colors: colors)
                    .padding(.top, AppSpacing.xxxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress View

    @ViewBuilder
    private func progressView(colors: AppColors) -> some View {
        GlassCard(isInteractive: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack {
                    Text("Progress")
                        .font(.grassHeadline)
                        .foregroundStyle(colors.primaryText)

                    Spacer()

                    Text("\(viewModel.completedCount)/\(viewModel.totalCount) completed")
                        .font(.grassCaption)
                        .foregroundStyle(colors.secondaryText)
                }

                // Enhanced progress bar with gradient
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colors.secondaryCardBackground)
                            .frame(height: 10)

                        if viewModel.totalCount > 0 {
                            Capsule()
                                .fill(colors.accentGradient)
                                .frame(
                                    width: geometry.size.width * CGFloat(viewModel.completedCount) / CGFloat(viewModel.totalCount),
                                    height: 10
                                )
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: viewModel.completedCount)
                            
                            // Glow effect when progress is high
                            if Double(viewModel.completedCount) / Double(viewModel.totalCount) > 0.5 {
                                Capsule()
                                    .fill(colors.accentGlow)
                                    .frame(
                                        width: geometry.size.width * CGFloat(viewModel.completedCount) / CGFloat(viewModel.totalCount),
                                        height: 10
                                    )
                                    .blur(radius: 4)
                            }
                        }
                    }
                }
                .frame(height: 10)
            }
        }
    }

    // MARK: - Recommendation Cards

    @ViewBuilder
    private func recommendationCardsView() -> some View {
        ForEach(viewModel.todaysRecommendations) { recommendation in
            ActivityRecommendationCard(
                recommendation: recommendation,
                onLog: {
                    viewModel.logActivity(recommendation)
                }
            )
        }
    }

    // MARK: - Loading View

    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: AppSpacing.sm) {
            SkeletonCard()
            SkeletonCard()
            SkeletonCard()
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(error: String, colors: AppColors) -> some View {
        GlassCard {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Oops!")
                    .font(.grassTitle2)
                    .foregroundStyle(colors.primaryText)

                Text(error)
                    .font(.grassBody)
                    .foregroundStyle(colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                AnimatedButton("Try Again", icon: "arrow.clockwise", hierarchy: .primary) {
                    Task {
                        await viewModel.loadTodaysRecommendations()
                    }
                }
                .padding(.top, AppSpacing.xxs)
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: - Empty State View

    @ViewBuilder
    private func emptyStateView(colors: AppColors) -> some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(colors.sunshine)
                    .shadow(color: colors.sunshine.opacity(0.3), radius: 8, x: 0, y: 4)

                Text("No Activities Yet")
                    .font(.grassTitle2)
                    .foregroundStyle(colors.primaryText)

                Text("We're preparing personalized outdoor activity recommendations for you. Check back soon!")
                    .font(.grassBody)
                    .foregroundStyle(colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)

                AnimatedButton("Refresh", icon: "arrow.clockwise", hierarchy: .primary) {
                    Task {
                        await viewModel.loadTodaysRecommendations()
                    }
                }
                .padding(.top, AppSpacing.xxs)
            }
            .padding(.vertical, AppSpacing.md)
        }
    }

    // MARK: - Refresh Button

    @ViewBuilder
    private func refreshButton(colors: AppColors) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            AnimatedButton(
                "Get New Activities",
                icon: "arrow.clockwise",
                hierarchy: .secondary
            ) {
                Task {
                    await viewModel.refreshRecommendations()
                }
            }
            .disabled(viewModel.isLoading || !viewModel.canRefresh)
            .opacity(viewModel.canRefresh ? 1.0 : 0.5)

            if viewModel.refreshesRemaining > 0 {
                Text("\(viewModel.refreshesRemaining) refreshes remaining today")
                    .font(.grassCaption)
                    .foregroundStyle(colors.secondaryText)
            } else {
                Text("No refreshes remaining today")
                    .font(.grassCaption)
                    .foregroundStyle(colors.softRed)
            }
        }
    }

    // MARK: - Helper Methods

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func updateWidgetData(recommendation: ActivityRecommendation) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.touchgrass.app") else {
            print("❌ Failed to access App Group shared storage")
            return
        }

        // Write today's recommendation data for the widget
        sharedDefaults.set(recommendation.activityType?.name ?? "Activity", forKey: "todayActivityType")
        sharedDefaults.set(recommendation.personalizedPrompt, forKey: "todayPrompt")
        sharedDefaults.set(recommendation.activityType?.icon ?? "leaf.fill", forKey: "todayIcon")
        sharedDefaults.set(recommendation.estimatedDurationMinutes ?? 0, forKey: "todayDuration")
        sharedDefaults.set(recommendation.wasLogged, forKey: "todayCompleted")

        if recommendation.wasLogged {
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "todayCompletedAt")
        } else {
            sharedDefaults.set(0, forKey: "todayCompletedAt")
        }

        print("✅ Updated widget data: \(recommendation.activityType?.name ?? "Activity")")

        // Tell WidgetKit to reload the widget timeline
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Preview

#Preview {
    TouchGrassTab()
        .environmentObject(ThemeManager.shared)
}
