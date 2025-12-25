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

            TouchGrassTab()
                .tabItem {
                    Label("Touch Grass", systemImage: "plus.circle.fill")
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
