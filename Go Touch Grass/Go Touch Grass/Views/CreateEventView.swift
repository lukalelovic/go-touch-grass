//
//  CreateEventView.swift
//  Go Touch Grass
//
//  View for creating user-generated community events
//

import SwiftUI
import MapKit

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    private let userEventService = UserEventService.shared
    private let locationManager = LocationManager.shared

    // Event details
    @State private var eventName = ""
    @State private var eventDescription = ""

    // Date/Time
    @State private var startDate = Date().addingTimeInterval(3600) // Default to 1 hour from now
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(7200) // Default to 2 hours from now

    // Location
    @State private var venueName = ""
    @State private var venueAddress = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var selectedLocation: Location?
    @State private var showingLocationPicker = false

    // Settings
    @State private var activityTypeId = 1 // Default to first activity type
    @State private var visibility: EventVisibility = .public
    @State private var isFree = true
    @State private var price: String = ""
    @State private var maxAttendees: String = ""
    @State private var requirements = ""

    // UI State
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section("Event Details") {
                    TextField("Event Name", text: $eventName)
                        .autocorrectionDisabled()

                    ZStack(alignment: .topLeading) {
                        if eventDescription.isEmpty {
                            Text("Description")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }

                        TextEditor(text: $eventDescription)
                            .frame(minHeight: 100)
                    }
                }

                // Date/Time Section
                Section("Date & Time") {
                    DatePicker("Start Date", selection: $startDate, in: Date()...)

                    Toggle("Add End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate...)
                    }
                }

                // Location Section
                Section("Location") {
                    TextField("Venue Name", text: $venueName)
                    TextField("Address", text: $venueAddress)

                    HStack {
                        TextField("City", text: $city)
                        TextField("State", text: $state)
                            .frame(width: 60)
                    }

                    TextField("Postal Code", text: $postalCode)
                        .keyboardType(.numberPad)

                    Button(action: {
                        showingLocationPicker = true
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            if let location = selectedLocation {
                                Text(location.name ?? "Selected Location")
                            } else {
                                Text("Pick Location on Map")
                            }
                        }
                    }
                }

                // Activity Type Section
                Section("Activity Type") {
                    Picker("Activity", selection: $activityTypeId) {
                        Text("Running").tag(1)
                        Text("Walking").tag(2)
                        Text("Hiking").tag(3)
                        Text("Biking").tag(4)
                        Text("Kayaking").tag(5)
                        Text("Climbing").tag(6)
                        Text("Swimming").tag(7)
                        Text("Other").tag(8)
                    }
                }

                // Settings Section
                Section("Settings") {
                    Picker("Visibility", selection: $visibility) {
                        Text("Public").tag(EventVisibility.public)
                        Text("Private").tag(EventVisibility.private)
                    }

                    Toggle("Free Event", isOn: $isFree)

                    if !isFree {
                        TextField("Price ($)", text: $price)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Max Attendees (optional)", text: $maxAttendees)
                        .keyboardType(.numberPad)

                    TextField("Requirements (optional)", text: $requirements)
                }
            }
            .navigationTitle("Start Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        Task {
                            await createEvent()
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
                    .onDisappear {
                        if let location = selectedLocation {
                            city = location.name ?? ""
                            // Note: The existing LocationPickerView uses Location model
                            // which doesn't have separate city/state fields
                        }
                    }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCreating {
                    ProgressView("Starting event...")
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !eventName.isEmpty &&
        !eventDescription.isEmpty &&
        !city.isEmpty &&
        selectedLocation != nil
    }

    private func createEvent() async {
        guard let location = selectedLocation else {
            errorMessage = "Please select a location on the map"
            showingError = true
            return
        }

        isCreating = true

        do {
            let priceValue: Double? = isFree ? nil : Double(price)
            let maxAttendeesValue: Int? = maxAttendees.isEmpty ? nil : Int(maxAttendees)

            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)

            let event = try await userEventService.createEvent(
                name: eventName,
                description: eventDescription,
                eventUrl: nil,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                location: coordinate,
                city: city.isEmpty ? (location.name ?? "Unknown") : city,
                state: state.isEmpty ? nil : state,
                country: "USA",
                venueName: venueName.isEmpty ? nil : venueName,
                venueAddress: venueAddress.isEmpty ? nil : venueAddress,
                postalCode: postalCode.isEmpty ? nil : postalCode,
                activityTypeId: activityTypeId,
                visibility: visibility,
                maxAttendees: maxAttendeesValue,
                requirements: requirements.isEmpty ? nil : requirements,
                price: priceValue,
                isFree: isFree
            )

            print("Successfully created event: \(event.id)")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            isCreating = false
        }
    }
}


#Preview {
    CreateEventView()
}
