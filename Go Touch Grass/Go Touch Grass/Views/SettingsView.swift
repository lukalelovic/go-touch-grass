//
//  SettingsView.swift
//  Go Touch Grass
//
//  Settings page for user account management
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        ZStack {
            colors.primaryBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture Section
                    VStack(spacing: 16) {
                        Text("Profile Picture")
                            .font(.headline)
                            .foregroundColor(colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            // Current profile picture
                            ProfilePictureView(
                                profilePictureUrl: viewModel.profilePictureUrl,
                                size: 80
                            )

                            Spacer()

                            VStack(spacing: 12) {
                                // Photo picker button
                                PhotosPicker(selection: $viewModel.selectedPhoto,
                                           matching: .images) {
                                    HStack {
                                        Image(systemName: "photo")
                                        Text("Choose Photo")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(colors.accent)
                                    .cornerRadius(8)
                                }

                                // Remove photo button
                                if viewModel.profilePictureUrl != nil {
                                    Button(action: {
                                        viewModel.removeProfilePicture()
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Remove")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(colors.cardBackground)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(colors.cardBackground)
                        .cornerRadius(12)
                    }

                    // Username Section
                    VStack(spacing: 16) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            TextField("Enter new username", text: $viewModel.newUsername)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            if let error = viewModel.usernameError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button(action: {
                                viewModel.updateUsername()
                            }) {
                                if viewModel.isUpdatingUsername {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Update Username")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canUpdateUsername() ? colors.accent : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(!viewModel.canUpdateUsername() || viewModel.isUpdatingUsername)
                        }
                        .padding()
                        .background(colors.cardBackground)
                        .cornerRadius(12)
                    }

                    // Privacy Settings Section
                    VStack(spacing: 16) {
                        Text("Privacy")
                            .font(.headline)
                            .foregroundColor(colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            Toggle(isOn: $viewModel.isPrivate) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Private Account")
                                        .foregroundColor(colors.primaryText)
                                        .fontWeight(.medium)
                                    Text("When enabled, new followers must send a request that you can approve or reject")
                                        .font(.caption)
                                        .foregroundColor(colors.secondaryText)
                                }
                            }
                            .tint(colors.accent)
                        }
                        .padding()
                        .background(colors.cardBackground)
                        .cornerRadius(12)
                    }

                    // Export Activities Section
                    VStack(spacing: 16) {
                        Text("Export Activities")
                            .font(.headline)
                            .foregroundColor(colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: {
                            viewModel.exportActivities()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export All Activities")
                                Spacer()
                            }
                            .foregroundColor(colors.primaryText)
                            .padding()
                            .background(colors.cardBackground)
                            .cornerRadius(12)
                        }
                    }

                    // Danger Zone
                    VStack(spacing: 16) {
                        Text("Danger Zone")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: {
                            viewModel.showDeleteAccountAlert = true
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Delete Account")
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(colors.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.primaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
        .onAppear {
            viewModel.updateSupabaseManager(supabaseManager)
            viewModel.loadUserData()
        }
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteAccount {
                    // Sign out and dismiss
                    Task {
                        try? await supabaseManager.signOut()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone. All your activities, followers, and data will be permanently deleted.")
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .onChange(of: viewModel.selectedPhoto) { oldValue, newValue in
            if newValue != nil {
                viewModel.handlePhotoSelection()
            }
        }
    }
}

// Share sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SupabaseManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}
