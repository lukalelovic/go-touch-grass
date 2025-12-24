//
//  ActivityRowView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
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
