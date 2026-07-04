//
//  NatureBackgroundView.swift
//  Go Touch Grass
//
//  Created by Assistant on 7/4/26.
//  Nature-inspired animated background with floating leaves
//

import SwiftUI

struct NatureBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        let colors = AppColors()
        
        ZStack {
            // Base gradient background
            colors.backgroundGradient
                .ignoresSafeArea()
            
            // Decorative leaf shapes
            GeometryReader { geometry in
                // Large decorative leaf in top-right
                LeafShape()
                    .fill(colors.accent.opacity(0.03))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(45))
                    .offset(x: geometry.size.width - 100, y: -50)
                    .blur(radius: 2)
                
                // Medium leaf in bottom-left
                LeafShape()
                    .fill(colors.accentLight.opacity(0.04))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -30, y: geometry.size.height - 100)
                    .blur(radius: 1.5)
                
                // Small accent leaf floating
                LeafShape()
                    .fill(colors.accent.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(animate ? 15 : -15))
                    .offset(
                        x: geometry.size.width * 0.7,
                        y: geometry.size.height * 0.3 + (animate ? 10 : -10)
                    )
                    .animation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
                
                // Organic circles for depth
                Circle()
                    .fill(colors.sky.opacity(0.02))
                    .frame(width: 300, height: 300)
                    .offset(x: geometry.size.width * 0.2, y: geometry.size.height * 0.6)
                    .blur(radius: 50)
                
                Circle()
                    .fill(colors.sunshine.opacity(0.015))
                    .frame(width: 250, height: 250)
                    .offset(x: geometry.size.width * 0.6, y: geometry.size.height * 0.2)
                    .blur(radius: 60)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Leaf Shape

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Create organic leaf shape
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        
        // Right side of leaf
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control1: CGPoint(x: width * 0.9, y: height * 0.1),
            control2: CGPoint(x: width * 1.1, y: height * 0.3)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 0.95, y: height * 0.7),
            control2: CGPoint(x: width * 0.7, y: height * 0.95)
        )
        
        // Left side of leaf
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.5),
            control1: CGPoint(x: width * 0.3, y: height * 0.95),
            control2: CGPoint(x: width * 0.05, y: height * 0.7)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: -width * 0.1, y: height * 0.3),
            control2: CGPoint(x: width * 0.1, y: height * 0.1)
        )
        
        return path
    }
}

// MARK: - Preview

#Preview {
    NatureBackgroundView()
}
