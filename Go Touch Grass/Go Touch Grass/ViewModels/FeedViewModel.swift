//
//  FeedViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine
import Auth

@MainActor
class FeedViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let activityStore: ActivityStore
    private var supabaseManager: SupabaseManager
    private var cancellables = Set<AnyCancellable>()

    init(activityStore: ActivityStore = .shared, supabaseManager: SupabaseManager? = nil) {
        self.activityStore = activityStore
        self.supabaseManager = supabaseManager ?? SupabaseManager()
        setupBindings()
    }

    func updateSupabaseManager(_ manager: SupabaseManager) {
        self.supabaseManager = manager
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

        // Get the authenticated user
        guard let authUser = supabaseManager.currentUser else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }

        do {
            let userId = authUser.id

            // Fetch activities from Supabase (feed shows user's own activities and followed users)
            let fetchedActivities = try await supabaseManager.fetchFeedActivities(
                for: userId,
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

            // Fall back to local/sample data
            activities = activityStore.activities
        }
    }
}
