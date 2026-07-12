//
//  FeedTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct FeedTab: View {
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    var body: some View {
        let colors = AppColors()

        NavigationStack {
            ZStack {
                NatureBackgroundView()

                VStack(spacing: 0) {
                    // Custom header with search button
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("Feed")
                                .font(.grassTitle)
                                .foregroundStyle(colors.primaryText)
                            
                            Text("See what your friends are up to")
                                .font(.grassSubheadline)
                                .foregroundStyle(colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Custom search button
                        NavigationLink(destination: UserSearchView()) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundStyle(colors.accent)
                                .frame(width: 44, height: 44)
                                .background {
                                    Circle()
                                        .fill(Color(red: 0.28, green: 0.50, blue: 0.20).opacity(0.9))
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, AppSpacing.sm)
                    
                    // Content
                    ScrollView {
                        if viewModel.activities.isEmpty {
                            // Enhanced empty state
                            GlassCard {
                                VStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(colors.accent)
                                        .shadow(color: colors.accentGlow, radius: 8, x: 0, y: 4)

                                    Text("Your Feed is Empty")
                                        .font(.grassTitle2)
                                        .foregroundColor(colors.primaryText)
                                        .padding(.top, AppSpacing.xxs)

                                    Text("Post your activities or follow your friends to see them listed here!")
                                        .font(.grassBody)
                                        .foregroundColor(colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, AppSpacing.md)
                                }
                                .padding(.vertical, AppSpacing.lg)
                            }
                            .padding(.horizontal)
                        } else {
                            // Activity list
                            LazyVStack(spacing: AppSpacing.xs) {
                                ForEach(viewModel.activities) { activity in
                                    NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                        ActivityRowView(
                                            activity: activity,
                                            isTouchGrassActivity: activity.isTouchGrassActivity
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.updateSupabaseManager(supabaseManager)
                viewModel.loadActivities()
            }
        }
    }
}
