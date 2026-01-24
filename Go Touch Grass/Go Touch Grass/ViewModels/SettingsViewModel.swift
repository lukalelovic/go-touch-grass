//
//  SettingsViewModel.swift
//  Go Touch Grass
//
//  View model for settings and account management
//

import Foundation
import SwiftUI
import PhotosUI
import Auth
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var newUsername: String = ""
    @Published var usernameError: String?
    @Published var isUpdatingUsername = false

    @Published var profilePictureUrl: String?
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var isUploadingPhoto = false

    @Published var isPrivate: Bool = false {
        didSet {
            if oldValue != isPrivate {
                updatePrivacySetting()
            }
        }
    }

    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var successMessage: String?
    @Published var errorMessage: String?

    @Published var showDeleteAccountAlert = false
    @Published var showShareSheet = false
    @Published var exportFileURL: URL?

    private var supabaseManager: SupabaseManager
    private var currentUserId: UUID?

    init(supabaseManager: SupabaseManager? = nil) {
        self.supabaseManager = supabaseManager ?? SupabaseManager()
    }

    func updateSupabaseManager(_ manager: SupabaseManager) {
        self.supabaseManager = manager
    }

    func loadUserData() {
        guard let authUser = supabaseManager.currentUser else { return }

        Task {
            do {
                currentUserId = authUser.id
                let user = try await supabaseManager.fetchUser(userId: authUser.id)
                newUsername = user.username
                profilePictureUrl = user.profilePictureUrl
                isPrivate = user.isPrivate
                print("🔵 Loaded user data - profilePictureUrl: \(user.profilePictureUrl ?? "nil"), isPrivate: \(user.isPrivate)")
            } catch {
                print("Error loading user data: \(error)")
            }
        }
    }

    func handlePhotoSelection() {
        Task {
            await uploadProfilePicture()
        }
    }

    // MARK: - Username Update

    func canUpdateUsername() -> Bool {
        return !newUsername.isEmpty && newUsername.count >= 3 && !isUpdatingUsername
    }

    func updateUsername() {
        guard let userId = currentUserId else {
            usernameError = "User not authenticated"
            return
        }

        guard newUsername.count >= 3 else {
            usernameError = "Username must be at least 3 characters"
            return
        }

        usernameError = nil
        isUpdatingUsername = true

        Task {
            do {
                try await supabaseManager.updateUsername(userId: userId, newUsername: newUsername)

                successMessage = "Username updated successfully!"
                showSuccessAlert = true
                isUpdatingUsername = false
            } catch {
                errorMessage = "Failed to update username: \(error.localizedDescription)"
                showErrorAlert = true
                isUpdatingUsername = false
            }
        }
    }

    // MARK: - Profile Picture

    private func uploadProfilePicture() async {
        guard let userId = currentUserId,
              let selectedPhoto = selectedPhoto else { return }

        isUploadingPhoto = true

        do {
            // Delete old profile picture from storage if exists
            if let oldUrl = profilePictureUrl {
                print("🔄 Deleting old profile picture: \(oldUrl)")
                try? await supabaseManager.deleteProfilePicture(url: oldUrl)
            }

            // Load image data
            guard let imageData = try await selectedPhoto.loadTransferable(type: Data.self) else {
                throw NSError(domain: "SettingsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
            }

            // Upload to Supabase Storage and get the public URL
            let publicURL = try await supabaseManager.uploadProfilePicture(userId: userId, imageData: imageData)
            print("✅ Uploaded new profile picture: \(publicURL)")

            // Update database with picture URL
            try await supabaseManager.updateProfilePicture(userId: userId, pictureUrl: publicURL)

            // Verify the update by fetching the user again
            let updatedUser = try await supabaseManager.fetchUser(userId: userId)
            print("🔍 Verification - profile_picture_url after upload: \(updatedUser.profilePictureUrl ?? "nil")")

            profilePictureUrl = publicURL
            successMessage = "Profile picture updated successfully!"
            showSuccessAlert = true
            isUploadingPhoto = false
            self.selectedPhoto = nil

            // Notify other views to refresh profile data
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("RefreshProfile"), object: nil)
            }
        } catch {
            errorMessage = "Failed to upload profile picture: \(error.localizedDescription)"
            showErrorAlert = true
            isUploadingPhoto = false
            self.selectedPhoto = nil
        }
    }

    func removeProfilePicture() {
        guard let userId = currentUserId else { return }

        Task {
            do {
                // Delete from storage if exists
                if let currentUrl = profilePictureUrl {
                    try? await supabaseManager.deleteProfilePicture(url: currentUrl)
                }

                // Update database to remove URL
                print("🔴 Removing profile picture for user: \(userId)")
                try await supabaseManager.updateProfilePicture(userId: userId, pictureUrl: nil)
                print("✅ Database updated successfully, profile_picture_url set to nil")

                // Verify the update by fetching the user again
                let updatedUser = try await supabaseManager.fetchUser(userId: userId)
                print("🔍 Verification - profile_picture_url after update: \(updatedUser.profilePictureUrl ?? "nil")")

                if updatedUser.profilePictureUrl != nil {
                    throw NSError(domain: "SettingsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile picture URL was not cleared in database"])
                }

                profilePictureUrl = nil
                successMessage = "Profile picture removed"
                showSuccessAlert = true

                // Notify other views to refresh profile data
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshProfile"), object: nil)
                }
            } catch {
                errorMessage = "Failed to remove profile picture: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }

    // MARK: - Privacy Settings

    private func updatePrivacySetting() {
        guard let userId = currentUserId else { return }

        Task {
            do {
                try await supabaseManager.updateUserPrivacy(userId: userId, isPrivate: isPrivate)
                print("✅ Privacy setting updated: \(isPrivate)")
            } catch {
                errorMessage = "Failed to update privacy setting: \(error.localizedDescription)"
                showErrorAlert = true
                // Revert the toggle on error
                await MainActor.run {
                    isPrivate = !isPrivate
                }
            }
        }
    }

    // MARK: - Export Activities

    func exportActivities() {
        guard let userId = currentUserId else { return }

        Task {
            do {
                // Fetch all user activities
                let activities = try await supabaseManager.fetchUserActivities(userId: userId, limit: 1000)

                // Generate CSV content
                var csvText = "Activity Type,Notes,Location,Timestamp,Likes\n"

                for activity in activities {
                    let type = activity.activityType.rawValue
                    let notes = (activity.notes ?? "").replacingOccurrences(of: ",", with: ";")
                    let location = activity.location?.name ?? ""
                    let timestamp = ISO8601DateFormatter().string(from: activity.timestamp)
                    let likes = "\(activity.likeCount)"

                    csvText += "\(type),\(notes),\(location),\(timestamp),\(likes)\n"
                }

                // Save to temporary file
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "activities_\(Date().timeIntervalSince1970).csv"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try csvText.write(to: fileURL, atomically: true, encoding: .utf8)

                // Show share sheet
                exportFileURL = fileURL
                showShareSheet = true
            } catch {
                errorMessage = "Failed to export activities: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }

    // MARK: - Delete Account

    func deleteAccount(completion: @escaping () -> Void) {
        guard let userId = currentUserId else { return }

        Task {
            do {
                // Delete user account (this should cascade delete all related data)
                try await supabaseManager.deleteUserAccount(userId: userId)

                // Call completion to sign out
                await MainActor.run {
                    completion()
                }
            } catch {
                errorMessage = "Failed to delete account: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
}
