//
//  FeedViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let activityStore: ActivityStore
    private let supabaseManager: SupabaseManager
    private var cancellables = Set<AnyCancellable>()
    // TODO: Replace with actual current user from Supabase Auth when auth is implemented
    // Using real user from database for now
    private let currentUser = User(
        id: UUID(uuidString: "28eb3c73-4815-4d69-a0ba-0c0ae84d1764")!,
        username: "outdoor_enthusiast",
        email: nil,
        profilePictureUrl: nil,
        createdAt: nil,
        updatedAt: nil
    )

    init(activityStore: ActivityStore = .shared, supabaseManager: SupabaseManager = .shared) {
        self.activityStore = activityStore
        self.supabaseManager = supabaseManager
        setupBindings()
    }

    private func setupBindings() {
        // Subscribe to ActivityStore changes for local updates
        activityStore.$activities
            .assign(to: &$activities)
    }

    // MARK: - Public Methods

    func loadActivities() {
        Task {
            await fetchActivities()
        }
    }

    func refreshActivities() async {
        await fetchActivities()
    }

    private func fetchActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch activities from Supabase (feed shows user's own activities for now)
            // TODO: Update to fetch from followed users once auth is implemented
            let fetchedActivities = try await supabaseManager.fetchFeedActivities(
                for: currentUser.id,
                limit: 50
            )

            // Update activities
            activities = fetchedActivities

            // Also update activity store
            activityStore.activities = fetchedActivities

            isLoading = false
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
            isLoading = false
            print("❌ Error loading activities from Supabase: \(error)")
            print("ℹ️ Current user ID being used: \(currentUser.id)")
            print("⚠️ Falling back to sample data. To fix: use a real user ID from your database")

            // Fall back to local/sample data
            activities = activityStore.activities
        }
    }
}
