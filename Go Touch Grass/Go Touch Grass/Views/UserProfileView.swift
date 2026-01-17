//
//  UserProfileView.swift
//  Go Touch Grass
//
//  User profile view that can display any user's profile
//

import SwiftUI

struct UserProfileView: View {
    let user: User
    let isCurrentUser: Bool
    @State private var isFollowing: Bool = false
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var activities: [Activity] = []
    @EnvironmentObject var themeManager: ThemeManager

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
                                // TODO: Toggle follow status via SupabaseManager
                                isFollowing.toggle()
                                followerCount += isFollowing ? 1 : -1
                            }) {
                                HStack {
                                    Image(systemName: isFollowing ? "person.fill.checkmark" : "person.badge.plus")
                                    Text(isFollowing ? "Following" : "Follow")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isFollowing ? Color.gray : colors.accentDark)
                                .cornerRadius(12)
                            }
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

                        if activities.isEmpty {
                            Text("No activities yet")
                                .font(.subheadline)
                                .foregroundColor(colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(activities) { activity in
                                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: activity.activityType.icon)
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(colors.eventCardBackground)
                                            .cornerRadius(10)

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
        // TODO: Load user's follower/following counts and activities from Supabase
        // For now, using placeholder data
        followerCount = 0
        followingCount = 0
        activities = []
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
