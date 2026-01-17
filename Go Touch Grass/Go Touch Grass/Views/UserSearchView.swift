//
//  UserSearchView.swift
//  Go Touch Grass
//
//  Search for users by username
//

import SwiftUI

struct UserSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var searchResults: [User] = []
    @State private var isSearching: Bool = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        ZStack {
            colors.primaryBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search results list
                if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(colors.secondaryText)
                        Text("No users found")
                            .font(.headline)
                            .foregroundColor(colors.secondaryText)
                        Text("Try searching for a different username")
                            .font(.subheadline)
                            .foregroundColor(colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(colors.secondaryText)
                        Text("Search for users")
                            .font(.headline)
                            .foregroundColor(colors.secondaryText)
                        Text("Find friends by their username")
                            .font(.subheadline)
                            .foregroundColor(colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults) { user in
                        NavigationLink(destination: UserProfileView(user: user, isCurrentUser: false)) {
                            HStack(spacing: 12) {
                                ProfilePictureView(
                                    profilePictureUrl: user.profilePictureUrl,
                                    size: 50
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.username)
                                        .font(.headline)
                                        .foregroundColor(colors.primaryText)

                                    if let email = user.email {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(colors.secondaryText)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(colors.secondaryText)
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(colors.cardBackground)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Search Users")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by username")
        .onChange(of: searchText) { oldValue, newValue in
            performSearch(query: newValue)
        }
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        // TODO: Query Supabase for users matching the search query
        // For now, using sample data filtered by username
        searchResults = User.sampleUsers.filter { user in
            user.username.localizedCaseInsensitiveContains(query)
        }

        isSearching = false
    }
}
