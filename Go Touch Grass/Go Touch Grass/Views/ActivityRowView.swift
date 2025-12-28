//
//  ActivityRowView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI
import MapKit

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Tappable user profile section
                NavigationLink(destination: UserProfileView(user: activity.user, isCurrentUser: false)) {
                    HStack(spacing: 12) {
                        // Profile picture
                        ProfilePictureView(
                            profilePictureUrl: activity.user.profilePictureUrl,
                            size: 44
                        )

                        // User info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.user.username)
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack(spacing: 4) {
                                Image(systemName: activity.activityType.icon)
                                    .font(.caption)
                                Text(activity.activityType.rawValue)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Timestamp
                Text(timeAgoString(from: activity.timestamp))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            // Notes preview
            if let notes = activity.notes {
                Text(notes)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.white)
            }

            // Map preview
            if let location = activity.location {
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))) {
                    Marker("", coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                    .tint(.green)
                }
                .frame(height: 120)
                .cornerRadius(8)
                .allowsHitTesting(false)
            }

            // Location
            if let location = activity.location, let name = location.name {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(name)
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(12)
        .background(Color(red: 0.2, green: 0.3, blue: 0.2))
        .cornerRadius(12)
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            let minutes = Int(interval / 60)
            return "\(max(1, minutes))m ago"
        }
    }
}
