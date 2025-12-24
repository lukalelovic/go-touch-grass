//
//  LogActivityTab.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct LogActivityTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.85, green: 0.93, blue: 0.85)
                    .ignoresSafeArea()
                Text("Log Activity")
            }
            .navigationTitle("Log Activity")
        }
    }
}
