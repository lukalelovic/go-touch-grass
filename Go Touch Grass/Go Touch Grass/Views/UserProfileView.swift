//
//  UserProfileView.swift
//  Go Touch Grass
//
//  User profile view that can display any user's profile
//

import SwiftUI
import Auth

struct UserProfileView: View {
    let user: User
    let isCurrentUser: Bool
    @State private var isFollowing: Bool = false
    @State private var hasPendingRequest: Bool = false
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var activities: [Activity] = []
    @State private var isLoading: Bool = false
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        ZStack {
            colors.primaryBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // User Info Card
                    VStack(spacing: 12) {
                        // Profile Picture
                        ProfilePictureView(
                            profilePictureUrl: user.profilePictureUrl,
                            size: 100
                        )

                        Text(user.username)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colors.primaryText)

                        if let email = user.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(colors.secondaryText)
                        }

                        // Follower/Following counts
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text("\(followerCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(colors.primaryText)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(colors.secondaryText)
                            }

                            VStack(spacing: 4) {
                                Text("\(followingCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(colors.primaryText)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(colors.secondaryText)
                            }
                        }

                        // Follow/Unfollow button (only show if not current user)
                        if !isCurrentUser {
                            Button(action: {
                                toggleFollow()
                            }) {
                                HStack {
                                    if hasPendingRequest {
                                        Image(systemName: "clock")
                                        Text("Requested")
                                    } else if isFollowing {
                                        Image(systemName: "person.fill.checkmark")
                                        Text("Following")
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                        Text("Follow")
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isFollowing || hasPendingRequest ? Color.gray : colors.accentDark)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(colors.cardBackground)
                    .cornerRadius(16)

                    // User's Activities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activities")
                            .font(.headline)
                            .foregroundColor(colors.primaryText)

                        // Check if profile is private and user is not following
                        if user.isPrivate && !isFollowing && !isCurrentUser {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(colors.secondaryText)
                                    .padding(.top, 20)

                                Text("This user has a private profile")
                                    .font(.headline)
                                    .foregroundColor(colors.primaryText)

                                Text("Follow to see their activities")
                                    .font(.subheadline)
                                    .foregroundColor(colors.secondaryText)
                                    .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if activities.isEmpty {
                            Text("No activities yet")
                                .font(.subheadline)
                                .foregroundColor(colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(activities) { activity in
                                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                    HStack(spacing: 12) {
                                        if let icon = activity.activityType.icon {
                                            Image(systemName: icon)
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .frame(width: 50, height: 50)
                                                .background(colors.eventCardBackground)
                                                .cornerRadius(10)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(activity.activityType.rawValue)
                                                .font(.headline)
                                                .foregroundColor(colors.primaryText)

                                            if let notes = activity.notes {
                                                Text(notes)
                                                    .font(.caption)
                                                    .foregroundColor(colors.secondaryText)
                                                    .lineLimit(1)
                                            }

                                            Text(formatDate(activity.timestamp))
                                                .font(.caption2)
                                                .foregroundColor(colors.secondaryText)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(colors.secondaryText)
                                    }
                                    .padding()
                                    .background(colors.cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(colors.secondaryCardBackground)
                    .cornerRadius(16)
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserData()
        }
    }

    private func loadUserData() {
        Task {
            isLoading = true

            do {
                // Load follower/following counts
                let followerCount = try await supabaseManager.getFollowerCount(userId: user.id)
                let followingCount = try await supabaseManager.getFollowingCount(userId: user.id)
                self.followerCount = followerCount
                self.followingCount = followingCount

                // Check if current user is following this user
                if !isCurrentUser, let authUser = supabaseManager.currentUser {
                    let isFollowing = try await supabaseManager.isFollowing(
                        followerId: authUser.id,
                        followingId: user.id
                    )
                    self.isFollowing = isFollowing

                    // Check if there's a pending follow request
                    let hasPending = try await supabaseManager.hasPendingFollowRequest(
                        requesterId: authUser.id,
                        requestedId: user.id
                    )
                    self.hasPendingRequest = hasPending
                }

                // Only load activities if:
                // 1. This is the current user's profile, OR
                // 2. The profile is public, OR
                // 3. The profile is private AND the current user is following
                let canViewActivities = isCurrentUser || !user.isPrivate || isFollowing

                if canViewActivities {
                    let activities = try await supabaseManager.fetchUserActivities(userId: user.id, limit: 50)
                    self.activities = activities
                } else {
                    self.activities = []
                }

                isLoading = false
            } catch {
                print("Error loading user data: \(error)")
                isLoading = false

                // Fall back to placeholder data
                followerCount = 0
                followingCount = 0
                activities = []
            }
        }
    }

    private func toggleFollow() {
        Task {
            guard let authUser = supabaseManager.currentUser else {
                print("Error: User not authenticated")
                return
            }

            do {
                isLoading = true

                if isFollowing {
                    // Unfollow - use toggle (which removes the follow)
                    let nowFollowing = try await supabaseManager.toggleFollow(
                        followerId: authUser.id,
                        followingId: user.id
                    )
                    isFollowing = nowFollowing
                    followerCount -= 1

                    // Clear activities if profile is private
                    if user.isPrivate {
                        activities = []
                    }
                } else if hasPendingRequest {
                    // Cancel pending request
                    _ = try await supabaseManager.cancelFollowRequest(
                        requesterId: authUser.id,
                        requestedId: user.id
                    )
                    hasPendingRequest = false
                } else {
                    // Send follow request (or directly follow if public)
                    let result = try await supabaseManager.sendFollowRequest(
                        requesterId: authUser.id,
                        requestedId: user.id
                    )

                    if result.isDirectFollow {
                        // Public account - followed directly
                        isFollowing = true
                        followerCount += 1

                        // Load activities now that we're following
                        let fetchedActivities = try await supabaseManager.fetchUserActivities(userId: user.id, limit: 50)
                        activities = fetchedActivities
                    } else {
                        // Private account - request sent
                        hasPendingRequest = true
                    }

                    print("✅ \(result.message)")
                }

                isLoading = false
            } catch {
                print("Error toggling follow: \(error)")
                isLoading = false
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
