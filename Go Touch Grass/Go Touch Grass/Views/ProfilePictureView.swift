//
//  ProfilePictureView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/28/25.
//

import SwiftUI

struct ProfilePictureView: View {
    let profilePictureUrl: String?
    let size: CGFloat
    @State private var imageKey = UUID()

    init(profilePictureUrl: String?, size: CGFloat = 40) {
        self.profilePictureUrl = profilePictureUrl
        self.size = size
    }

    var body: some View {
        Group {
            if let urlString = profilePictureUrl, !urlString.isEmpty {
                // Check if it's a URL or SF Symbol name
                if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                    // Remote image from Supabase Storage
                    // Add cache busting timestamp to force refresh
                    let urlWithTimestamp = urlString + "?t=\(Date().timeIntervalSince1970)"
                    AsyncImage(url: URL(string: urlWithTimestamp)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: size, height: size)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size, height: size)
                                .clipShape(Circle())
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    // SF Symbol placeholder (for local dev/sample data)
                    Image(systemName: urlString)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.2))
                }
            } else {
                // No URL or empty string - show placeholder
                placeholderImage
            }
        }
        .id("\(profilePictureUrl ?? "placeholder")-\(imageKey.uuidString)")
        .onChange(of: profilePictureUrl) { _, _ in
            // Force AsyncImage to reload when URL changes
            imageKey = UUID()
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(.gray)
    }
}
