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
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        NavigationStack {
            ZStack {
                colors.primaryBackground
                    .ignoresSafeArea()

                if viewModel.activities.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(colors.secondaryText)

                        Text("Post your activities or follow your friends to see them listed here!")
                            .font(.headline)
                            .foregroundColor(colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    List(viewModel.activities) { activity in
                        NavigationLink(destination: ActivityDetailView(activity: activity)) {
                            ActivityRowView(activity: activity)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Feed")
            .toolbarBackground(colors.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UserSearchView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(colors.primaryText)
                    }
                }
            }
            .onAppear {
                viewModel.updateSupabaseManager(supabaseManager)
                viewModel.loadActivities()
            }
        }
    }
}
