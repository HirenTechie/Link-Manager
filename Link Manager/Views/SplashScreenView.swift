import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5

    var body: some View {
        if isActive {
            // This will be replaced by the main app view in the parent
            EmptyView()
        } else {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                        .scaleEffect(size)
                        .opacity(opacity)

                    Text("Link Manager")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary.opacity(0.80))
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 1.0
                    self.opacity = 1.00
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
