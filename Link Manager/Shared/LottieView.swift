import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let contentMode: UIView.ContentMode
    let completion: ((Bool) -> Void)?

    init(animationName: String, 
         loopMode: LottieLoopMode = .playOnce, 
         contentMode: UIView.ContentMode = .scaleAspectFit, 
         completion: ((Bool) -> Void)? = nil) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.completion = completion
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.subviews.forEach { $0.removeFromSuperview() }
        
        let configuration = LottieConfiguration(renderingEngine: .mainThread)
        let animationView = LottieAnimationView(name: animationName, configuration: configuration)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        uiView.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: uiView.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: uiView.widthAnchor)
        ])
        
        animationView.play { finished in
            completion?(finished)
        }
    }
}
