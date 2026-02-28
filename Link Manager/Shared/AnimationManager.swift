import Foundation
import SwiftUI
import Lottie
import Combine
import Lottie

enum AnimationStatus {
    case success
    case failed
    
    var filename: String {
        switch self {
        case .success:
            return "success"
        case .failed:
            return "fail"
        }
    }
}

class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    private init() {}
    
    func view(for status: AnimationStatus, completion: ((Bool) -> Void)? = nil) -> some View {
        LottieView(animationName: status.filename, loopMode: .playOnce, completion: completion)
    }
}
