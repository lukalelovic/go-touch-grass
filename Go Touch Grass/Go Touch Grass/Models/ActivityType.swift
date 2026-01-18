//
//  ActivityType.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation

// MARK: - Activity Type
enum ActivityType: String, CaseIterable, Codable {
    case hiking = "Hiking"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case climbing = "Climbing"
    case kayaking = "Kayaking"
    case camping = "Camping"
    case skiing = "Skiing"
    case surfing = "Surfing"
    case walking = "Walking"
    case coffee = "Coffee"
    case other = "Other"

    var icon: String {
        switch self {
        case .hiking: return "figure.hiking"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .climbing: return "figure.climbing"
        case .kayaking: return "kayak"
        case .camping: return "tent.fill"
        case .skiing: return "figure.skiing.downhill"
        case .surfing: return "surfboard"
        case .walking: return "figure.walk"
        case .coffee: return "cup.and.saucer.fill"
        case .other: return "leaf.fill"
        }
    }
}
