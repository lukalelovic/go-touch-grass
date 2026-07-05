//
//  TouchGrassLiveActivity.swift
//  Go Touch Grass
//
//  Live Activity for Lock Screen and Dynamic Island
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

struct TouchGrassLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TouchGrassActivityAttributes.self) { context in
            // Lock Screen View
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded - Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.attributes.icon)
                            .font(.title2)
                            .foregroundColor(AppColors(isDarkMode: true).accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.activityType)
                                .font(.headline)
                                .fontWeight(.semibold)

                            if let duration = context.attributes.duration {
                                Text("\(duration) min")
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                        }
                    }
                }

                // Expanded - Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    } else {
                        EmptyView()
                    }
                }

                // Expanded - Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.state.prompt)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if !context.state.isCompleted {
                            Text("Tap 'Touch Grass' in the app to complete")
                                .font(.caption)
                                .opacity(0.6)
                        } else if let completedAt = context.state.completedAt {
                            Text("Completed at \(completedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact leading (left side of notch)
                Image(systemName: context.state.isCompleted ? "checkmark.circle.fill" : context.attributes.icon)
                    .foregroundColor(context.state.isCompleted ? .green : AppColors(isDarkMode: true).accent)
            } compactTrailing: {
                // Compact trailing (right side of notch)
                if !context.state.isCompleted {
                    if let duration = context.attributes.duration {
                        Text("\(duration)m")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                } else {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            } minimal: {
                // Minimal view (when multiple Live Activities are active)
                Image(systemName: context.state.isCompleted ? "checkmark.circle.fill" : context.attributes.icon)
                    .foregroundColor(context.state.isCompleted ? .green : AppColors(isDarkMode: true).accent)
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TouchGrassActivityAttributes>
    let colors = AppColors(isDarkMode: true)

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(colors.accent.opacity(0.2))
                    .frame(width: 50, height: 50)

                if context.state.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: context.attributes.icon)
                        .font(.title3)
                        .foregroundColor(colors.accent)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(context.state.activityType)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    if let duration = context.attributes.duration, !context.state.isCompleted {
                        Text("\(duration) min")
                            .font(.caption)
                            .opacity(0.7)
                    }
                }

                Text(context.state.prompt)
                    .font(.caption)
                    .lineLimit(2)
                    .opacity(0.8)

                if context.state.isCompleted, let completedAt = context.state.completedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Completed at \(completedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }

            Spacer()
        }
        .padding()
        .activityBackgroundTint(colors.cardBackground.opacity(0.8))
    }
}

// Preview
#Preview("Live Activity", as: .content, using: TouchGrassActivityAttributes(
    recommendationId: "test-id",
    icon: "figure.hiking",
    duration: 30
)) {
    TouchGrassLiveActivity()
} contentStates: {
    TouchGrassActivityAttributes.ContentState(
        activityType: "Hiking",
        prompt: "Take a scenic hike in the mountains",
        isCompleted: false,
        completedAt: nil
    )
    TouchGrassActivityAttributes.ContentState(
        activityType: "Hiking",
        prompt: "Take a scenic hike in the mountains",
        isCompleted: true,
        completedAt: Date()
    )
}
