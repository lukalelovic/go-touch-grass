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

    // New badge and level properties
    @Published var userStats: UserStats?
    @Published var levelInfo: UserLevelInfo?
    @Published var badgeProgress: [BadgeProgress] = []
    @Published var unlockedBadges: [BadgeProgress] = []
    @Published var lockedBadges: [BadgeProgress] = []

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

        // Load stats from database
        loadUserStats()

        // Load level info
        loadLevelInfo()

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

    func loadUserStats() {
        // TODO: Query user_stats view from Supabase
        // - SELECT * FROM user_stats WHERE user_id = currentUser.id
        // - Parse JSONB activities_by_type field
        // - Update userStats property
        //
        // For now, use sample data
        // userStats = UserStats.sampleStats
    }

    func loadLevelInfo() {
        // TODO: Query user_current_levels view from Supabase
        // - SELECT * FROM user_current_levels WHERE user_id = currentUser.id
        // - This view calculates current level, milestone info, and progress
        // - Update levelInfo property
        //
        // Example query result includes:
        // - current_level (equals total activities)
        // - current_milestone_level, milestone_name, milestone_icon
        // - next_milestone_level, next_milestone_name
        // - activities_to_next_milestone, progress_to_next_milestone
        //
        // For now, calculate locally from activities
        let totalActivities = userActivities.count
        let currentMilestone = LevelMilestone.milestoneFor(level: totalActivities)
        let nextMilestone = LevelMilestone.nextMilestoneFor(level: totalActivities)

        let activitiesToNext = (nextMilestone?.milestoneLevel ?? 0) - totalActivities
        let progressPercent: Double
        if let current = currentMilestone, let next = nextMilestone {
            let range = Double(next.milestoneLevel - current.milestoneLevel)
            let completed = Double(totalActivities - current.milestoneLevel)
            progressPercent = (completed / range) * 100
        } else if nextMilestone != nil {
            progressPercent = Double(totalActivities) / Double(nextMilestone!.milestoneLevel) * 100
        } else {
            progressPercent = 100
        }

        levelInfo = UserLevelInfo(
            userId: currentUser.id,
            username: currentUser.username,
            totalActivities: totalActivities,
            currentLevel: max(totalActivities, 1),
            currentMilestoneLevel: currentMilestone?.milestoneLevel,
            milestoneName: currentMilestone?.name,
            milestoneDescription: currentMilestone?.description,
            milestoneIcon: currentMilestone?.icon,
            nextMilestoneLevel: nextMilestone?.milestoneLevel,
            nextMilestoneName: nextMilestone?.name,
            nextMilestoneIcon: nextMilestone?.icon,
            activitiesToNextMilestone: max(activitiesToNext, 0),
            progressToNextMilestone: progressPercent
        )
    }

    func loadBadges() {
        // TODO: Query user_badge_progress view from Supabase
        // - SELECT * FROM user_badge_progress WHERE user_id = currentUser.id
        // - This view returns all badges with is_unlocked flag
        // - Update badgeProgress, unlockedBadges, and lockedBadges
        //
        // Example query:
        // let response = await supabase
        //     .from("user_badge_progress")
        //     .select("*")
        //     .eq("user_id", currentUser.id)
        //     .order("is_unlocked", ascending: false)
        //     .order("display_order", ascending: true)
        //
        // For now, use sample data
        let allBadges = Badge.sampleBadges.map { badge in
            // Simple logic: unlock if criteria is met
            let isUnlocked = checkBadgeCriteria(badge)
            return BadgeProgress(
                badge: badge,
                isUnlocked: isUnlocked,
                unlockedAt: isUnlocked ? Date() : nil,
                progress: nil
            )
        }

        badgeProgress = allBadges
        unlockedBadges = allBadges.filter { $0.isUnlocked }
        lockedBadges = allBadges.filter { !$0.isUnlocked }
    }

    private func checkBadgeCriteria(_ badge: Badge) -> Bool {
        // Simple local check - in production, this would come from the database
        switch badge.criteria.type {
        case "total_activities":
            return totalActivities >= (badge.criteria.count ?? 0)
        case "specific_activity":
            // Would need to count activities by type
            return false
        case "likes_received", "likes_given":
            // Would need to query likes
            return false
        default:
            return false
        }
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
