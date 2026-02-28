import UIKit
import Social
import SwiftUI
import CoreData
import MobileCoreServices

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure the view is transparent so we can see the host app behind if desired, 
        // asking for "Share Sheet" usually implies simple presentation.
        // But standard Share Extension presents a compose sheet. 
        // We want to skip the compose sheet and just save + animate.
        view.backgroundColor = .clear
        
        handleShare()
    }

    private func handleShare() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            self.showErrorAndExit("No input items found.")
            return
        }

        let contentTypeURL = "public.url" 
        let contentTypeText = "public.text"
        
        // We will collect ALL found URLs
        var detectedURLs: [URL] = []
        let dispatchGroup = DispatchGroup()
        
        for attachment in extensionItem.attachments ?? [] {
            
            // Checks for direct URL
            if attachment.hasItemConformingToTypeIdentifier(contentTypeURL) {
                dispatchGroup.enter()
                attachment.loadItem(forTypeIdentifier: contentTypeURL, options: nil) { (data, error) in
                    if let url = data as? URL {
                        detectedURLs.append(url)
                    }
                    dispatchGroup.leave()
                }
            }
            
            // Checks for Text (and then extracts URLs from it)
            if attachment.hasItemConformingToTypeIdentifier(contentTypeText) {
                dispatchGroup.enter()
                attachment.loadItem(forTypeIdentifier: contentTypeText, options: nil) { (data, error) in
                    if let text = data as? String {
                        let urls = self.extractURLs(from: text)
                        detectedURLs.append(contentsOf: urls)
                    } else if let url = data as? URL {
                        // Sometimes text attachment comes as a file URL??
                        detectedURLs.append(url)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Deduplicate
            let uniqueURLs = Array(Set(detectedURLs))
            
            if uniqueURLs.isEmpty {
                 self.showErrorAndExit("No links found.")
            } else if uniqueURLs.count == 1 {
                // Just 1 link? Save immediately.
                self.saveLinks([uniqueURLs[0]])
            } else {
                // Multiple URLs? Show Selection UI
                self.showSelectionUI(urls: uniqueURLs)
            }
        }
    }
    
    private func extractURLs(from text: String) -> [URL] {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            return matches.compactMap { $0.url }
        } catch {
            return []
        }
    }
    
    private func showSelectionUI(urls: [URL]) {
        let selectionView = ShareLinkSelectionView(
            detectedURLs: urls,
            onSave: { [weak self] selected in
                self?.saveLinks(selected)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        )
        
        let hostingController = UIHostingController(rootView: selectionView)
        hostingController.view.backgroundColor = .clear // Allow partial transparent if needed, or system bg
        hostingController.modalPresentationStyle = .overFullScreen
        
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
        hostingController.view.frame = self.view.bounds
        hostingController.didMove(toParent: self)
    }

    private func saveLinks(_ urls: [URL]) {
        guard !urls.isEmpty else {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        // Run on Main Thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 2. Save to Core Data
            let context = PersistenceController.shared.container.viewContext
            
            for url in urls {
                let content = Content(context: context)
                content.id = UUID()
                content.savedLinkUrl = url.absoluteString
                content.creationDate = Date()
                content.isFavorite = false
                
                // Temporary domain name for now; main app will fix/fetch metadata
                if let host = url.host {
                     content.domainName = host.replacingOccurrences(of: "www.", with: "").capitalized
                }
            }
            
            do {
                try context.save()
                self.showStatusAnimation(.success)
            } catch {
                print("Failed to save: \(error)")
                self.showStatusAnimation(.failed)
            }
        }
    }
    
    private func showErrorAndExit(_ message: String) {
        // Also show failed animation for general errors if suitable, or just alert?
        // User asked to "change the animation of the success and failed animation"
        // So for "No input items" or "No links found", we might just want to show "Failed" animation briefly.
        // But alerts might be more informative.
        // Let's stick to the user request "failed animation".
        // But for specific error messages, maybe an alert is better?
        // Use failed animation for simplicity as requested "failed animation ... to use success.json, failed.json"
        
        DispatchQueue.main.async { [weak self] in
            // Maybe log the message?
            print("Error: \(message)")
            self?.showStatusAnimation(.failed)
        }
    }

    private func showStatusAnimation(_ status: AnimationStatus) {
         let swiftUIView = StatusAnimationView(status: status) { [weak self] in
             // Close after animation completes
             // Add a small delay for user to see the "final state" if needed, 
             // but Lottie usually has an end.
             // Let's exit immediately after animation finishes.
             self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
         }
         
         let hostingController = UIHostingController(rootView: swiftUIView)
         hostingController.view.backgroundColor = .clear
         hostingController.modalPresentationStyle = .overFullScreen
         
         self.addChild(hostingController)
         self.view.addSubview(hostingController.view)
         hostingController.view.frame = self.view.bounds
         hostingController.didMove(toParent: self)
    }
}

