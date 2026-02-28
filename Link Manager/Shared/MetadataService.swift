import Foundation
import LinkPresentation
import UniformTypeIdentifiers
import UIKit

struct LinkMetadata {
    let title: String?
    let iconData: Data?
    let imageData: Data?
    let url: URL
    let description: String?
}

class MetadataService {
    static let shared = MetadataService()
    
    private let provider = LPMetadataProvider()
    
    func fetchMetadata(for url: URL) async throws -> LinkMetadata {
        // Use a new provider instance per request if needed to avoid state issues, 
        // but shared instance is often fine. Apple recommends new instance for new request usually.
        let provider = LPMetadataProvider() 
        let metadata = try await provider.startFetchingMetadata(for: url)
        
        var iconData: Data?
        var imageData: Data?
        
        if let iconProvider = metadata.iconProvider {
            iconData = try? await loadData(from: iconProvider)
        }
        
        if let imageProvider = metadata.imageProvider {
            imageData = try? await loadData(from: imageProvider)
        }
        
        return LinkMetadata(
            title: metadata.title,
            iconData: iconData,
            imageData: imageData,
            url: metadata.url ?? url,
            description: nil // Native LPLinkMetadata doesn't expose description directly accessible
        )
    }
    
    private func loadData(from provider: NSItemProvider) async throws -> Data? {
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let item = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
            if let data = item as? Data { return data }
            if let url = item as? URL { return try? Data(contentsOf: url) }
            if let image = item as? UIImage { return image.pngData() }
        }
        return nil
    }
    
    // Helper Methods
    func extractDomainName(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        let components = host.components(separatedBy: ".")
        let ignoredSubdomains = ["www", "m", "mobile", "web", "app", "secure", "api", "shop", "store", "open", "music", "play"]
        
        for component in components {
            if !ignoredSubdomains.contains(component) {
                return component.capitalized
            }
        }
        return components.first?.capitalized
    }
    
    func getFaviconURL(for domain: String) -> URL? {
        return URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(domain)")
    }
}
