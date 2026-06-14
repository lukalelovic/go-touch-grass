//
//  TouchGrassTab.swift
//  Go Touch Grass
//
//  Rewritten on 2026-05-31 for the Touch Grass Tab Overhaul
//  Displays personalized daily activity recommendations
//

import SwiftUI

struct TouchGrassTab: View {
    @StateObject private var viewModel = RecommendationViewModel()
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let colors = AppColors()

        NavigationStack {
            ZStack {
                colors.primaryBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
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
                }
            }
        }
    }

    // MARK: - Preview Text

    @ViewBuilder
    private func previewText(colors: AppColors) -> some View {
        if viewModel.completedCount > 0 {
            Text("Nice work! You've touched grass today!")
                .font(.subheadline)
                .foregroundStyle(colors.accent)
        } else {
            Text("Get outside — you've got \(viewModel.totalCount) activities waiting!")
                .font(.subheadline)
                .foregroundStyle(colors.secondaryText)
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private func headerView(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Activities")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colors.primaryText)

            Text(formattedDate())
                .font(.subheadline)
                .foregroundStyle(colors.secondaryText)

            if viewModel.hasRecommendations {
                previewText(colors: colors)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress View

    @ViewBuilder
    private func progressView(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(colors.primaryText)

                Spacer()

                Text("\(viewModel.completedCount)/\(viewModel.totalCount) completed")
                    .font(.caption)
                    .foregroundStyle(colors.secondaryText)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(colors.secondaryCardBackground)
                        .frame(height: 8)
                        .cornerRadius(4)

                    if viewModel.totalCount > 0 {
                        Rectangle()
                            .fill(colors.accent)
                            .frame(
                                width: geometry.size.width * CGFloat(viewModel.completedCount) / CGFloat(viewModel.totalCount),
                                height: 8
                            )
                            .cornerRadius(4)
                            .animation(.easeInOut, value: viewModel.completedCount)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(colors.cardBackground)
        .cornerRadius(12)
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
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Loading your activities...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(error: String, colors: AppColors) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colors.primaryText)

            Text(error)
                .font(.body)
                .foregroundStyle(colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                Task {
                    await viewModel.loadTodaysRecommendations()
                }
            }) {
                Text("Try Again")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Empty State View

    @ViewBuilder
    private func emptyStateView(colors: AppColors) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 60))
                .foregroundStyle(colors.accent)
                .padding()

            Text("No Activities Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colors.primaryText)

            Text("We're preparing personalized outdoor activity recommendations for you. Check back soon!")
                .font(.body)
                .foregroundStyle(colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                Task {
                    await viewModel.loadTodaysRecommendations()
                }
            }) {
                Text("Refresh")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.top, 40)
    }

    // MARK: - Refresh Button

    @ViewBuilder
    private func refreshButton(colors: AppColors) -> some View {
        VStack(spacing: 8) {
            Button(action: {
                Task {
                    await viewModel.refreshRecommendations()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Get New Activities")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(colors.primaryBackground)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white)
                .cornerRadius(20)
            }
            .disabled(viewModel.isLoading || !viewModel.canRefresh)
            .opacity(viewModel.canRefresh ? 1.0 : 0.5)

            if viewModel.refreshesRemaining > 0 {
                Text("\(viewModel.refreshesRemaining) refreshes remaining today")
                    .font(.caption)
                    .foregroundStyle(colors.secondaryText)
            } else {
                Text("No refreshes remaining today")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helper Methods

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    TouchGrassTab()
        .environmentObject(ThemeManager.shared)
}
