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

// MARK: - Enhanced Color System with Nature-Inspired Palette

struct AppColors {
    let isDarkMode: Bool

    // Background colors - Enhanced earthy dark green tones
    var primaryBackground: Color {
        Color(red: 0.11, green: 0.22, blue: 0.18) // #1C3830 - Deeper forest green
    }
    
    var secondaryBackground: Color {
        Color(red: 0.14, green: 0.26, blue: 0.21) // Slightly lighter forest
    }

    var cardBackground: Color {
        Color(red: 0.16, green: 0.30, blue: 0.25).opacity(0.6) // Semi-transparent for glass effect
    }

    var secondaryCardBackground: Color {
        Color(red: 0.14, green: 0.27, blue: 0.22).opacity(0.5)
    }

    var eventCardBackground: Color {
        Color(red: 0.18, green: 0.32, blue: 0.27).opacity(0.6)
    }

    // Text colors with better hierarchy
    var primaryText: Color {
        Color(red: 0.95, green: 0.97, blue: 0.95) // Soft white with slight green tint
    }

    var secondaryText: Color {
        Color(red: 0.85, green: 0.92, blue: 0.88).opacity(0.8) // Muted green-white
    }

    var tertiaryText: Color {
        Color(red: 0.7, green: 0.8, blue: 0.75).opacity(0.6)
    }

    // Nature-inspired accent colors
    var accent: Color {
        Color(red: 0.52, green: 0.85, blue: 0.64) // #84D9A0 - Fresh spring green
    }

    var accentDark: Color {
        Color(red: 0.42, green: 0.72, blue: 0.54) // Deeper spring green
    }

    var accentLight: Color {
        Color(red: 0.68, green: 0.92, blue: 0.76) // Light mint green
    }
    
    var accentGlow: Color {
        Color(red: 0.52, green: 0.85, blue: 0.64).opacity(0.3) // For glow effects
    }

    // Additional nature-inspired colors
    var sunshine: Color {
        Color(red: 0.98, green: 0.85, blue: 0.46) // Warm sunlight
    }
    
    var sky: Color {
        Color(red: 0.53, green: 0.75, blue: 0.88) // Soft sky blue
    }
    
    var earth: Color {
        Color(red: 0.62, green: 0.49, blue: 0.37) // Earthy brown
    }

    // Gradients for depth and visual interest
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                primaryBackground,
                Color(red: 0.13, green: 0.24, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                cardBackground,
                cardBackground.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Special colors
    var divider: Color {
        Color.white.opacity(0.15)
    }
    
    var glassOverlay: Color {
        Color.white.opacity(0.05)
    }

    init(isDarkMode: Bool = true) {
        self.isDarkMode = true // Always dark mode
    }
}

// MARK: - Typography System with SF Pro Rounded

extension Font {
    // Display styles
    static let grassDisplay = Font.system(.largeTitle, design: .rounded, weight: .heavy)
    static let grassDisplayMedium = Font.system(.largeTitle, design: .rounded, weight: .semibold)
    
    // Title styles
    static let grassTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let grassTitle2 = Font.system(.title2, design: .rounded, weight: .bold)
    static let grassTitle3 = Font.system(.title3, design: .rounded, weight: .semibold)
    
    // Headline styles
    static let grassHeadline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let grassSubheadline = Font.system(.subheadline, design: .rounded, weight: .medium)
    
    // Body styles
    static let grassBody = Font.system(.body, design: .rounded, weight: .regular)
    static let grassBodyEmphasized = Font.system(.body, design: .rounded, weight: .semibold)
    
    // Caption styles
    static let grassCaption = Font.system(.caption, design: .rounded, weight: .regular)
    static let grassCaption2 = Font.system(.caption2, design: .rounded, weight: .regular)
}

// MARK: - Spacing System (8pt grid)

struct AppSpacing {
    static let xxxs: CGFloat = 4
    static let xxs: CGFloat = 8
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 40
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius System

struct AppRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let pill: CGFloat = 100
}

// MARK: - Shadow System

struct AppShadow {
    static let sm: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        Color.black.opacity(0.1), 4, 0, 2
    )
    static let md: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        Color.black.opacity(0.15), 8, 0, 4
    )
    static let lg: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        Color.black.opacity(0.2), 16, 0, 8
    )
}

extension View {
    func themedColors(_ themeManager: ThemeManager) -> AppColors {
        AppColors(isDarkMode: themeManager.isDarkMode)
    }
}
