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

    private let activityStore: ActivityStore
    private var cancellables = Set<AnyCancellable>()

    init(activityStore: ActivityStore = .shared) {
        self.activityStore = activityStore
        setupBindings()
    }

    private func setupBindings() {
        // Subscribe to ActivityStore changes
        activityStore.$activities
            .assign(to: &$activities)
    }

    // MARK: - Public Methods

    func loadActivities() {
        // Activities are automatically updated through the binding
        // In the future, this will fetch from Supabase

        // TODO: Fetch activities from Supabase
        // - Call Supabase query for all activities
        // - Sort by timestamp descending
        // - Update activities array
        // activityStore.activities = await supabaseClient
        //     .from("activities")
        //     .select()
        //     .order("timestamp", ascending: false)
    }

    func refreshActivities() async {
        // TODO: Implement pull-to-refresh
        // - Fetch latest activities from Supabase
        // - Update local store
        // - Show loading indicator
    }
}
