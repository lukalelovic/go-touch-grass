//
//  ProfileTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct ProfileTab: View {
    @StateObject private var activityStore = ActivityStore.shared

    // TODO: Replace with actual current user from Supabase Auth
    @State private var currentUser: User = User.sampleUsers[0]
    @State private var userActivities: [Activity] = []
    @State private var currentStreak: Int = 0
    @State private var totalActivities: Int = 0
    @State private var badges: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.85, green: 0.93, blue: 0.85)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User Info Card
                        VStack(spacing: 12) {
                            // Profile Picture Placeholder
                            Circle()
                                .fill(Color(red: 0.2, green: 0.3, blue: 0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                )

                            Text(currentUser.username)
                                .font(.title2)
                                .fontWeight(.bold)

                            if let email = currentUser.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(16)

                        // Stats Card
                        VStack(spacing: 16) {
                            Text("Stats")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 16) {
                                // Streak
                                VStack {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.orange)
                                    Text("\(currentStreak)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Day Streak")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)

                                // Total Activities
                                VStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.green)
                                    Text("\(totalActivities)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Activities")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(16)

                        // Badges Section (placeholder)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Badges")
                                .font(.headline)

                            if badges.isEmpty {
                                Text("Complete activities to earn badges!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                    ForEach(badges, id: \.self) { badge in
                                        VStack {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.yellow)
                                            Text(badge)
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(16)

                        // Recent Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activities")
                                .font(.headline)

                            if userActivities.isEmpty {
                                Text("No activities yet. Go touch grass!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(userActivities.prefix(5)) { activity in
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

                        // Settings/Logout Section
                        VStack(spacing: 12) {
                            Button(action: {
                                // TODO: Navigate to settings
                            }) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Settings")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                            }

                            Button(action: {
                                // TODO: Implement logout
                                // - Call Supabase auth signOut
                                // - Clear local user data
                                // - Navigate to login screen
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                loadUserProfile()
            }
        }
    }

    private func loadUserProfile() {
        // TODO: Fetch current user from Supabase Auth
        // - Get authenticated user session
        // - Load user profile data
        // supabaseClient.auth.session?.user

        // TODO: Fetch user's activities from Supabase
        // - Query activities table filtered by user_id
        // - Sort by timestamp descending
        // - Limit to recent activities (e.g., last 20)
        // let activities = supabaseClient
        //     .from("activities")
        //     .select()
        //     .eq("user_id", currentUser.id)
        //     .order("timestamp", ascending: false)
        //     .limit(20)

        // TODO: Calculate streak
        // - Query activities grouped by date
        // - Count consecutive days with activities
        // - Update currentStreak state

        // TODO: Calculate total activities count
        // - Count total activities for user
        // - Update totalActivities state

        // TODO: Fetch earned badges
        // - Query user_badges table
        // - Or calculate based on achievements
        // - Update badges state

        // Load data from ActivityStore
        userActivities = activityStore.getActivitiesForUser(currentUser)
        totalActivities = userActivities.count
        currentStreak = 3 // Placeholder - TODO: Calculate actual streak
        badges = [] // Empty for now
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
