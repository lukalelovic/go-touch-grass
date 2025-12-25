//
//  LogActivityTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct TouchGrassTab: View {
    @StateObject private var activityStore = ActivityStore.shared
    @State private var selectedActivityType: ActivityType = .hiking
    @State private var notes: String = ""
    @State private var selectedLocation: Location?
    @State private var showLocationPicker = false
    @State private var showSuccessAlert = false

    // TODO: Replace with actual current user from Supabase Auth
    private let currentUser = User.sampleUsers[0]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.85, green: 0.93, blue: 0.85)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Activity Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Type")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Picker("Activity Type", selection: $selectedActivityType) {
                                ForEach(ActivityType.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
                                    }
                                    .tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                        }

                        // Notes Text Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextEditor(text: $notes)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Location Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Button(action: {
                                showLocationPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(selectedLocation != nil ? Color(red: 0.1, green: 0.6, blue: 0.1) : .gray)

                                    if let location = selectedLocation {
                                        Text(location.name ?? "Unknown Location")
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Search for a location")
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if selectedLocation != nil {
                                        Button(action: {
                                            selectedLocation = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }

                        // TODO: Add photo picker here in future
                        // VStack(alignment: .leading, spacing: 8) {
                        //     Text("Photo (Optional)")
                        //         .font(.headline)
                        //     Button("Add Photo") {
                        //         // Photo picker logic
                        //     }
                        // }

                        // Save Button
                        Button(action: saveActivity) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("I Touched Grass!")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.1, green: 0.6, blue: 0.1))
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)

                        // Info Text
                        Text("Remember: You can only log 3 activities per day!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("Touch Grass")
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
            }
            .alert("Activity Logged!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    clearForm()
                }
            } message: {
                Text("Your activity has been logged successfully!")
            }
        }
    }

    private func saveActivity() {
        // Validate: Check daily limit (3 activities per day)
        let todayCount = activityStore.getTodayActivityCount(for: currentUser)
        if todayCount >= 3 {
            // TODO: Show error alert instead
            print("Daily limit reached! You can only log 3 activities per day.")
            return
        }

        // Validate: Notes should not be empty
        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // TODO: Show error alert
            print("Please add some notes about your activity!")
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
        // supabaseClient.from("activities").insert(newActivity)

        // TODO: Upload photo to Supabase Storage if provided
        // - Upload image to storage bucket
        // - Get URL and update activity record

        // Show success message
        showSuccessAlert = true
    }

    private func clearForm() {
        selectedActivityType = .hiking
        notes = ""
        selectedLocation = nil
    }
}
