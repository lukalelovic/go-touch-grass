//
//  ShareTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct ShareTab: View {
    @StateObject private var viewModel = ShareViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        NavigationStack {
            ZStack {
                colors.primaryBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Activity Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Type")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)

                            if viewModel.isLoadingActivityTypes {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                                .background(colors.cardBackground)
                                .cornerRadius(12)
                            } else {
                                Picker("Activity Type", selection: $viewModel.selectedActivityType) {
                                    ForEach(viewModel.availableActivityTypes) { type in
                                        HStack {
                                            if let icon = type.icon {
                                                Image(systemName: icon)
                                            }
                                            Text(type.name)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(colors.cardBackground)
                                .cornerRadius(12)
                            }
                        }

                        // Notes Text Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)

                            ZStack(alignment: .topLeading) {
                                if viewModel.notes.isEmpty {
                                    Text("Share your experience...")
                                        .foregroundColor(colors.secondaryText.opacity(0.5))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                }

                                TextEditor(text: $viewModel.notes)
                                    .frame(height: 120)
                                    .padding(4)
                                    .scrollContentBackground(.hidden)
                                    .background(themeManager.isDarkMode ? Color(red: 0.2, green: 0.3, blue: 0.2) : Color.white.opacity(0.8))
                                    .foregroundColor(colors.primaryText)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }

                        // Location Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location (Optional)")
                                .font(.headline)
                                .foregroundColor(colors.primaryText)

                            Button(action: {
                                viewModel.showLocationPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(viewModel.selectedLocation != nil ? colors.accent : .gray)

                                    if let location = viewModel.selectedLocation {
                                        Text(location.name ?? "Unknown Location")
                                            .foregroundColor(colors.primaryText)
                                    } else {
                                        Text("Search for a location")
                                            .foregroundColor(colors.secondaryText)
                                    }

                                    Spacer()

                                    if viewModel.selectedLocation != nil {
                                        Button(action: {
                                            viewModel.selectedLocation = nil
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
                                .background(colors.cardBackground)
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
                        Button(action: viewModel.saveActivity) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Share Activity")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.accent)
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)

                        // Info Text
                        Text("Remember: You can only log 1 activity per day!")
                            .font(.caption)
                            .foregroundColor(colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("Share")
            .toolbarBackground(colors.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(selectedLocation: $viewModel.selectedLocation)
            }
            .alert("Activity Logged!", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) {
                    viewModel.clearForm()
                }
            } message: {
                Text("Your activity has been logged successfully!")
            }
            .onAppear {
                viewModel.updateSupabaseManager(supabaseManager)
                viewModel.loadActivityTypes()
            }
        }
    }
}
