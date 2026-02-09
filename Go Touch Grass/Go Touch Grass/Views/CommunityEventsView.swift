//
//  CommunityEventsView.swift
//  Go Touch Grass
//
//  View for browsing nearby user-generated community events
//

import SwiftUI
import CoreLocation

struct CommunityEventsView: View {
    private let userEventService = UserEventService.shared
    private let locationManager = LocationManager.shared
    @State private var nearbyEvents: [UserEvent] = []
    @State private var myCreatedEvents: [UserEvent] = []
    @State private var myJoinedEvents: [UserEvent] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var showingCreateEvent = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Events", selection: $selectedTab) {
                    Text("Nearby").tag(0)
                    Text("My Events").tag(1)
                    Text("Joined").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                Group {
                    if isLoading {
                        ProgressView("Loading events...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        switch selectedTab {
                        case 0:
                            nearbyEventsView
                        case 1:
                            myEventsView
                        case 2:
                            joinedEventsView
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle("Community Events")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView()
                    .onDisappear {
                        Task {
                            await loadEvents()
                        }
                    }
            }
            .task {
                await loadEvents()
            }
            .refreshable {
                await loadEvents()
            }
        }
    }

    // MARK: - Nearby Events View

    private var nearbyEventsView: some View {
        Group {
            if nearbyEvents.isEmpty {
                ContentUnavailableView(
                    "No Events Nearby",
                    systemImage: "map",
                    description: Text("There are no community events in your area yet. Be the first to create one!")
                )
            } else {
                List(nearbyEvents) { event in
                    NavigationLink {
                        UserEventDetailView(event: event)
                    } label: {
                        UserEventRow(event: event)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - My Events View

    private var myEventsView: some View {
        Group {
            if myCreatedEvents.isEmpty {
                ContentUnavailableView(
                    "No Events Created",
                    systemImage: "calendar.badge.plus",
                    description: Text("You haven't created any community events yet. Tap + to create your first event!")
                )
            } else {
                List(myCreatedEvents) { event in
                    NavigationLink {
                        UserEventDetailView(event: event, isCreator: true)
                    } label: {
                        UserEventRow(event: event, showStatus: true)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Joined Events View

    private var joinedEventsView: some View {
        Group {
            if myJoinedEvents.isEmpty {
                ContentUnavailableView(
                    "No Events Joined",
                    systemImage: "person.2",
                    description: Text("You haven't joined any community events yet. Browse nearby events to find activities!")
                )
            } else {
                List(myJoinedEvents) { event in
                    NavigationLink {
                        UserEventDetailView(event: event)
                    } label: {
                        UserEventRow(event: event)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadEvents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let nearby = loadNearbyEvents()
            async let created = userEventService.fetchMyCreatedEvents()
            async let joined = userEventService.fetchMyJoinedEvents()

            (nearbyEvents, myCreatedEvents, myJoinedEvents) = try await (nearby, created, joined)
        } catch {
            print("Error loading events: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    private func loadNearbyEvents() async throws -> [UserEvent] {
        guard let location = locationManager.currentLocation else {
            return []
        }

        return try await userEventService.fetchNearbyPublicEvents(location: location, radius: 50)
    }
}

// MARK: - User Event Row

struct UserEventRow: View {
    let event: UserEvent
    var showStatus: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Event name
            Text(event.name)
                .font(.headline)

            // Date
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Location
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(event.city)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let venue = event.venueName {
                    Text("• \(venue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Status badges
            HStack(spacing: 8) {
                if event.isFree {
                    EventBadge(text: "Free", color: .green)
                }

                if event.visibility == .private {
                    EventBadge(text: "Private", color: .orange)
                }

                if showStatus && event.isCancelled {
                    EventBadge(text: "Cancelled", color: .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Event Badge Component

struct EventBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

#Preview {
    CommunityEventsView()
}
