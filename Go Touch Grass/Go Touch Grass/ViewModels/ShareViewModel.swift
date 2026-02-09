//
//  ShareViewModel.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/25/25.
//

import Foundation
import Combine
import Auth

@MainActor
class ShareViewModel: ObservableObject {
    @Published var availableActivityTypes: [ActivityType] = [ActivityType.hiking]
    @Published var selectedActivityType: ActivityType = ActivityType.hiking
    @Published var notes: String = ""
    @Published var selectedLocation: Location?
    @Published var showLocationPicker = false
    @Published var showSuccessAlert = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var isLoadingActivityTypes = false

    private let activityStore: ActivityStore
    private var supabaseManager: SupabaseManager

    init(activityStore: ActivityStore = .shared, supabaseManager: SupabaseManager? = nil) {
        self.activityStore = activityStore
        self.supabaseManager = supabaseManager ?? SupabaseManager.shared
    }

    func updateSupabaseManager(_ manager: SupabaseManager) {
        self.supabaseManager = manager
    }

    func loadActivityTypes() {
        Task {
            await loadActivityTypesAsync()
        }
    }

    private func loadActivityTypesAsync() async {
        isLoadingActivityTypes = true
        do {
            let types = try await supabaseManager.fetchActivityTypes()
            if !types.isEmpty {
                availableActivityTypes = types
                // Always select the first type from database
                selectedActivityType = types[0]
            }
            isLoadingActivityTypes = false
        } catch {
            print("Failed to load activity types: \(error)")
            // Keep hiking as fallback (already initialized)
            isLoadingActivityTypes = false
        }
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

        // Get the authenticated user
        guard let authUser = supabaseManager.currentUser else {
            errorMessage = "Not authenticated"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let userId = authUser.id

            // Check daily limit (1 activity per day)
            let todayCount = try await supabaseManager.getTodayActivityCount(userId: userId)
            if todayCount >= 1 {
                errorMessage = "Daily limit reached! You can only log 1 activity per day."
                isSaving = false
                return
            }

            // Create activity in Supabase
            let newActivity = try await supabaseManager.createActivity(
                userId: userId,
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
        // Reset to first available type
        if let firstType = availableActivityTypes.first {
            selectedActivityType = firstType
        }
        notes = ""
        selectedLocation = nil
    }

    func canSaveActivity() -> Bool {
        return !isSaving && !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
