//
//  ContentView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/21/25.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var isCheckingAuth = true

    var body: some View {
        let colors = AppColors()
        let _ = print("🎨 ContentView body evaluated, isAuthenticated: \(supabaseManager.isAuthenticated)")

        Group {
            if isCheckingAuth {
                // Show loading state while checking authentication
                ZStack {
                    colors.primaryBackground.ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(colors.accent)
                }
            } else if supabaseManager.isAuthenticated {
                let _ = print("✅ Showing TabView")
                TabView {
                    FeedTab()
                        .tabItem {
                            Label("Feed", systemImage: "arrow.up.right")
                        }

                    TouchGrassTab()
                        .tabItem {
                            Label("Touch Grass", systemImage: "leaf.fill")
                        }

                    ShareTab()
                        .tabItem {
                            Label("Share", systemImage: "plus.circle.fill")
                        }

                    ProfileTab()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
                .tint(.white.opacity(0.9))
                .onAppear {
                    updateTabBarAppearance()
                }
            } else {
                let _ = print("❌ Showing AuthView")
                AuthView()
            }
        }
        .onAppear {
            // Give the auth state listener a moment to check for session
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    isCheckingAuth = false
                }
            }
        }
        .onChange(of: supabaseManager.isAuthenticated) { oldValue, newValue in
            if oldValue != newValue {
                // Reset checking state when auth changes
                isCheckingAuth = false
            }
        }
    }

    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.169, green: 0.341, blue: 0.282, alpha: 1.0) // #2B5748

        // Configure item appearance for all states
        let itemAppearance = UITabBarItemAppearance()
        
        // Selected state - white with high opacity
        itemAppearance.selected.iconColor = UIColor.white.withAlphaComponent(0.9)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.9)]
        
        // Normal/unselected state - white with low opacity
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        
        // Apply to all layout types
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Override the tint color to prevent blue selection
        UITabBar.appearance().tintColor = UIColor.white.withAlphaComponent(0.9)
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.4)

        // Force update of all existing tab bars
        UIApplication.shared.windows.forEach { window in
            window.allSubviews.compactMap { $0 as? UITabBar }.forEach { tabBar in
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
                tabBar.tintColor = UIColor.white.withAlphaComponent(0.9)
                tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.4)
            }
        }
    }
}

extension UIView {
    var allSubviews: [UIView] {
        subviews + subviews.flatMap { $0.allSubviews }
    }
}

#Preview {
    ContentView()
        .environmentObject(SupabaseManager.shared)
        .environmentObject(ThemeManager.shared)
}
