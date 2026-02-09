//
//  UserEventDetailView.swift
//  Go Touch Grass
//
//  Detail view for a user-generated community event
//

import SwiftUI
import MapKit

struct UserEventDetailView: View {
    let event: UserEvent
    var isCreator: Bool = false

    private let userEventService = UserEventService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var hasJoined = false
    @State private var attendeeCount = 0
    @State private var isLoading = false
    @State private var showingCancelDialog = false
    @State private var showingJoinOptions = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    // Event Name
                    Text(event.name)
                        .font(.title)
                        .fontWeight(.bold)

                    // Status badges
                    HStack(spacing: 8) {
                        if event.isFree {
                            StatusBadge(text: "Free", color: .green, icon: "dollarsign.circle.fill")
                        } else if let price = event.price {
                            StatusBadge(text: "$\(String(format: "%.2f", price))", color: .blue, icon: "dollarsign.circle.fill")
                        }

                        StatusBadge(
                            text: event.visibility == .public ? "Public" : "Private",
                            color: event.visibility == .public ? .blue : .orange,
                            icon: event.visibility == .public ? "globe" : "lock.fill"
                        )

                        if event.isCancelled {
                            StatusBadge(text: "Cancelled", color: .red, icon: "xmark.circle.fill")
                        }
                    }

                    Divider()

                    // Date & Time
                    InfoRow(icon: "calendar", title: "Date & Time") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.startDate.formatted(date: .long, time: .shortened))
                            if let endDate = event.endDate {
                                Text("to \(endDate.formatted(date: .abbreviated, time: .shortened))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Location
                    InfoRow(icon: "location.fill", title: "Location") {
                        VStack(alignment: .leading, spacing: 4) {
                            if let venue = event.venueName {
                                Text(venue)
                                    .fontWeight(.medium)
                            }
                            if let address = event.fullAddress {
                                Text(address)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [event]) { event in
                        MapMarker(coordinate: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude), tint: .red)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .allowsHitTesting(false)

                    Divider()

                    // Description
                    InfoRow(icon: "text.alignleft", title: "Description") {
                        Text(event.description)
                    }

                    // Attendees
                    if event.visibility == .public {
                        Divider()

                        InfoRow(icon: "person.2.fill", title: "Attendees") {
                            HStack {
                                Text("\(attendeeCount) going")
                                if let maxAttendees = event.maxAttendees {
                                    Text("/ \(maxAttendees) max")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Requirements
                    if let requirements = event.requirements {
                        Divider()

                        InfoRow(icon: "checkmark.circle.fill", title: "Requirements") {
                            Text(requirements)
                        }
                    }

                    // Event URL
                    if let eventUrl = event.eventUrl, let url = URL(string: eventUrl) {
                        Divider()

                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link")
                                Text("Event Website")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                    }

                    // Cancellation info
                    if event.isCancelled, let reason = event.cancellationReason {
                        Divider()

                        InfoRow(icon: "exclamationmark.triangle.fill", title: "Cancellation Reason") {
                            Text(reason)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCreator && !event.isCancelled {
                ToolbarItem(placement: .primaryAction) {
                    Button("Cancel Event", role: .destructive) {
                        showingCancelDialog = true
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !isCreator && !event.isCancelled && event.isUpcoming {
                actionButton
                    .padding()
                    .background(.ultraThinMaterial)
            }
        }
        .task {
            await loadEventDetails()
        }
        .alert("Cancel Event", isPresented: $showingCancelDialog) {
            TextField("Reason (optional)", text: Binding(
                get: { errorMessage ?? "" },
                set: { errorMessage = $0 }
            ))
            Button("Cancel Event", role: .destructive) {
                Task {
                    await cancelEvent()
                }
            }
            Button("Nevermind", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this event? All attendees will be notified.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            Task {
                if hasJoined {
                    await leaveEvent()
                } else {
                    await joinEvent()
                }
            }
        } label: {
            HStack {
                Image(systemName: hasJoined ? "xmark.circle.fill" : "checkmark.circle.fill")
                Text(hasJoined ? "Leave Event" : "Join Event")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasJoined ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }

    // MARK: - Helper Methods

    private func loadEventDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let joined = userEventService.hasJoinedEvent(eventId: event.id)
            async let count = userEventService.getAttendeeCount(eventId: event.id)

            (hasJoined, attendeeCount) = try await (joined, count)
        } catch {
            print("Error loading event details: \(error)")
        }
    }

    private func joinEvent() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await userEventService.joinEvent(eventId: event.id, status: .going)
            hasJoined = true
            attendeeCount += 1
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func leaveEvent() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await userEventService.leaveEvent(eventId: event.id)
            hasJoined = false
            attendeeCount -= 1
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func cancelEvent() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await userEventService.cancelEvent(eventId: event.id, reason: errorMessage)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Info Row Component

struct InfoRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                content
            }
        }
    }
}

// MARK: - Status Badge Component

struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        UserEventDetailView(event: UserEvent(
            id: UUID(),
            creatorId: UUID(),
            visibility: .public,
            name: "Morning Trail Run",
            description: "Join us for a casual 5k trail run through the local park. All paces welcome!",
            eventUrl: nil,
            startDate: Date().addingTimeInterval(86400),
            endDate: nil,
            timezone: "America/Los_Angeles",
            venueName: "Golden Gate Park",
            venueAddress: "501 Stanyan St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            postalCode: "94117",
            latitude: 37.7694,
            longitude: -122.4862,
            activityTypeId: 1,
            maxAttendees: 15,
            requirements: "Bring water and comfortable running shoes",
            price: nil,
            currency: "USD",
            isFree: true,
            isCancelled: false,
            cancelledAt: nil,
            cancellationReason: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
