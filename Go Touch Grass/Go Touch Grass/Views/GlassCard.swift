//
//  GlassCard.swift
//  Go Touch Grass
//
//  Created by Assistant on 7/4/26.
//  Reusable glass effect card component
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = AppRadius.md
    var padding: CGFloat = AppSpacing.sm
    var isInteractive: Bool = false
    
    init(
        cornerRadius: CGFloat = AppRadius.md,
        padding: CGFloat = AppSpacing.sm,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isInteractive = isInteractive
        self.content = content()
    }
    
    var body: some View {
        let colors = AppColors()
        
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(colors.cardGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(colors.glassOverlay)
                    }
                    .shadow(
                        color: AppShadow.md.color,
                        radius: AppShadow.md.radius,
                        x: AppShadow.md.x,
                        y: AppShadow.md.y
                    )
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors().backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: AppSpacing.md) {
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Glass Card Example")
                        .font(.grassHeadline)
                        .foregroundStyle(AppColors().primaryText)
                    
                    Text("This is a reusable glass card component with liquid glass effects")
                        .font(.grassBody)
                        .foregroundStyle(AppColors().secondaryText)
                }
            }
            
            GlassCard(isInteractive: true) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors().accent)
                    
                    Text("Interactive Card")
                        .font(.grassHeadline)
                        .foregroundStyle(AppColors().primaryText)
                    
                    Spacer()
                }
            }
        }
        .padding()
    }
}
