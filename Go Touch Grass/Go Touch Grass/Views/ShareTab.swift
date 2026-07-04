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
        let colors = AppColors()

        NavigationStack {
            ZStack {
                NatureBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        // Custom header like TouchGrassTab
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("Share")
                                .font(.grassTitle)
                                .foregroundStyle(colors.primaryText)
                            
                            Text("Log your outdoor activity")
                                .font(.grassSubheadline)
                                .foregroundStyle(colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, AppSpacing.xs)
                        
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
                                Menu {
                                    ForEach(viewModel.availableActivityTypes) { type in
                                        Button(action: {
                                            viewModel.selectedActivityType = type
                                        }) {
                                            HStack {
                                                if let icon = type.icon {
                                                    Image(systemName: icon)
                                                }
                                                Text(type.name)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if let icon = viewModel.selectedActivityType.icon {
                                            Image(systemName: icon)
                                                .foregroundColor(colors.primaryText)
                                        }
                                        Text(viewModel.selectedActivityType.name)
                                            .foregroundColor(colors.primaryText)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(colors.secondaryText)
                                            .font(.caption)
                                    }
                                }
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
                                    .background(colors.cardBackground)
                                    .foregroundColor(colors.primaryText)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .onChange(of: viewModel.notes) { _ in
                                        // Clear error when user starts typing
                                        if viewModel.errorMessage != nil {
                                            viewModel.errorMessage = nil
                                        }
                                    }
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

                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Save Button
                        Button(action: viewModel.saveActivity) {
                            HStack {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: colors.primaryBackground))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Share Activity")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(colors.primaryBackground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isSaving ? Color.gray : .white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isSaving)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
