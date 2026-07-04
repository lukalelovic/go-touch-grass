//
//  ProgressRing.swift
//  Go Touch Grass
//
//  Created by Assistant on 7/4/26.
//  Circular progress ring for streaks and achievements
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let icon: String
    let iconColor: Color
    let ringColor: Color
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var animateProgress = false
    
    init(
        progress: Double,
        icon: String,
        iconColor: Color = AppColors().accent,
        ringColor: Color = AppColors().accent,
        size: CGFloat = 100,
        lineWidth: CGFloat = 8
    ) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.icon = icon
        self.iconColor = iconColor
        self.ringColor = ringColor
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        let colors = AppColors()
        
        ZStack {
            // Background ring
            Circle()
                .stroke(colors.divider, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animateProgress ? progress : 0)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animateProgress)
            
            // Glow effect
            if progress > 0.8 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: lineWidth * 1.5,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 4)
            }
            
            // Center icon
            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(iconColor)
        }
        .onAppear {
            animateProgress = true
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors().backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: AppSpacing.xl) {
            // Streak ring
            VStack(spacing: AppSpacing.xxs) {
                ProgressRing(
                    progress: 0.75,
                    icon: "flame.fill",
                    iconColor: .orange,
                    ringColor: .orange
                )
                
                Text("7 Day Streak")
                    .font(.grassCaption)
                    .foregroundStyle(AppColors().secondaryText)
            }
            
            // Level progress
            VStack(spacing: AppSpacing.xxs) {
                ProgressRing(
                    progress: 0.6,
                    icon: "leaf.fill",
                    iconColor: AppColors().accent,
                    ringColor: AppColors().accent,
                    size: 120,
                    lineWidth: 10
                )
                
                Text("Level 5")
                    .font(.grassHeadline)
                    .foregroundStyle(AppColors().primaryText)
            }
            
            // Full progress
            VStack(spacing: AppSpacing.xxs) {
                ProgressRing(
                    progress: 1.0,
                    icon: "checkmark",
                    iconColor: AppColors().accent,
                    ringColor: AppColors().accent,
                    size: 80
                )
                
                Text("Complete!")
                    .font(.grassCaption)
                    .foregroundStyle(AppColors().accent)
            }
        }
        .padding()
    }
}
