//
//  FeedTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct FeedTab: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.85, green: 0.93, blue: 0.85)
                    .ignoresSafeArea()

                if viewModel.activities.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("Post your activities or follow your friends to see them listed here!")
                            .font(.headline)
                            .foregroundColor(.secondary)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UserSearchView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                viewModel.loadActivities()
            }
        }
    }
}
