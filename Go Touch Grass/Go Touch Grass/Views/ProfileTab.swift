//
//  ProfileTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct ProfileTab: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        NavigationStack {
            ZStack {
                colors.primaryBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User Info Card
                        if let currentUser = viewModel.currentUser {
                            VStack(spacing: 12) {
                                // Profile Picture
                                ProfilePictureView(
                                    profilePictureUrl: currentUser.profilePictureUrl,
                                    size: 100
                                )

                                Text(currentUser.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(colors.primaryText)

                                // Follower/Following counts
                                HStack(spacing: 24) {
                                    VStack(spacing: 4) {
                                        Text("\(viewModel.followerCount)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(colors.primaryText)
                                        Text("Followers")
                                            .font(.caption)
                                            .foregroundColor(colors.secondaryText)
                                    }

                                    VStack(spacing: 4) {
                                        Text("\(viewModel.followingCount)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(colors.primaryText)
                                        Text("Following")
                                            .font(.caption)
                                            .foregroundColor(colors.secondaryText)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colors.cardBackground)
                            .cornerRadius(16)
                        }

                        // Level Card
                        if let levelInfo = viewModel.levelInfo {
                            VStack(spacing: 12) {
                                HStack {
                                    if let icon = levelInfo.milestoneIcon {
                                        Image(systemName: icon)
                                            .font(.system(size: 40))
                                            .foregroundColor(colors.accentDark)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Level \(levelInfo.currentLevel)")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(colors.primaryText)
                                        if let milestoneName = levelInfo.milestoneName {
                                            Text(milestoneName)
                                                .font(.headline)
                                                .foregroundColor(colors.secondaryText)
                                        }
                                    }
                                    Spacer()
                                }

                                // Progress to next milestone
                                if let nextName = levelInfo.nextMilestoneName, levelInfo.activitiesToNextMilestone > 0 {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("\(levelInfo.activitiesToNextMilestone) activities to \(nextName)")
                                                .font(.caption)
                                                .foregroundColor(colors.secondaryText)
                                            Spacer()
                                            Text("\(Int(levelInfo.progressToNextMilestone))%")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(colors.primaryText)
                                        }

                                        ProgressView(value: levelInfo.progressToNextMilestone, total: 100)
                                            .tint(colors.accentDark)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colors.cardBackground)
                            .cornerRadius(16)
                        }

                        // Stats Card
                        VStack(spacing: 16) {
                            Text("Stats")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)
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
                                        .foregroundColor(colors.primaryText)
                                    Text("Day Streak")
                                        .font(.caption)
                                        .foregroundColor(colors.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.cardBackground)
                                .cornerRadius(12)

                                // Total Activities
                                VStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(colors.accent)
                                    Text("\(viewModel.totalActivities)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(colors.primaryText)
                                    Text("Activities")
                                        .font(.caption)
                                        .foregroundColor(colors.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colors.secondaryCardBackground)
                        .cornerRadius(16)

                        // Badges Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Badges")
                                    .font(.headline)
                                    .foregroundColor(colors.primaryText)
                                Spacer()
                                Text("\(viewModel.unlockedBadges.count)/\(viewModel.badgeProgress.count)")
                                    .font(.subheadline)
                                    .foregroundColor(colors.secondaryText)
                            }

                            if viewModel.unlockedBadges.isEmpty {
                                Text("Complete activities to earn badges!")
                                    .font(.subheadline)
                                    .foregroundColor(colors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                // Show unlocked badges
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                                    ForEach(viewModel.unlockedBadges) { badgeProgress in
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(
                                                        red: badgeProgress.badge.rarity.color.red,
                                                        green: badgeProgress.badge.rarity.color.green,
                                                        blue: badgeProgress.badge.rarity.color.blue
                                                    ).opacity(0.3))
                                                    .frame(width: 60, height: 60)

                                                if let icon = badgeProgress.badge.icon {
                                                    Image(systemName: icon)
                                                        .font(.system(size: 28))
                                                        .foregroundColor(Color(
                                                            red: badgeProgress.badge.rarity.color.red,
                                                            green: badgeProgress.badge.rarity.color.green,
                                                            blue: badgeProgress.badge.rarity.color.blue
                                                        ))
                                                }
                                            }

                                            Text(badgeProgress.badge.name)
                                                .font(.caption2)
                                                .foregroundColor(colors.primaryText)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                    }
                                }

                                // Show locked badges (grayed out)
                                if !viewModel.lockedBadges.isEmpty {
                                    Divider()
                                        .padding(.vertical, 4)
                                        .background(colors.divider)

                                    Text("Locked Badges")
                                        .font(.caption)
                                        .foregroundColor(colors.secondaryText)

                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                                        ForEach(viewModel.lockedBadges.prefix(6)) { badgeProgress in
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 60, height: 60)

                                                    if let icon = badgeProgress.badge.icon {
                                                        Image(systemName: icon)
                                                            .font(.system(size: 28))
                                                            .foregroundColor(.gray.opacity(0.5))
                                                    }

                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.gray)
                                                        .offset(x: 15, y: 15)
                                                }

                                                Text(badgeProgress.badge.name)
                                                    .font(.caption2)
                                                    .foregroundColor(colors.secondaryText)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colors.secondaryCardBackground)
                        .cornerRadius(16)

                        // Recent Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activities")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)

                            if viewModel.userActivities.isEmpty {
                                Text("No activities yet. Go touch grass!")
                                    .font(.subheadline)
                                    .foregroundColor(colors.secondaryText)
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

                                                Text(viewModel.formatDate(activity.timestamp))
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

                        // Settings/Logout Section
                        VStack(spacing: 12) {
                            // Dark Mode Toggle
                            Button(action: {
                                themeManager.toggleTheme()
                            }) {
                                HStack {
                                    Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                                    Text(themeManager.isDarkMode ? "Dark Mode" : "Light Mode")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(colors.primaryText)
                                .padding()
                                .background(colors.cardBackground)
                                .cornerRadius(12)
                            }

                            NavigationLink(destination: SettingsView()) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Settings")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(colors.primaryText)
                                .padding()
                                .background(colors.cardBackground)
                                .cornerRadius(12)
                            }

                            Button(action: {
                                Task {
                                    do {
                                        try await supabaseManager.signOut()
                                    } catch {
                                        print("Error signing out: \(error)")
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding()
                                .background(colors.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbarBackground(colors.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
            .onAppear {
                viewModel.updateSupabaseManager(supabaseManager)
                viewModel.loadUserProfile()
            }
        }
    }
}
