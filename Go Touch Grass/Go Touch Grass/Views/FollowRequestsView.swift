//
//  FollowRequestsView.swift
//  Go Touch Grass
//
//  View for managing follow requests (private accounts)
//

import SwiftUI
import Auth

struct FollowRequestsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) var dismiss

    @State private var pendingRequests: [FollowRequestWithUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        ZStack {
            colors.primaryBackground
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(colors.accent)
            } else if pendingRequests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(colors.secondaryText)
                    Text("No pending requests")
                        .font(.headline)
                        .foregroundColor(colors.secondaryText)
                    Text("When users request to follow you, they'll appear here")
                        .font(.subheadline)
                        .foregroundColor(colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(pendingRequests) { request in
                            FollowRequestRow(
                                request: request,
                                onAccept: {
                                    acceptRequest(request)
                                },
                                onReject: {
                                    rejectRequest(request)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Follow Requests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.primaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
        .onAppear {
            loadPendingRequests()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    private func loadPendingRequests() {
        guard let userId = supabaseManager.currentUser?.id else { return }

        isLoading = true
        Task {
            do {
                pendingRequests = try await supabaseManager.getPendingFollowRequests(userId: userId)
                isLoading = false
            } catch {
                errorMessage = "Failed to load follow requests: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func acceptRequest(_ request: FollowRequestWithUser) {
        guard let currentUserId = supabaseManager.currentUser?.id else { return }

        Task {
            do {
                _ = try await supabaseManager.acceptFollowRequest(
                    requesterId: request.userId,
                    requestedId: currentUserId
                )
                // Remove from list
                pendingRequests.removeAll { $0.id == request.id }

                // Notify other views to refresh (in case they're showing follower counts)
                NotificationCenter.default.post(name: NSNotification.Name("RefreshProfile"), object: nil)
            } catch {
                errorMessage = "Failed to accept request: \(error.localizedDescription)"
            }
        }
    }

    private func rejectRequest(_ request: FollowRequestWithUser) {
        guard let currentUserId = supabaseManager.currentUser?.id else { return }

        Task {
            do {
                _ = try await supabaseManager.rejectFollowRequest(
                    requesterId: request.userId,
                    requestedId: currentUserId
                )
                // Remove from list
                pendingRequests.removeAll { $0.id == request.id }
            } catch {
                errorMessage = "Failed to reject request: \(error.localizedDescription)"
            }
        }
    }
}

struct FollowRequestRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let request: FollowRequestWithUser
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        HStack(spacing: 12) {
            // Profile picture
            ProfilePictureView(
                profilePictureUrl: request.profilePictureUrl,
                size: 50
            )

            // Username
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(request.username)")
                    .font(.headline)
                    .foregroundColor(colors.primaryText)

                Text(timeAgoString(from: request.createdAt))
                    .font(.caption)
                    .foregroundColor(colors.secondaryText)
            }

            Spacer()

            // Accept/Reject buttons
            HStack(spacing: 8) {
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.red)
                        .clipShape(Circle())
                }

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(colors.accent)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(colors.cardBackground)
        .cornerRadius(12)
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "just now"
        }
    }
}

#Preview {
    NavigationStack {
        FollowRequestsView()
            .environmentObject(SupabaseManager())
            .environmentObject(ThemeManager.shared)
    }
}
