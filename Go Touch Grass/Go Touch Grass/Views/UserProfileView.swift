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

    var body: some View {
        ZStack {
            Color(red: 0.85, green: 0.93, blue: 0.85)
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

                        if let email = user.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Follower/Following counts
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text("\(followerCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 4) {
                                Text("\(followingCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                                .background(isFollowing ? Color.gray : Color(red: 0.0, green: 0.5, blue: 0.0))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(16)

                    // User's Activities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activities")
                            .font(.headline)

                        if activities.isEmpty {
                            Text("No activities yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                                            .background(Color(red: 0.2, green: 0.3, blue: 0.2))
                                            .cornerRadius(10)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(activity.activityType.rawValue)
                                                .font(.headline)
                                                .foregroundColor(.primary)

                                            if let notes = activity.notes {
                                                Text(notes)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }

                                            Text(formatDate(activity.timestamp))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.3))
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
