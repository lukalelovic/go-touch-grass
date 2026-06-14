import SwiftUI

struct LandingAnimationView: View {
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var grassProgress: [CGFloat] = [0, 0, 0, 0, 0]
    @State private var isReady: Bool = false

    var onComplete: () -> Void

    private let warmGreen = Color(red: 0.55, green: 0.78, blue: 0.35)

    var body: some View {
        ZStack {
            warmGreen.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .symbolEffect(.bounce, options: .repeat(2), value: isReady)

                Text("Go Touch Grass")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(textOpacity)
            }

            grassBlades
        }
        .onAppear(perform: startAnimation)
    }

    private var grassBlades: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let spacing = width / 6

            ForEach(0..<5) { i in
                let x = spacing + CGFloat(i) * spacing
                let bladeHeight: CGFloat = [60, 90, 120, 80, 50][i]
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.25))
                    .frame(width: 6, height: bladeHeight * grassProgress[i])
                    .position(x: x, y: height - bladeHeight * grassProgress[i] / 2)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.15), value: grassProgress[i])
            }
        }
    }

    private func startAnimation() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        for i in 0..<5 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.15)) {
                grassProgress[i] = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                textOpacity = 1
            }
            isReady = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                iconOpacity = 0
                textOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}
