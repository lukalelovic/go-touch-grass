//
//  Go_Touch_GrassApp.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/21/25.
//

import SwiftUI

@main
struct Go_Touch_GrassApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseManager)
                .environmentObject(themeManager)
        }
    }
}
