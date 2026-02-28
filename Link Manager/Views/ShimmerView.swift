import SwiftUI

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration = 1.5
    var bounce = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Color.white.opacity(0.5)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.8), .clear]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .rotationEffect(.degrees(30))
                                .offset(x: -geo.size.width + (geo.size.width * 3 * phase)) // Move across
                        )
                }
            )
            .onAppear {
                withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: bounce)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}
