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
    

    let client: SupabaseClient

    var isAuthenticated = false {
        willSet {
            print("🔄 isAuthenticated will change to: \(newValue)")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        didSet {
            print("🔄 isAuthenticated did change to: \(isAuthenticated)")
        }
    }

    var currentUser: Auth.User? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    init() {
        // Initialize Supabase client with credentials from SupabaseConfig
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )

        print("🚀 SupabaseManager initialized")

        // Set up auth state listener
        Task {
            await setupAuthListener()
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthListener() async {
        for await (event, session) in client.auth.authStateChanges {
            await MainActor.run {
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
    }

    // MARK: - Auth Methods

    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        await MainActor.run {
            self.objectWillChange.send()
            self.isAuthenticated = true
            self.currentUser = session.user
            print("✅ Signed in user: \(session.user.id)")
            print("✅ isAuthenticated is now: \(self.isAuthenticated)")
        }
    }

    func signUpWithEmail(email: String, password: String, username: String) async throws {
        // Sign up the user with Supabase Auth
        let session = try await client.auth.signUp(email: email, password: password)
        let userId = session.user.id
        print("Signed up user: \(userId)")

        // Create user record in the users table
        // The user's auth.uid() will be the same as their users.id
        struct UserInsert: Codable {
            let id: String
            let username: String
            let email: String
        }

        let userData = UserInsert(
            id: userId.uuidString,
            username: username,
            email: email
        )

        do {
            // Insert and request the created record back
            let response = try await client
                .from("users")
                .insert(userData)
                .select()
                .single()
                .execute()

            print("Created user record for: \(username)")
            print("Response data: \(String(data: response.data, encoding: .utf8) ?? "none")")

            // Update auth state
            objectWillChange.send()
            self.isAuthenticated = true
            self.currentUser = session.user
            print("✅ Signup complete - isAuthenticated: \(self.isAuthenticated)")
        } catch {
            print("Error creating user record: \(error)")
            throw error
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
        print("User signed out")
    }

    func signInWithApple() async throws {
        // Apple Sign-In implementation will go here
        // This requires additional setup with Sign in with Apple
        throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In not yet implemented"])
    }

    // MARK: - Activity Methods

    /// Fetch activities from followed users (feed)
    /// Shows activities from users that the current user follows, plus their own activities
    func fetchFeedActivities(for userId: UUID, limit: Int = 50) async throws -> [Activity] {
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
    func fetchUserActivities(userId: UUID, limit: Int = 50) async throws -> [Activity] {
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
    func createActivity(
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

        // Insert activity using Codable struct
        struct ActivityInsert: Codable {
            let userId: String
            let activityTypeId: Int
            let timestamp: String
            let notes: String?
            let locationLatitude: Double?
            let locationLongitude: Double?
            let locationName: String?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case activityTypeId = "activity_type_id"
                case timestamp
                case notes
                case locationLatitude = "location_latitude"
                case locationLongitude = "location_longitude"
                case locationName = "location_name"
            }
        }

        struct ActivityInsertResponse: Codable {
            let id: String
        }

        let activityInsert = ActivityInsert(
            userId: userId.uuidString,
            activityTypeId: activityTypeId,
            timestamp: ISO8601DateFormatter().string(from: timestamp),
            notes: notes,
            locationLatitude: location?.latitude,
            locationLongitude: location?.longitude,
            locationName: location?.name
        )

        let insertResponse = try await client
            .from("activities")
            .insert(activityInsert)
            .select()
            .single()
            .execute()

        // Decode the response to get the activity ID
        let insertedActivity = try JSONDecoder().decode(ActivityInsertResponse.self, from: insertResponse.data)
        guard let uuid = UUID(uuidString: insertedActivity.id) else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse activity ID"])
        }

        // Fetch the full activity with stats
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
    func deleteActivity(activityId: UUID) async throws {
        try await client
            .from("activities")
            .delete()
            .eq("id", value: activityId.uuidString)
            .execute()
    }

    /// Get today's activity count for a user
    func getTodayActivityCount(userId: UUID) async throws -> Int {
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
    func fetchUser(userId: UUID) async throws -> User {
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
    func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
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
    func toggleFollow(followerId: UUID, followingId: UUID) async throws -> Bool {
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
    func isFollowing(followerId: UUID, followingId: UUID) async throws -> Bool {
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
    func getFollowerCount(userId: UUID) async throws -> Int {
        let response = try await client.rpc(
            "get_follower_count",
            params: ["p_user_id": userId.uuidString]
        ).execute()

        let result = try JSONDecoder().decode(Int.self, from: response.data)
        return result
    }

    /// Get following count for a user
    func getFollowingCount(userId: UUID) async throws -> Int {
        let response = try await client.rpc(
            "get_following_count",
            params: ["p_user_id": userId.uuidString]
        ).execute()

        let result = try JSONDecoder().decode(Int.self, from: response.data)
        return result
    }

    // MARK: - Like Methods

    /// Toggle like on an activity
    func toggleLike(activityId: UUID, userId: UUID) async throws -> Bool {
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
    func hasLiked(activityId: UUID, userId: UUID) async throws -> Bool {
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
    func getUserStats(userId: UUID) async throws -> UserStats {
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
    func getUserLevelInfo(userId: UUID) async throws -> UserLevelInfo {
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
    func getUserBadgeProgress(userId: UUID) async throws -> [BadgeProgress] {
        let response = try await client
            .from("user_badge_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("is_unlocked", ascending: false)
            .order("badge_id")
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
    func getUserStreak(userId: UUID) async throws -> Int {
        let response = try await client.rpc(
            "get_user_streak",
            params: ["p_user_id": userId.uuidString]
        ).execute()

        let result = try JSONDecoder().decode(Int.self, from: response.data)
        return result
    }

    /// Check and award badges to a user
    func checkAndAwardBadges(userId: UUID) async throws {
        _ = try await client.rpc(
            "check_and_award_badges",
            params: ["p_user_id": userId.uuidString]
        ).execute()
    }

    // MARK: - Settings & Account Management

    /// Update username
    func updateUsername(userId: UUID, newUsername: String) async throws {
        struct UsernameUpdate: Codable {
            let username: String
        }

        let update = UsernameUpdate(username: newUsername)

        _ = try await client
            .from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    /// Update profile picture URL
    func updateProfilePicture(userId: UUID, pictureUrl: String?) async throws {
        struct ProfilePictureUpdate: Codable {
            let profilePictureUrl: String?

            enum CodingKeys: String, CodingKey {
                case profilePictureUrl = "profile_picture_url"
            }
        }

        let update = ProfilePictureUpdate(profilePictureUrl: pictureUrl)

        _ = try await client
            .from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    /// Delete profile picture from storage
    func deleteProfilePicture(url: String) async throws {
        // Extract the file path from the URL
        // URL format: https://...supabase.co/storage/v1/object/public/avatars/user_id/filename.jpg
        guard let urlComponents = URLComponents(string: url),
              let pathComponents = urlComponents.path.components(separatedBy: "/avatars/").last else {
            return
        }

        try await client.storage
            .from("avatars")
            .remove(paths: [pathComponents])
    }

    /// Delete user account and all related data
    func deleteUserAccount(userId: UUID) async throws {
        // Delete user (should cascade to all related tables via foreign keys)
        _ = try await client
            .from("users")
            .delete()
            .eq("id", value: userId.uuidString)
            .execute()

        // Sign out from auth
        try await client.auth.signOut()
    }
}
