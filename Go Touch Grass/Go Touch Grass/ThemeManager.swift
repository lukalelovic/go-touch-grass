//
//  ThemeManager.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 1/17/26.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true // Always dark mode

    static let shared = ThemeManager()

    private init() {
        // Always use dark mode
        self.isDarkMode = true
    }
}

struct AppColors {
    let isDarkMode: Bool

    // Background colors - always dark mode
    var primaryBackground: Color {
        Color(red: 0.169, green: 0.341, blue: 0.282) // #2B5748 - Main earthy dark green
    }

    var cardBackground: Color {
        Color(red: 0.14, green: 0.28, blue: 0.23) // Darker for better contrast
    }

    var secondaryCardBackground: Color {
        Color(red: 0.12, green: 0.24, blue: 0.20) // Even darker for secondary cards
    }

    var eventCardBackground: Color {
        Color(red: 0.16, green: 0.32, blue: 0.26) // Slightly lighter than cardBackground
    }

    // Text colors - always dark mode
    var primaryText: Color {
        .white
    }

    var secondaryText: Color {
        Color.white.opacity(0.7)
    }

    var tertiaryText: Color {
        Color.white.opacity(0.5)
    }

    // Accent colors (vibrant green for contrast)
    var accent: Color {
        Color(red: 0.4, green: 0.8, blue: 0.4) // Brighter green for better visibility
    }

    var accentDark: Color {
        Color(red: 0.35, green: 0.7, blue: 0.35)
    }

    var accentLight: Color {
        Color(red: 0.5, green: 0.85, blue: 0.5)
    }

    // Special colors
    var divider: Color {
        Color.white.opacity(0.2)
    }

    init(isDarkMode: Bool = true) {
        self.isDarkMode = true // Always dark mode
    }
}

extension View {
    func themedColors(_ themeManager: ThemeManager) -> AppColors {
        AppColors(isDarkMode: themeManager.isDarkMode)
    }
}
