//
//  ActivityType.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation

// MARK: - Activity Type (Database Model)
struct ActivityType: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let icon: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case createdAt = "created_at"
    }

    init(id: Int, name: String, icon: String?, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }

    // Use default equality and hashing based on all properties
    // This is safer for SwiftUI's ForEach and prevents hash collisions
}

// MARK: - Legacy Support (for backward compatibility with old enum-based code)
extension ActivityType {
    // Legacy rawValue property for compatibility
    var rawValue: String {
        return name
    }

    // Legacy init for compatibility with old enum pattern
    init?(rawValue: String) {
        // This will be used during JSON decoding when we only have the name
        // We'll need to match it with actual database types later
        self.id = 0 // Placeholder, will be resolved when fetching from DB
        self.name = rawValue
        self.icon = ActivityType.fallbackIcon(for: rawValue)
        self.createdAt = nil
    }

    // Fallback icons for backward compatibility
    static func fallbackIcon(for name: String) -> String {
        switch name.lowercased() {
        case "hiking": return "figure.hiking"
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        case "climbing": return "figure.climbing"
        case "kayaking": return "figure.kayaking"
        case "camping": return "tent.fill"
        case "skiing": return "snowflake"
        case "surfing": return "water.waves"
        case "walking": return "figure.walk"
        case "coffee": return "cup.and.saucer.fill"
        case "other": return "figure.outdoor.cycle"
        default: return "leaf.fill"
        }
    }
}

// MARK: - Fallback (for when database is unavailable)
extension ActivityType {
    // Minimal fallback type when database fetch fails
    static let hiking = ActivityType(id: 1, name: "Hiking", icon: "figure.hiking")
}
