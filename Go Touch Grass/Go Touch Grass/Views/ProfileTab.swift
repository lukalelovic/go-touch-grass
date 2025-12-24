//
//  ProfileTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct ProfileTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.85, green: 0.93, blue: 0.85)
                    .ignoresSafeArea()
                Text("Profile")
            }
            .navigationTitle("Profile")
        }
    }
}
