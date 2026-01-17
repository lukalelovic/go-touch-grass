//
//  ThemeManager.swift
//  Go Touch Grass
//
//  Created by Luka Lelovic on 1/17/26.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false

    static let shared = ThemeManager()

    private init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }

    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}

struct AppColors {
    let isDarkMode: Bool

    // Background colors
    var primaryBackground: Color {
        isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color(red: 0.85, green: 0.93, blue: 0.85)
    }

    var cardBackground: Color {
        isDarkMode ? Color(red: 0.2, green: 0.3, blue: 0.2) : Color.white.opacity(0.5)
    }

    var secondaryCardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.25, blue: 0.15) : Color.white.opacity(0.3)
    }

    var eventCardBackground: Color {
        Color(red: 0.2, green: 0.3, blue: 0.2)
    }

    // Text colors
    var primaryText: Color {
        isDarkMode ? .white : .primary
    }

    var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.7) : .secondary
    }

    var tertiaryText: Color {
        isDarkMode ? Color.white.opacity(0.5) : .secondary
    }

    // Accent colors (keep green)
    var accent: Color {
        Color(red: 0.1, green: 0.6, blue: 0.1)
    }

    var accentDark: Color {
        Color(red: 0.2, green: 0.5, blue: 0.2)
    }

    var accentLight: Color {
        Color(red: 0.3, green: 0.7, blue: 0.3)
    }

    // Special colors
    var divider: Color {
        isDarkMode ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }

    init(isDarkMode: Bool) {
        self.isDarkMode = isDarkMode
    }
}

extension View {
    func themedColors(_ themeManager: ThemeManager) -> AppColors {
        AppColors(isDarkMode: themeManager.isDarkMode)
    }
}
