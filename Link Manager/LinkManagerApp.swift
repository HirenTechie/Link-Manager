import CoreData
import SwiftUI

@main
struct LinkManagerApp: App {
    let persistenceController = PersistenceController.shared

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    HomeView()
                        .environment(
                            \.managedObjectContext, persistenceController.container.viewContext
                        )
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
