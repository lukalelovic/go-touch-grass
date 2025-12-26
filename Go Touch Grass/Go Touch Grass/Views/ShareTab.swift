//
//  ShareTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct ShareTab: View {
    @StateObject private var viewModel = ShareViewModel()

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

                            Picker("Activity Type", selection: $viewModel.selectedActivityType) {
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

                            TextEditor(text: $viewModel.notes)
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
                                viewModel.showLocationPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(viewModel.selectedLocation != nil ? Color(red: 0.1, green: 0.6, blue: 0.1) : .gray)

                                    if let location = viewModel.selectedLocation {
                                        Text(location.name ?? "Unknown Location")
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Search for a location")
                                            .foregroundColor(.secondary)
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
                        Button(action: viewModel.saveActivity) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Share Activity")
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
            .navigationTitle("Share")
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
        }
    }
}
