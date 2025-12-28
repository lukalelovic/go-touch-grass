//
//  ActivityDetailView.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import SwiftUI
import MapKit

struct ActivityDetailView: View {
    let activity: Activity
    @State private var niceCount: Int = 0

    var body: some View {
        ZStack {
            Color(red: 0.85, green: 0.93, blue: 0.85)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        // User and activity info
                        HStack(spacing: 12) {
                            // Tappable user profile section
                            NavigationLink(destination: UserProfileView(user: activity.user, isCurrentUser: false)) {
                                HStack(spacing: 12) {
                                    // Profile picture
                                    ProfilePictureView(
                                        profilePictureUrl: activity.user.profilePictureUrl,
                                        size: 56
                                    )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activity.user.username)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)

                                        HStack(spacing: 6) {
                                            Image(systemName: activity.activityType.icon)
                                            Text(activity.activityType.rawValue)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Text(formatDate(activity.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Notes / description
                        if let notes = activity.notes {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                            }
                        }

                        // Map
                        if let location = activity.location {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location")
                                    .font(.headline)

                                Map(position: .constant(MapCameraPosition.region(
                                    MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(
                                            latitude: location.latitude,
                                            longitude: location.longitude
                                        ),
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    )
                                ))) {
                                    Marker(location.name ?? "Activity Location", coordinate: CLLocationCoordinate2D(
                                        latitude: location.latitude,
                                        longitude: location.longitude
                                    ))
                                }
                                .frame(height: 200)
                                .cornerRadius(12)

                                if let locationName = location.name {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin.circle.fill")
                                        Text(locationName)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }

                        // "Nice" button
                        Button(action: {
                            niceCount += 1
                        }) {
                            HStack {
                                Image(systemName: niceCount > 0 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                Text("Nice")
                                if niceCount > 0 {
                                    Text("(\(niceCount))")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.0, green: 0.5, blue: 0.0))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
