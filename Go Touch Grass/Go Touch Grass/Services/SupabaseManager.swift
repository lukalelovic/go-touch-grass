//
//  SupabaseManager.swift
//  Go Touch Grass
//
//  Supabase client manager singleton
//

import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private init() {
        // Initialize Supabase client with environment variables
        self.client = SupabaseClient(
            supabaseURL: URL(string: Environment.supabaseURL)!,
            supabaseKey: Environment.supabaseAnonKey
        )

        // Set up auth state listener
        Task {
            await setupAuthListener()
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthListener() async {
        for await state in client.auth.authStateChanges {
            switch state {
            case .signedIn(let session):
                self.isAuthenticated = true
                self.currentUser = session.user
                print("User signed in: \(session.user.id)")
            case .signedOut:
                self.isAuthenticated = false
                self.currentUser = nil
                print("User signed out")
            case .initialSession(let session):
                if let session = session {
                    self.isAuthenticated = true
                    self.currentUser = session.user
                    print("Initial session found: \(session.user.id)")
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    print("No initial session")
                }
            case .userUpdated(let session):
                self.currentUser = session.user
                print("User updated: \(session.user.id)")
            case .tokenRefreshed(let session):
                self.currentUser = session.user
                print("Token refreshed for user: \(session.user.id)")
            default:
                break
            }
        }
    }

    // MARK: - Auth Methods (Placeholders for future implementation)

    // These methods will be implemented when you're ready to add auth logic to your views

    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        print("Signed in user: \(session.user.id)")
    }

    func signUpWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)
        print("Signed up user: \(session.user.id)")
    }

    func signOut() async throws {
        try await client.auth.signOut()
        print("User signed out")
    }

    func signInWithApple() async throws {
        // Apple Sign-In implementation will go here
        // This requires additional setup with Sign in with Apple
        throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In not yet implemented"])
    }
}
