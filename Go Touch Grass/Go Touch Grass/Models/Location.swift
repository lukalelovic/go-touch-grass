//
//  Location.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 12/24/25.
//

import Foundation

// MARK: - Location
struct Location: Equatable, Codable, Identifiable {
    var id: String {
        "\(latitude),\(longitude)"
    }

    let latitude: Double
    let longitude: Double
    let name: String?
}
