//
//  TouchGrassActivityAttributes.swift
//  Go Touch Grass
//
//  Shared attributes for Live Activities
//  This file must be included in both the main app and widget extension targets
//

import ActivityKit
import Foundation

struct TouchGrassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var activityType: String
        var prompt: String
        var isCompleted: Bool
        var completedAt: Date?
    }

    var recommendationId: String
    var icon: String
    var duration: Int?
}
