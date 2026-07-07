//
//  AnimatedButton.swift
//  Go Touch Grass
//
//  Created by Assistant on 7/4/26.
//  Reusable animated button with glass effect and haptic feedback
//

import SwiftUI

enum ButtonHierarchy {
    case primary
    case secondary
    case tertiary
}

struct AnimatedButton: View {
    let title: String
    let icon: String?
    let hierarchy: ButtonHierarchy
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        hierarchy: ButtonHierarchy = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.hierarchy = hierarchy
        self.action = action
    }
    
    var body: some View {
        let colors = AppColors()
        
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: AppSpacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.grassBodyEmphasized)
                }
                Text(title)
                    .font(.grassBodyEmphasized)
            }
            .foregroundStyle(foregroundColor(colors))
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .frame(maxWidth: hierarchy == .primary ? .infinity : nil)
            .background {
                if hierarchy == .primary {
                    Capsule()
                        .fill(colors.accentGradient)
                } else if hierarchy == .secondary {
                    Capsule()
                        .stroke(colors.accent, lineWidth: 2)
                        .background(Capsule().fill(colors.cardBackground))
                }
            }
        }
        .buttonStyle(SpringButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func foregroundColor(_ colors: AppColors) -> Color {
        switch hierarchy {
        case .primary:
            return Color(red: 0.10, green: 0.18, blue: 0.08)
        case .secondary, .tertiary:
            return colors.accent
        }
    }
}

// MARK: - Spring Button Style

struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style Extension

extension ButtonStyle where Self == GlassButtonStyle {
    static var grassGlass: GlassButtonStyle {
        GlassButtonStyle()
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let colors = AppColors()
        
        configuration.label
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background {
                Capsule()
                    .fill(colors.cardGradient)
                    .glassEffect(.regular.interactive())
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors().backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: AppSpacing.md) {
            AnimatedButton("Touch Grass", icon: "leaf.fill", hierarchy: .primary) {
                print("Primary button tapped")
            }
            
            AnimatedButton("Learn More", icon: "info.circle", hierarchy: .secondary) {
                print("Secondary button tapped")
            }
            
            AnimatedButton("Skip", hierarchy: .tertiary) {
                print("Tertiary button tapped")
            }
            
            Button("Glass Style") {
                print("Glass button tapped")
            }
            .buttonStyle(.grassGlass)
        }
        .padding()
    }
}
