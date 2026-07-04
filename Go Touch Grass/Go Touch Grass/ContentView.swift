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
    @State private var selectedTab = 0

    var body: some View {
        let colors = AppColors()
        let _ = print("🎨 ContentView body evaluated, isAuthenticated: \(supabaseManager.isAuthenticated)")

        ZStack {
            // Nature-inspired background
            NatureBackgroundView()
            
            Group {
                if isCheckingAuth {
                    // Enhanced loading state
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(colors.accent)
                        
                        Text("Loading...")
                            .font(.grassCaption)
                            .foregroundStyle(colors.secondaryText)
                    }
                } else if supabaseManager.isAuthenticated {
                    let _ = print("✅ Showing Custom TabView")
                    
                    VStack(spacing: 0) {
                        // Content area
                        ZStack {
                            if selectedTab == 0 {
                                FeedTab()
                            } else if selectedTab == 1 {
                                TouchGrassTab()
                            } else if selectedTab == 2 {
                                ShareTab()
                            } else {
                                ProfileTab()
                            }
                        }
                        
                        // Custom Tab Bar
                        HStack(spacing: 0) {
                            CustomTabButton(
                                icon: "arrow.up.right",
                                label: "Feed",
                                isSelected: selectedTab == 0,
                                colors: colors
                            ) {
                                selectedTab = 0
                            }
                            
                            CustomTabButton(
                                icon: "leaf.fill",
                                label: "Touch Grass",
                                isSelected: selectedTab == 1,
                                colors: colors
                            ) {
                                selectedTab = 1
                            }
                            
                            CustomTabButton(
                                icon: "plus.circle.fill",
                                label: "Share",
                                isSelected: selectedTab == 2,
                                colors: colors
                            ) {
                                selectedTab = 2
                            }
                            
                            CustomTabButton(
                                icon: "person.fill",
                                label: "Profile",
                                isSelected: selectedTab == 3,
                                colors: colors
                            ) {
                                selectedTab = 3
                            }
                        }
                        .padding(.top, AppSpacing.xxs)
                        .padding(.bottom, AppSpacing.xs)
                        .background {
                            // Static dark green background
                            Color(red: 0.11, green: 0.22, blue: 0.18)
                                .opacity(0.95)
                                .ignoresSafeArea(edges: .bottom)
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    let _ = print("❌ Showing AuthView")
                    AuthView()
                }
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
}

// MARK: - Custom Tab Button

struct CustomTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? colors.accent : Color.white.opacity(0.6))
                
                Text(label)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(isSelected ? colors.accent : Color.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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
