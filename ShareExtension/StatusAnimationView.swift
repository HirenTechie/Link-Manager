import SwiftUI

struct StatusAnimationView: View {
    var status: AnimationStatus
    var completion: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                AnimationManager.shared.view(for: status) { finished in
                    if finished {
                        completion?()
                    }
                }
                .frame(width: 200, height: 200)
                
                Text(status == .success ? "Saved!" : "Failed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}
