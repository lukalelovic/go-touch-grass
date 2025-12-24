//
//  ContentView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/21/25.

import SwiftUI

struct ContentView: View {
    init() {
        // Configure tab bar appearance for opaque icons
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Active tab color (fully opaque green)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.1, green: 0.6, blue: 0.1, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.1, green: 0.6, blue: 0.1, alpha: 1.0)]

        // Inactive tab color (fully opaque gray)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            FeedTab()
                .tabItem {
                    Label("Feed", systemImage: "arrow.up.right")
                }

            LogActivityTab()
                .tabItem {
                    Label("Log Activity", systemImage: "plus.circle.fill")
                }

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color(red: 0.1, green: 0.6, blue: 0.1))
    }
}

#Preview {
    ContentView()
}
