import Foundation
import LinkPresentation
import UniformTypeIdentifiers

class MetadataService {
    static let shared = MetadataService()
    
    struct LinkMetadata {
        let title: String?
        let iconData: Data?
        let imageData: Data?
        let url: URL
    }
    
    func fetchMetadata(for url: URL) async throws -> LinkMetadata {
        let provider = LPMetadataProvider()
        let metadata = try await provider.startFetchingMetadata(for: url)
        
        var iconData: Data?
        var imageData: Data?
        
        // Fetch Icon
        if let iconProvider = metadata.iconProvider {
            iconData = try? await loadData(from: iconProvider)
        }
        
        // Fetch Image (Thumbnail)
        if let imageProvider = metadata.imageProvider {
            imageData = try? await loadData(from: imageProvider)
        }
        
        return LinkMetadata(
            title: metadata.title,
            iconData: iconData,
            imageData: imageData,
            url: url
        )
    }
    
    private func loadData(from provider: NSItemProvider) async throws -> Data? {
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let item = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
            
            if let data = item as? Data {
                return data
            } else if let url = item as? URL {
                return try? Data(contentsOf: url)
            } else if let image = item as? UIImage {
                return image.pngData()
            }
        }
        return nil
    }
    
    func extractDomainName(from url: URL) -> String? {
        return url.host?.replacingOccurrences(of: "www.", with: "").capitalized
    }
    
    // Google Favicon API as a fallback or domain icon source
    func getFaviconURL(for domain: String) -> URL? {
        return URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(domain)")
    }
}
