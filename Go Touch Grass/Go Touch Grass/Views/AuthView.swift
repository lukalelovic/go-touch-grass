//
//  AuthView.swift
//  Go Touch Grass
//
//  Authentication view for login and signup
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)

        ZStack {
            colors.primaryBackground.ignoresSafeArea()

            VStack(spacing: 30) {
                // Logo and title
                VStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(colors.accent)

                    Text("Go Touch Grass")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(colors.primaryText)

                    Text("Get outside and share your adventures")
                        .font(.subheadline)
                        .foregroundStyle(colors.secondaryText)
                }
                .padding(.top, 60)

                Spacer()

                // Auth form
                VStack(spacing: 20) {
                    // Toggle between login and signup
                    Picker("Mode", selection: $isSignUp) {
                        Text("Login").tag(false)
                        Text("Sign Up").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Username field (signup only)
                    if isSignUp {
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal)
                    }

                    // Email field
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(.horizontal)

                    // Password field
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Submit button
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text(isSignUp ? "Sign Up" : "Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(isLoading)
                }
                .padding(.vertical)
                .background(colors.cardBackground)
                .cornerRadius(20)
                .padding()

                Spacer()
            }
        }
    }

    private func handleAuth() {
        // Validate inputs
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }

        if isSignUp && username.isEmpty {
            errorMessage = "Please enter a username"
            return
        }

        if isSignUp && username.count < 3 {
            errorMessage = "Username must be at least 3 characters"
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isSignUp {
                    try await supabaseManager.signUpWithEmail(email: email, password: password, username: username)
                } else {
                    try await supabaseManager.signInWithEmail(email: email, password: password)
                }
                // Clear form on success
                await MainActor.run {
                    email = ""
                    password = ""
                    username = ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SupabaseManager.shared)
        .environmentObject(ThemeManager.shared)
}
