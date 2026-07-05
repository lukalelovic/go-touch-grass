//
//  LiveActivityManager.swift
//  Go Touch Grass
//
//  Manages Live Activities for the app
//

import Foundation
import ActivityKit
import WidgetKit

// Type alias to avoid conflict with app's Activity model
typealias LiveActivity = ActivityKit.Activity

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: LiveActivity<TouchGrassActivityAttributes>?

    private init() {}

    // MARK: - Check Authorization

    func areActivitiesEnabled() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Start Live Activity

    func startLiveActivity(
        recommendationId: String,
        activityType: String,
        prompt: String,
        icon: String,
        duration: Int?
    ) async {
        // End any existing activity first
        await endLiveActivity()

        // Check if Live Activities are enabled
        guard areActivitiesEnabled() else {
            print("⚠️ Live Activities are not enabled")
            return
        }

        // Only start if ActivityKit is available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Activities are not authorized")
            return
        }

        do {
            let attributes = TouchGrassActivityAttributes(
                recommendationId: recommendationId,
                icon: icon,
                duration: duration
            )

            let initialState = TouchGrassActivityAttributes.ContentState(
                activityType: activityType,
                prompt: prompt,
                isCompleted: false,
                completedAt: nil
            )

            let activity = try LiveActivity<TouchGrassActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            print("✅ Live Activity started: \(activity.id)")

            // Update shared storage for widget
            updateSharedStorage(
                activityType: activityType,
                prompt: prompt,
                icon: icon,
                duration: duration,
                isCompleted: false
            )

            // Reload widget timeline
            WidgetCenter.shared.reloadTimelines(ofKind: "TouchGrassWidget")

        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    // MARK: - Mark Activity Completed

    func markActivityCompleted() async {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to mark as completed")
            return
        }

        let updatedState = TouchGrassActivityAttributes.ContentState(
            activityType: activity.content.state.activityType,
            prompt: activity.content.state.prompt,
            isCompleted: true,
            completedAt: Date()
        )

        await activity.update(
            ActivityContent(
                state: updatedState,
                staleDate: Date().addingTimeInterval(60 * 5) // Stale after 5 minutes
            )
        )

        print("✅ Live Activity marked as completed")

        // Update shared storage
        updateSharedStorage(
            activityType: activity.content.state.activityType,
            prompt: activity.content.state.prompt,
            icon: activity.attributes.icon,
            duration: activity.attributes.duration,
            isCompleted: true
        )

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "TouchGrassWidget")

        // Auto-dismiss after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await endLiveActivity()
        }
    }

    // MARK: - End Live Activity

    func endLiveActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = TouchGrassActivityAttributes.ContentState(
            activityType: activity.content.state.activityType,
            prompt: activity.content.state.prompt,
            isCompleted: activity.content.state.isCompleted,
            completedAt: activity.content.state.completedAt
        )

        await activity.end(
            ActivityContent(
                state: finalState,
                staleDate: Date()
            ),
            dismissalPolicy: .immediate
        )

        currentActivity = nil
        print("✅ Live Activity ended")
    }

    // MARK: - Shared Storage

    private func updateSharedStorage(
        activityType: String,
        prompt: String,
        icon: String,
        duration: Int?,
        isCompleted: Bool
    ) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.touchgrass.app") else {
            print("⚠️ Could not access shared UserDefaults")
            return
        }

        sharedDefaults.set(activityType, forKey: "todayActivityType")
        sharedDefaults.set(prompt, forKey: "todayPrompt")
        sharedDefaults.set(icon, forKey: "todayIcon")
        sharedDefaults.set(duration ?? 0, forKey: "todayDuration")
        sharedDefaults.set(isCompleted, forKey: "todayCompleted")

        if isCompleted {
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "todayCompletedAt")
        } else {
            sharedDefaults.set(0, forKey: "todayCompletedAt")
        }

        print("✅ Shared storage updated")
    }
}
