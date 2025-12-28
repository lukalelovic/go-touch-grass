//
//  SupabaseManager.swift
//  Go Touch Grass
//
//  Supabase client manager singleton
//

import Foundation
import Combine
import Supabase

class SupabaseManager: ObservableObject {
    @MainActor static let shared = SupabaseManager()

    let client: SupabaseClient

    @MainActor @Published var isAuthenticated = false
    @MainActor @Published var currentUser: Auth.User?

    @MainActor private init() {
        // Initialize Supabase client with environment variables
        self.client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )

        // Set up auth state listener
        Task {
            await setupAuthListener()
        }
    }

    // MARK: - Auth State Listener

    @MainActor private func setupAuthListener() async {
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .signedIn:
                if let session = session {
                    self.isAuthenticated = true
                    self.currentUser = session.user
                    print("User signed in: \(session.user.id)")
                }
            case .signedOut:
                self.isAuthenticated = false
                self.currentUser = nil
                print("User signed out")
            case .initialSession:
                if let session = session {
                    self.isAuthenticated = true
                    self.currentUser = session.user
                    print("Initial session found: \(session.user.id)")
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    print("No initial session")
                }
            case .userUpdated:
                if let session = session {
                    self.currentUser = session.user
                    print("User updated: \(session.user.id)")
                }
            case .tokenRefreshed:
                if let session = session {
                    self.currentUser = session.user
                    print("Token refreshed for user: \(session.user.id)")
                }
            default:
                break
            }
        }
    }

    // MARK: - Auth Methods (Placeholders for future implementation)

    // These methods will be implemented when you're ready to add auth logic to your views

    @MainActor func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        print("Signed in user: \(session.user.id)")
    }

    @MainActor func signUpWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)
        print("Signed up user: \(session.user.id)")
    }

    @MainActor func signOut() async throws {
        try await client.auth.signOut()
        print("User signed out")
    }

    @MainActor func signInWithApple() async throws {
        // Apple Sign-In implementation will go here
        // This requires additional setup with Sign in with Apple
        throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In not yet implemented"])
    }
}
