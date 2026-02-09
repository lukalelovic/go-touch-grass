//
//  ContentView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/21/25.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    var body: some View {
        let colors = AppColors(isDarkMode: themeManager.isDarkMode)
        let _ = print("🎨 ContentView body evaluated, isAuthenticated: \(supabaseManager.isAuthenticated)")

        Group {
            if supabaseManager.isAuthenticated {
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
                .tint(colors.accent)
                .onAppear {
                    updateTabBarAppearance(isDarkMode: themeManager.isDarkMode)
                }
                .onChange(of: themeManager.isDarkMode) { _, isDarkMode in
                    updateTabBarAppearance(isDarkMode: isDarkMode)
                }
            } else {
                let _ = print("❌ Showing AuthView")
                AuthView()
            }
        }
    }

    private func updateTabBarAppearance(isDarkMode: Bool) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        if isDarkMode {
            appearance.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        } else {
            appearance.backgroundColor = UIColor(red: 0.85, green: 0.93, blue: 0.85, alpha: 1.0)
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Force update of all existing tab bars
        UIApplication.shared.windows.forEach { window in
            window.allSubviews.compactMap { $0 as? UITabBar }.forEach { tabBar in
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
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
