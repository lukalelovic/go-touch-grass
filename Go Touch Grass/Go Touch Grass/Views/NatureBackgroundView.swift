//
//  NatureBackgroundView.swift
//  Go Touch Grass
//
//  Created by Assistant on 7/4/26.
//  Clean gradient background
//

import SwiftUI

struct NatureBackgroundView: View {
    var body: some View {
        let colors = AppColors()
        
        // Clean gradient background only
        colors.backgroundGradient
            .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    NatureBackgroundView()
}
