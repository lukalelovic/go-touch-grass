//
//  ActivityDetailViewModel.swift
//  Go Touch Grass
//
//  ViewModel for managing activity detail state and likes
//

import Foundation
import SwiftUI
import Combine
import Auth

@MainActor
class ActivityDetailViewModel: ObservableObject {
    @Published var likeCount: Int = 0
    @Published var hasLiked: Bool = false
    @Published var isLoading: Bool = false

    private let activity: Activity
    private var supabaseManager: SupabaseManager

    init(activity: Activity, supabaseManager: SupabaseManager = .shared) {
        self.activity = activity
        self.supabaseManager = supabaseManager

        // Initialize with the count from the activity
        self.likeCount = activity.likeCount ?? 0
    }

    func loadLikeState() async {
        guard let userId = supabaseManager.currentUser?.id else { return }

        do {
            // Check if current user has liked this activity
            hasLiked = try await supabaseManager.hasLiked(
                activityId: activity.id,
                userId: userId
            )
        } catch {
            print("❌ Error loading like state: \(error)")
        }
    }

    func toggleLike() {
        guard !isLoading else { return }
        guard let userId = supabaseManager.currentUser?.id else { return }

        Task {
            isLoading = true

            do {
                // Toggle like in database
                let nowLiked = try await supabaseManager.toggleLike(
                    activityId: activity.id,
                    userId: userId
                )

                // Update local state
                hasLiked = nowLiked

                // Update count based on whether user now likes it or not
                if nowLiked {
                    likeCount += 1
                } else {
                    likeCount = max(0, likeCount - 1)
                }

                print("✅ Like toggled: \(nowLiked ? "liked" : "unliked")")
            } catch {
                print("❌ Error toggling like: \(error)")
            }

            isLoading = false
        }
    }
}
