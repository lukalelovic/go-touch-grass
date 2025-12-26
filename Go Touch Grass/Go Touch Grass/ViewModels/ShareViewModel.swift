//
//  ShareViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine

@MainActor
class ShareViewModel: ObservableObject {
    @Published var selectedActivityType: ActivityType = .hiking
    @Published var notes: String = ""
    @Published var selectedLocation: Location?
    @Published var showLocationPicker = false
    @Published var showSuccessAlert = false
    @Published var errorMessage: String?

    private let activityStore: ActivityStore
    // TODO: Replace with actual current user from Supabase Auth
    private let currentUser = User.sampleUsers[0]

    init(activityStore: ActivityStore = .shared) {
        self.activityStore = activityStore
    }

    // MARK: - Public Methods

    func saveActivity() {
        // Validate: Check daily limit (3 activities per day)
        let todayCount = activityStore.getTodayActivityCount(for: currentUser)
        if todayCount >= 3 {
            errorMessage = "Daily limit reached! You can only log 3 activities per day."
            return
        }

        // Validate: Notes should not be empty
        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please add some notes about your activity!"
            return
        }

        // Create Activity object
        let newActivity = Activity(
            user: currentUser,
            activityType: selectedActivityType,
            timestamp: Date(),
            notes: notes.isEmpty ? nil : notes,
            location: selectedLocation
        )

        // Save to in-memory store
        activityStore.addActivity(newActivity)

        // TODO: Later, call Supabase to persist activity
        // - POST to Supabase activities table
        // - Handle success/error responses
        // do {
        //     try await supabaseClient.from("activities").insert(newActivity)
        //     showSuccessAlert = true
        // } catch {
        //     errorMessage = "Failed to save activity: \(error.localizedDescription)"
        // }

        // TODO: Upload photo to Supabase Storage if provided
        // - Upload image to storage bucket
        // - Get URL and update activity record

        // Show success message
        showSuccessAlert = true
    }

    func clearForm() {
        selectedActivityType = .hiking
        notes = ""
        selectedLocation = nil
    }

    func canSaveActivity() -> Bool {
        let todayCount = activityStore.getTodayActivityCount(for: currentUser)
        return todayCount < 3 && !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
