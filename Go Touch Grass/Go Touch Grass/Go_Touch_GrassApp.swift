//
//  Go_Touch_GrassApp.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/21/25.
//

import SwiftUI

@main
struct Go_Touch_GrassApp: App {
    @State private var showLanding = true

    private let supabaseManager = SupabaseManager.shared
    private let themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            if showLanding {
                LandingAnimationView {
                    showLanding = false
                }
            } else {
                ContentView()
                    .environmentObject(supabaseManager)
                    .environmentObject(themeManager)
            }
        }
    }
}
