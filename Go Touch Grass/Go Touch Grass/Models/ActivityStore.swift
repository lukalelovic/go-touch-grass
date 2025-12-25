//
//  ActivityStore.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation
import Combine

class ActivityStore: ObservableObject {
    @Published var activities: [Activity] = Activity.sampleActivities

    static let shared = ActivityStore()

    private init() {}

    func addActivity(_ activity: Activity) {
        // Add to beginning of list (most recent first)
        activities.insert(activity, at: 0)

        // TODO: Later, this will also:
        // - Call Supabase to persist the activity
        // - Upload any associated photos
        // - Trigger any necessary notifications
        // - Update user stats/badges
    }

    func deleteActivity(_ activity: Activity) {
        activities.removeAll { $0.id == activity.id }

        // TODO: Later, this will also:
        // - Call Supabase to delete the activity
        // - Delete any associated photos from storage
    }

    func getActivitiesForUser(_ user: User) -> [Activity] {
        activities.filter { $0.user.id == user.id }
    }

    func getTodayActivityCount(for user: User) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return activities.filter { activity in
            activity.user.id == user.id &&
            calendar.isDate(activity.timestamp, inSameDayAs: today)
        }.count
    }
}
