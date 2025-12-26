//
//  ProfileViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var currentUser: User = User.sampleUsers[0]
    @Published var userActivities: [Activity] = []
    @Published var currentStreak: Int = 0
    @Published var totalActivities: Int = 0
    @Published var badges: [String] = []

    private let activityStore: ActivityStore
    private var cancellables = Set<AnyCancellable>()

    init(activityStore: ActivityStore = .shared) {
        self.activityStore = activityStore
        setupBindings()
    }

    private func setupBindings() {
        // Subscribe to ActivityStore changes to update user activities
        activityStore.$activities
            .map { [weak self] activities in
                guard let self = self else { return [] }
                return self.activityStore.getActivitiesForUser(self.currentUser)
            }
            .assign(to: &$userActivities)

        // Update total activities count when userActivities changes
        $userActivities
            .map { $0.count }
            .assign(to: &$totalActivities)
    }

    // MARK: - Public Methods

    func loadUserProfile() {
        // TODO: Fetch current user from Supabase Auth
        // - Get authenticated user session
        // - Load user profile data
        // currentUser = await supabaseClient.auth.session?.user

        // Load activities from store (already updated through binding)
        userActivities = activityStore.getActivitiesForUser(currentUser)

        // Calculate streak
        calculateStreak()

        // Load badges
        loadBadges()
    }

    func calculateStreak() {
        // TODO: Calculate actual streak
        // - Query activities grouped by date
        // - Count consecutive days with activities
        // - Update currentStreak
        //
        // let sortedActivities = userActivities.sorted { $0.timestamp > $1.timestamp }
        // var streak = 0
        // var currentDate = Date()
        // for activity in sortedActivities {
        //     if Calendar.current.isDate(activity.timestamp, inSameDayAs: currentDate) {
        //         if streak == 0 { streak = 1 }
        //     } else if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
        //               Calendar.current.isDate(activity.timestamp, inSameDayAs: previousDay) {
        //         streak += 1
        //         currentDate = previousDay
        //     } else {
        //         break
        //     }
        // }
        // currentStreak = streak

        // Placeholder value
        currentStreak = 3
    }

    func loadBadges() {
        // TODO: Fetch earned badges
        // - Query user_badges table from Supabase
        // - Or calculate based on achievements
        // - Update badges array
        //
        // Example achievements:
        // - First activity: "Grass Toucher"
        // - 10 activities: "Nature Explorer"
        // - 7 day streak: "Committed"
        // - Try all activity types: "Versatile"

        badges = []
    }

    func logout() {
        // TODO: Implement logout
        // - Call Supabase auth signOut
        // - Clear local user data
        // - Navigate to login screen
        // await supabaseClient.auth.signOut()
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
