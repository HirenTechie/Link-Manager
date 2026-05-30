import SwiftUI

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon:        String
    let title:       String
    let subtitle:    String
    let iconColors:  [Color]
}

// MARK: - Onboarding View
struct OnboardingView: View {

    var onFinished: () -> Void

    // MARK: Pages
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "link.badge.plus",
            title: "Save Any Link",
            subtitle: "Instantly save links from anywhere — browser, apps, or share sheet. Never lose an important link again.",
            iconColors: [Color(.splashLogoPurple), Color(.splashLogoBlue), .cyan]
        ),
        OnboardingPage(
            icon: "square.grid.2x2.fill",
            title: "Organize Smartly",
            subtitle: "Group your links into collections. Keep work, personal, and everything else neatly sorted.",
            iconColors: [Color(.splashParticleViolet), Color(.splashParticleElectricBlue), .cyan]
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "Access in a Flash",
            subtitle: "Open any saved link instantly. Your links, always at your fingertips — fast and simple.",
            iconColors: [Color(.splashGlowViolet), Color(.splashTaglineBlue), .cyan]
        ),
    ]

    // MARK: State
    @State private var currentPage   = 0
    @State private var iconScale: CGFloat  = 0.5
    @State private var iconOpacity: Double = 0
    @State private var iconY: CGFloat      = 30
    @State private var textOpacity: Double = 0
    @State private var textY: CGFloat      = 20
    @State private var isAnimatingIcon     = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {

                Spacer()

                // Icon
                iconSection

                Spacer().frame(height: 48)

                // Text
                textSection

                Spacer()

                // Bottom Controls
                bottomControls
                    .padding(.bottom, 52)
            }
            .padding(.horizontal, 28)
        }
    }

    // MARK: Background (same as splash)
    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.splashBgBlack),
                    Color(.splashBgMidPurple),
                    Color(.splashBgDeepViolet)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ambient orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(.splashAmbientViolet).opacity(0.22), .clear],
                        center: .center, startRadius: 5, endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: -80, y: -260)
                .blur(radius: 50)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(.splashAmbientBlue).opacity(0.14), .clear],
                        center: .center, startRadius: 5, endRadius: 200
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: 130, y: 340)
                .blur(radius: 55)
        }
    }

    // MARK: Icon Section
    private var iconSection: some View {
        ZStack {
            // Glow bloom
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            pages[currentPage].iconColors[0].opacity(0.40),
                            pages[currentPage].iconColors[1].opacity(0.18),
                            .clear
                        ],
                        center: .center, startRadius: 5, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 24)

            // Icon
            Image(systemName: pages[currentPage].icon)
                .font(.system(size: 90, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: pages[currentPage].iconColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: pages[currentPage].iconColors[0].opacity(0.85), radius: 22, x: 0, y: 0)
                .shadow(color: pages[currentPage].iconColors[1].opacity(0.45), radius: 44, x: 0, y: 12)
                // Floating animation
                .offset(y: isAnimatingIcon ? -8 : 0)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: isAnimatingIcon
                )
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
        .offset(y: iconY)
        .onAppear { animateIn() }
    }

    // MARK: Text Section
    private var textSection: some View {
        VStack(spacing: 14) {

            Text(pages[currentPage].title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(.splashTextLavender)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .shadow(color: Color(.splashLogoPurple).opacity(0.50), radius: 12, x: 0, y: 4)

            Text(pages[currentPage].subtitle)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 8)
        }
        .opacity(textOpacity)
        .offset(y: textY)
    }

    // MARK: Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 24) {

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage
                              ? Color(.splashLogoPurple)
                              : Color.white.opacity(0.25))
                        .frame(width: i == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
            }

            // Next / Get Started button
            Button(action: handleNext) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(.splashLogoPurple), Color(.splashLogoBlue)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(.splashLogoPurple).opacity(0.55), radius: 14, x: 0, y: 6)
            }

            // Skip button (hidden on last page)
            if currentPage < pages.count - 1 {
                Button(action: { onFinished() }) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.40))
                }
            } else {
                // Spacer to keep layout stable
                Color.clear.frame(height: 20)
            }
        }
    }

    // MARK: Helpers
    private func handleNext() {
        if currentPage < pages.count - 1 {
            switchPage(to: currentPage + 1)
        } else {
            onFinished()
        }
    }

    private func switchPage(to index: Int) {
        // Fade out current
        withAnimation(.easeIn(duration: 0.18)) {
            iconOpacity = 0
            iconScale   = 0.85
            iconY       = -10
            textOpacity = 0
            textY       = -10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            currentPage = index
            animateIn()
        }
    }

    private func animateIn() {
        // Reset
        iconScale   = 0.5
        iconOpacity = 0
        iconY       = 30
        textOpacity = 0
        textY       = 20
        isAnimatingIcon = false

        // Icon in
        withAnimation(.spring(response: 0.60, dampingFraction: 0.62)) {
            iconScale   = 1.0
            iconOpacity = 1.0
            iconY       = 0
        }
        // Text in (slight delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.50, dampingFraction: 0.70)) {
                textOpacity = 1.0
                textY       = 0
            }
        }
        // Start floating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            isAnimatingIcon = true
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(onFinished: {})
}
