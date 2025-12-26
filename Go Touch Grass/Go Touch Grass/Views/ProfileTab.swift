//
//  ProfileTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct ProfileTab: View {
    @StateObject private var viewModel = ProfileViewModel()

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

                            Text(viewModel.currentUser.username)
                                .font(.title2)
                                .fontWeight(.bold)

                            if let email = viewModel.currentUser.email {
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
                                    Text("\(viewModel.currentStreak)")
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
                                    Text("\(viewModel.totalActivities)")
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

                            if viewModel.badges.isEmpty {
                                Text("Complete activities to earn badges!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                    ForEach(viewModel.badges, id: \.self) { badge in
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

                            if viewModel.userActivities.isEmpty {
                                Text("No activities yet. Go touch grass!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(viewModel.userActivities.prefix(5)) { activity in
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

                                                Text(viewModel.formatDate(activity.timestamp))
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
                viewModel.loadUserProfile()
            }
        }
    }
}
