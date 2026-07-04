//
//  SkeletonView.swift
//  Go Touch Grass
//
//  Created by Assistant on 7/4/26.
//  Skeleton loading views with shimmer effect
//

import SwiftUI

struct SkeletonView: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var shimmerOffset: CGFloat = -1
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = AppRadius.xs) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        let colors = AppColors()
        
        Rectangle()
            .fill(colors.secondaryCardBackground)
            .frame(height: height)
            .cornerRadius(cornerRadius)
            .overlay {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    colors.glassOverlay.opacity(0.5),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset * geometry.size.width)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                            ) {
                                shimmerOffset = 2
                            }
                        }
                }
            }
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    SkeletonView(height: 40, cornerRadius: AppRadius.xs)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        SkeletonView(height: 16, cornerRadius: AppRadius.xs)
                            .frame(width: 120)
                        SkeletonView(height: 12, cornerRadius: AppRadius.xs)
                            .frame(width: 80)
                    }
                    
                    Spacer()
                }
                
                SkeletonView(height: 14, cornerRadius: AppRadius.xs)
                SkeletonView(height: 14, cornerRadius: AppRadius.xs)
                    .frame(width: 200)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        NatureBackgroundView()
        
        VStack(spacing: AppSpacing.md) {
            SkeletonCard()
            SkeletonCard()
            SkeletonCard()
        }
        .padding()
    }
}
