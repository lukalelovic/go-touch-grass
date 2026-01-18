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
    @Published var isSaving = false

    private let activityStore: ActivityStore
    private let supabaseManager: SupabaseManager
    // TODO: Replace with actual current user from Supabase Auth when auth is implemented
    // Using real user from database for now
    private let currentUser = User(
        id: UUID(uuidString: "28eb3c73-4815-4d69-a0ba-0c0ae84d1764")!,
        username: "outdoor_enthusiast",
        email: nil,
        profilePictureUrl: nil,
        createdAt: nil,
        updatedAt: nil
    )

    init(activityStore: ActivityStore = .shared, supabaseManager: SupabaseManager = SupabaseManager()) {
        self.activityStore = activityStore
        self.supabaseManager = supabaseManager
    }

    // MARK: - Public Methods

    func saveActivity() {
        Task {
            await saveActivityAsync()
        }
    }

    private func saveActivityAsync() async {
        // Validate: Notes should not be empty
        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please add some notes about your activity!"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            // Check daily limit (3 activities per day)
            let todayCount = try await supabaseManager.getTodayActivityCount(userId: currentUser.id)
            if todayCount >= 3 {
                errorMessage = "Daily limit reached! You can only log 3 activities per day."
                isSaving = false
                return
            }

            // Create activity in Supabase
            let newActivity = try await supabaseManager.createActivity(
                userId: currentUser.id,
                activityType: selectedActivityType,
                notes: notes.isEmpty ? nil : notes,
                location: selectedLocation,
                timestamp: Date()
            )

            // Also save to in-memory store for local UI updates
            activityStore.addActivity(newActivity)

            // TODO: Upload photo to Supabase Storage if provided
            // - Upload image to storage bucket
            // - Get URL and update activity record

            // Show success message
            isSaving = false
            showSuccessAlert = true
        } catch {
            errorMessage = "Failed to save activity: \(error.localizedDescription)"
            isSaving = false
            print("Error saving activity: \(error)")
        }
    }

    func clearForm() {
        selectedActivityType = .hiking
        notes = ""
        selectedLocation = nil
    }

    func canSaveActivity() -> Bool {
        return !isSaving && !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
