//
//  SupabaseManager.swift
//  Go Touch Grass
//
//  Supabase client manager singleton
//

import Foundation
import Combine
import Supabase

class SupabaseManager: ObservableObject {
    @MainActor static let shared = SupabaseManager()

    let client: SupabaseClient

    @MainActor @Published var isAuthenticated = false
    @MainActor @Published var currentUser: Auth.User?

    @MainActor private init() {
        // Initialize Supabase client with credentials from SupabaseConfig
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )

        // Set up auth state listener
        Task {
            await setupAuthListener()
        }
    }

    // MARK: - Auth State Listener

    @MainActor private func setupAuthListener() async {
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .signedIn:
                if let session = session {
                    self.isAuthenticated = true
                    self.currentUser = session.user
                    print("User signed in: \(session.user.id)")
                }
            case .signedOut:
                self.isAuthenticated = false
                self.currentUser = nil
                print("User signed out")
            case .initialSession:
                if let session = session {
                    self.isAuthenticated = true
                    self.currentUser = session.user
                    print("Initial session found: \(session.user.id)")
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    print("No initial session")
                }
            case .userUpdated:
                if let session = session {
                    self.currentUser = session.user
                    print("User updated: \(session.user.id)")
                }
            case .tokenRefreshed:
                if let session = session {
                    self.currentUser = session.user
                    print("Token refreshed for user: \(session.user.id)")
                }
            default:
                break
            }
        }
    }

    // MARK: - Auth Methods (Placeholders for future implementation)

    // These methods will be implemented when you're ready to add auth logic to your views

    @MainActor func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        print("Signed in user: \(session.user.id)")
    }

    @MainActor func signUpWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)
        print("Signed up user: \(session.user.id)")
    }

    @MainActor func signOut() async throws {
        try await client.auth.signOut()
        print("User signed out")
    }

    @MainActor func signInWithApple() async throws {
        // Apple Sign-In implementation will go here
        // This requires additional setup with Sign in with Apple
        throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In not yet implemented"])
    }

    // MARK: - Activity Methods

    /// Fetch activities from followed users (feed)
    /// Shows activities from users that the current user follows, plus their own activities
    @MainActor func fetchFeedActivities(for userId: UUID, limit: Int = 50) async throws -> [Activity] {
        // First, get the list of users that this user follows
        let followsResponse = try await client
            .from("user_follows")
            .select("following_id")
            .eq("follower_id", value: userId.uuidString)
            .execute()

        let followsData = try JSONSerialization.jsonObject(with: followsResponse.data) as? [[String: Any]] ?? []
        var followingIds = followsData.compactMap { $0["following_id"] as? String }

        // Always include the user's own activities in their feed
        followingIds.append(userId.uuidString)

        // Fetch activities from followed users + self
        let response = try await client
            .from("activities_with_stats")
            .select()
            .in("user_id", values: followingIds)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activities = try decoder.decode([Activity].self, from: response.data)
        return activities
    }

    /// Fetch activities for a specific user (profile view)
    @MainActor func fetchUserActivities(userId: UUID, limit: Int = 50) async throws -> [Activity] {
        let response = try await client
            .from("activities_with_stats")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activities = try decoder.decode([Activity].self, from: response.data)
        return activities
    }

    /// Create a new activity
    @MainActor func createActivity(
        userId: UUID,
        activityType: ActivityType,
        notes: String?,
        location: Location?,
        timestamp: Date = Date()
    ) async throws -> Activity {
        // Get the activity type ID from the database
        let activityTypeResponse = try await client
            .from("activity_types")
            .select("id")
            .eq("name", value: activityType.rawValue)
            .single()
            .execute()

        let activityTypeData = try JSONSerialization.jsonObject(with: activityTypeResponse.data) as? [String: Any]
        guard let activityTypeId = activityTypeData?["id"] as? Int else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Activity type not found"])
        }

        // Prepare activity data
        var activityData: [String: Any] = [
            "user_id": userId.uuidString,
            "activity_type_id": activityTypeId,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]

        if let notes = notes, !notes.isEmpty {
            activityData["notes"] = notes
        }

        if let location = location {
            activityData["location_latitude"] = location.latitude
            activityData["location_longitude"] = location.longitude
            if let locationName = location.name {
                activityData["location_name"] = locationName
            }
        }

        // Insert activity
        let insertData = try JSONSerialization.data(withJSONObject: activityData)
        let insertResponse = try await client
            .from("activities")
            .insert(insertData)
            .select()
            .single()
            .execute()

        // Fetch the full activity with stats
        let activityId = try JSONDecoder().decode([String: String].self, from: insertResponse.data)["id"]
        guard let id = activityId, let uuid = UUID(uuidString: id) else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get activity ID"])
        }

        let activityResponse = try await client
            .from("activities_with_stats")
            .select()
            .eq("id", value: uuid.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activity = try decoder.decode(Activity.self, from: activityResponse.data)

        // Check and award badges
        try? await checkAndAwardBadges(userId: userId)

        return activity
    }

    /// Delete an activity
    @MainActor func deleteActivity(activityId: UUID) async throws {
        try await client
            .from("activities")
            .delete()
            .eq("id", value: activityId.uuidString)
            .execute()
    }

    /// Get today's activity count for a user
    @MainActor func getTodayActivityCount(userId: UUID) async throws -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let response = try await client
            .from("activities")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .gte("timestamp", value: ISO8601DateFormatter().string(from: startOfDay))
            .lt("timestamp", value: ISO8601DateFormatter().string(from: endOfDay))
            .execute()

        return response.count ?? 0
    }

    // MARK: - User Methods

    /// Fetch user by ID
    @MainActor func fetchUser(userId: UUID) async throws -> User {
        let response = try await client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let user = try decoder.decode(User.self, from: response.data)
        return user
    }

    /// Search users by username (case-insensitive)
    @MainActor func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
        let response = try await client
            .from("users")
            .select()
            .ilike("username", pattern: "%\(query)%")
            .order("username")
            .limit(limit)
            .execute()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let users = try decoder.decode([User].self, from: response.data)
        return users
    }

    // MARK: - Follow Methods

    /// Toggle follow/unfollow a user
    @MainActor func toggleFollow(followerId: UUID, followingId: UUID) async throws -> Bool {
        let response = try await client.rpc(
            "toggle_user_follow",
            params: [
                "p_follower_id": followerId.uuidString,
                "p_following_id": followingId.uuidString
            ]
        ).execute()

        let result = try JSONDecoder().decode(Bool.self, from: response.data)
        return result
    }

    /// Check if user is following another user
    @MainActor func isFollowing(followerId: UUID, followingId: UUID) async throws -> Bool {
        let response = try await client.rpc(
            "is_following",
            params: [
                "p_follower_id": followerId.uuidString,
                "p_following_id": followingId.uuidString
            ]
        ).execute()

        let result = try JSONDecoder().decode(Bool.self, from: response.data)
        return result
    }

    /// Get follower count for a user
    @MainActor func getFollowerCount(userId: UUID) async throws -> Int {
        let response = try await client.rpc(
            "get_follower_count",
            params: ["p_user_id": userId.uuidString]
        ).execute()

        let result = try JSONDecoder().decode(Int.self, from: response.data)
        return result
    }

    /// Get following count for a user
    @MainActor func getFollowingCount(userId: UUID) async throws -> Int {
        let response = try await client.rpc(
            "get_following_count",
            params: ["p_user_id": userId.uuidString]
        ).execute()

        let result = try JSONDecoder().decode(Int.self, from: response.data)
        return result
    }

    // MARK: - Like Methods

    /// Toggle like on an activity
    @MainActor func toggleLike(activityId: UUID, userId: UUID) async throws -> Bool {
        let response = try await client.rpc(
            "toggle_activity_like",
            params: [
                "p_activity_id": activityId.uuidString,
                "p_user_id": userId.uuidString
            ]
        ).execute()

        let result = try JSONDecoder().decode(Bool.self, from: response.data)
        return result
    }

    /// Check if user has liked an activity
    @MainActor func hasLiked(activityId: UUID, userId: UUID) async throws -> Bool {
        let response = try await client.rpc(
            "has_user_liked_activity",
            params: [
                "p_activity_id": activityId.uuidString,
                "p_user_id": userId.uuidString
            ]
        ).execute()

        let result = try JSONDecoder().decode(Bool.self, from: response.data)
        return result
    }

    // MARK: - Stats and Badges Methods

    /// Get user stats
    @MainActor func getUserStats(userId: UUID) async throws -> UserStats {
        let response = try await client
            .from("user_stats")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let stats = try decoder.decode(UserStats.self, from: response.data)
        return stats
    }

    /// Get user level info
    @MainActor func getUserLevelInfo(userId: UUID) async throws -> UserLevelInfo {
        let response = try await client
            .from("user_current_levels")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let levelInfo = try decoder.decode(UserLevelInfo.self, from: response.data)
        return levelInfo
    }

    /// Get user badge progress
    @MainActor func getUserBadgeProgress(userId: UUID) async throws -> [BadgeProgress] {
        let response = try await client
            .from("user_badge_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("is_unlocked", ascending: false)
            .order("display_order")
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Decode the response as a custom structure that matches the view
        struct BadgeProgressResponse: Codable {
            let userId: UUID
            let username: String
            let badgeId: Int
            let badgeName: String
            let badgeDescription: String
            let category: BadgeCategory
            let icon: String?
            let rarity: BadgeRarity
            let criteria: BadgeCriteria
            let unlockedAt: Date?
            let isUnlocked: Bool
            let progress: [String: Int]?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case username
                case badgeId = "badge_id"
                case badgeName = "badge_name"
                case badgeDescription = "badge_description"
                case category
                case icon
                case rarity
                case criteria
                case unlockedAt = "unlocked_at"
                case isUnlocked = "is_unlocked"
                case progress
            }
        }

        let responses = try decoder.decode([BadgeProgressResponse].self, from: response.data)

        // Convert to BadgeProgress objects
        return responses.map { resp in
            let badge = Badge(
                id: resp.badgeId,
                name: resp.badgeName,
                description: resp.badgeDescription,
                category: resp.category,
                icon: resp.icon,
                criteria: resp.criteria,
                displayOrder: 0, // Not returned from view
                rarity: resp.rarity,
                createdAt: Date() // Not returned from view
            )

            return BadgeProgress(
                badge: badge,
                isUnlocked: resp.isUnlocked,
                unlockedAt: resp.unlockedAt,
                progress: resp.progress
            )
        }
    }

    /// Get user streak
    @MainActor func getUserStreak(userId: UUID) async throws -> Int {
        let response = try await client.rpc(
            "get_user_streak",
            params: ["p_user_id": userId.uuidString]
        ).execute()

        let result = try JSONDecoder().decode(Int.self, from: response.data)
        return result
    }

    /// Check and award badges to a user
    @MainActor func checkAndAwardBadges(userId: UUID) async throws {
        _ = try await client.rpc(
            "check_and_award_badges",
            params: ["p_user_id": userId.uuidString]
        ).execute()
    }
}
