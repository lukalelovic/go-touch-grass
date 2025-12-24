//
//  ContentView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/21/25.

import SwiftUI

struct ContentView: View {
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
        .tint(Color(red: 0.0, green: 0.5, blue: 0.0))
    }
}

// MARK: - Feed Tab
struct FeedTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.9, green: 0.98, blue: 0.9)
                    .ignoresSafeArea()
                Text("Feed")
            }
            .navigationTitle("Feed")
        }
    }
}

// MARK: - Log Activity Tab
struct LogActivityTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.9, green: 0.98, blue: 0.9)
                    .ignoresSafeArea()
                Text("Log Activity")
            }
            .navigationTitle("Log Activity")
        }
    }
}

// MARK: - Profile Tab
struct ProfileTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.9, green: 0.98, blue: 0.9)
                    .ignoresSafeArea()
                Text("Profile")
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
}
