//
//  ProfileViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine
import Auth

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var userActivities: [Activity] = []
    @Published var currentStreak: Int = 0
    @Published var totalActivities: Int = 0

    // Follow counts
    @Published var followerCount: Int = 0
    @Published var followingCount: Int = 0

    // New badge and level properties
    @Published var userStats: UserStats?
    @Published var levelInfo: UserLevelInfo?
    @Published var badgeProgress: [BadgeProgress] = []
    @Published var unlockedBadges: [BadgeProgress] = []
    @Published var lockedBadges: [BadgeProgress] = []

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
        // Subscribe to ActivityStore changes to update user activities
        activityStore.$activities
            .map { [weak self] activities in
                guard let self = self, let currentUser = self.currentUser else { return [] }
                return self.activityStore.getActivitiesForUser(currentUser)
            }
            .assign(to: &$userActivities)

        // Update total activities count when userActivities changes
        $userActivities
            .map { $0.count }
            .assign(to: &$totalActivities)
    }

    // MARK: - Public Methods

    func loadUserProfile() {
        Task {
            await fetchUserProfile()
        }
    }

    private func fetchUserProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get the authenticated user ID from Supabase Auth
            guard let authUser = supabaseManager.currentUser else {
                errorMessage = "Not authenticated"
                isLoading = false
                return
            }

            let userId = authUser.id

            // Fetch the user profile from the users table
            let user = try await supabaseManager.fetchUser(userId: userId)
            currentUser = user

            // Fetch user activities from Supabase
            let activities = try await supabaseManager.fetchUserActivities(
                userId: userId,
                limit: 50
            )
            userActivities = activities
            activityStore.activities = activities

            // Fetch streak
            do {
                let streak = try await supabaseManager.getUserStreak(userId: userId)
                currentStreak = streak
                print("✅ Fetched streak: \(streak)")
            } catch {
                print("❌ Error fetching streak: \(error)")
                throw error
            }

            // Fetch follower/following counts
            let followerCount = try await supabaseManager.getFollowerCount(userId: userId)
            let followingCount = try await supabaseManager.getFollowingCount(userId: userId)
            self.followerCount = followerCount
            self.followingCount = followingCount

            // Fetch level info
            do {
                let levelInfo = try await supabaseManager.getUserLevelInfo(userId: userId)
                self.levelInfo = levelInfo
                print("✅ Fetched level info: Level \(levelInfo.currentLevel)")
            } catch {
                print("❌ Error fetching level info: \(error)")
                throw error
            }

            // Fetch badge progress
            let badgeProgress = try await supabaseManager.getUserBadgeProgress(userId: userId)
            self.badgeProgress = badgeProgress
            self.unlockedBadges = badgeProgress.filter { $0.isUnlocked }
            self.lockedBadges = badgeProgress.filter { !$0.isUnlocked }

            // Fetch user stats
            do {
                let stats = try await supabaseManager.getUserStats(userId: userId)
                self.userStats = stats
                print("✅ Fetched user stats: \(stats.totalActivities) activities")
            } catch {
                print("❌ Error fetching user stats: \(error)")
                throw error
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            isLoading = false
            print("Error loading profile: \(error)")

            // Fall back to local calculations
            loadLocalProfileData()
        }
    }

    private func loadLocalProfileData() {
        // Fall back to local data when Supabase fails
        guard let currentUser = currentUser else { return }
        userActivities = activityStore.getActivitiesForUser(currentUser)
        calculateLocalStreak()
        loadLocalLevelInfo()
        loadLocalBadges()
        followerCount = 0
        followingCount = 0
    }

    func loadFollowCounts() {
        Task {
            guard let currentUser = currentUser else { return }
            do {
                let followerCount = try await supabaseManager.getFollowerCount(userId: currentUser.id)
                let followingCount = try await supabaseManager.getFollowingCount(userId: currentUser.id)
                self.followerCount = followerCount
                self.followingCount = followingCount
            } catch {
                print("Error loading follow counts: \(error)")
                followerCount = 0
                followingCount = 0
            }
        }
    }

    private func calculateLocalStreak() {
        // Local streak calculation as fallback
        currentStreak = 3
    }

    private func loadLocalLevelInfo() {
        // For now, calculate locally from activities
        guard let currentUser = currentUser else { return }

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

    private func loadLocalBadges() {
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
