//
//  TouchGrassWidget.swift
//  Go Touch Grass
//
//  Home Screen and Lock Screen Widget
//

import WidgetKit
import SwiftUI

struct TouchGrassWidget: Widget {
    let kind: String = "TouchGrassWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActivityProvider()) { entry in
            TouchGrassWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Activity")
        .description("See your recommended outdoor activity for today")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Timeline Provider

struct ActivityProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActivityEntry {
        ActivityEntry(
            date: Date(),
            activityType: "Hiking",
            prompt: "Take a 30-minute hike in nature",
            icon: "figure.hiking",
            duration: 30,
            isCompleted: false,
            completedAt: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ActivityEntry) -> ()) {
        let entry = ActivityEntry(
            date: Date(),
            activityType: "Walking",
            prompt: "Take a mindful walk around your neighborhood",
            icon: "figure.walk",
            duration: 20,
            isCompleted: false,
            completedAt: nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            // Fetch today's recommendation from shared data or Supabase
            let entry = await fetchTodaysActivity()

            // Update timeline every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchTodaysActivity() async -> ActivityEntry {
        // Try to get data from App Group shared storage
        if let sharedDefaults = UserDefaults(suiteName: "group.com.touchgrass.app") {
            let activityType = sharedDefaults.string(forKey: "todayActivityType") ?? "Walking"
            let prompt = sharedDefaults.string(forKey: "todayPrompt") ?? "Touch some grass today"
            let icon = sharedDefaults.string(forKey: "todayIcon") ?? "leaf.fill"
            let duration = sharedDefaults.integer(forKey: "todayDuration")
            let isCompleted = sharedDefaults.bool(forKey: "todayCompleted")
            let completedTimestamp = sharedDefaults.double(forKey: "todayCompletedAt")

            let completedAt = completedTimestamp > 0 ? Date(timeIntervalSince1970: completedTimestamp) : nil

            return ActivityEntry(
                date: Date(),
                activityType: activityType,
                prompt: prompt,
                icon: icon,
                duration: duration > 0 ? duration : nil,
                isCompleted: isCompleted,
                completedAt: completedAt
            )
        }

        // Fallback
        return ActivityEntry(
            date: Date(),
            activityType: "Walking",
            prompt: "Open the app to see your activity",
            icon: "leaf.fill",
            duration: 20,
            isCompleted: false,
            completedAt: nil
        )
    }
}

// MARK: - Timeline Entry

struct ActivityEntry: TimelineEntry {
    let date: Date
    let activityType: String
    let prompt: String
    let icon: String
    let duration: Int?
    let isCompleted: Bool
    let completedAt: Date?
}

// MARK: - Widget Views

struct TouchGrassWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ActivityProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .systemMedium:
            MediumWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        default:
            SmallWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
    }
}

// MARK: - Small Widget (Home Screen)

struct SmallWidgetView: View {
    let entry: ActivityEntry

    var accentColor: Color {
        Color(red: 0.55, green: 0.78, blue: 0.35) // App's accent warm green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.icon)
                    .font(.title2)
                    .foregroundColor(accentColor)

                Spacer()

                if entry.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            Text(entry.activityType)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            if let duration = entry.duration {
                Text("\(duration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget (Home Screen)

struct MediumWidgetView: View {
    let entry: ActivityEntry

    var accentColor: Color {
        Color(red: 0.55, green: 0.78, blue: 0.35) // App's accent warm green
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: entry.icon)
                    .font(.system(size: 30))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                if entry.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }

                Text(entry.activityType)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(entry.prompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if let duration = entry.duration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(duration) minutes")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Lock Screen Widgets

struct LockScreenRectangularView: View {
    let entry: ActivityEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: entry.icon)
                    .font(.caption)
                Text(entry.activityType)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if entry.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Text(entry.prompt)
                .font(.caption2)
                .lineLimit(2)
                .opacity(0.8)

            if let duration = entry.duration, !entry.isCompleted {
                Text("\(duration) min")
                    .font(.caption2)
                    .opacity(0.7)
            }

            if entry.isCompleted, let completedAt = entry.completedAt {
                Text("Completed at \(completedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}

struct LockScreenCircularView: View {
    let entry: ActivityEntry

    var body: some View {
        ZStack {
            if entry.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Image(systemName: entry.icon)
                    .font(.title3)
            }
        }
    }
}

// Preview
#Preview(as: .systemSmall) {
    TouchGrassWidget()
} timeline: {
    ActivityEntry(
        date: Date(),
        activityType: "Hiking",
        prompt: "Take a scenic hike in the mountains",
        icon: "figure.hiking",
        duration: 45,
        isCompleted: false,
        completedAt: nil
    )
    ActivityEntry(
        date: Date(),
        activityType: "Hiking",
        prompt: "Take a scenic hike in the mountains",
        icon: "figure.hiking",
        duration: 45,
        isCompleted: true,
        completedAt: Date()
    )
}
