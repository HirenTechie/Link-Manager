import Foundation
import CoreData
import SwiftUI

@MainActor
class LinkViewModel: ObservableObject {
    let context: NSManagedObjectContext
    
    @Published var categories: [Category] = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchCategories()
        Task {
            await processPendingLinks()
        }
    }
    
    func fetchCategories() {
        let request = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            categories = try context.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
    
    func processPendingLinks() async {
        let request = Content.fetchRequest()
        // Links that have no title are considered pending/incomplete (from Share Extension)
        request.predicate = NSPredicate(format: "title == nil")
        
        do {
            let pendingLinks = try context.fetch(request)
            for link in pendingLinks {
                if let urlString = link.savedLinkUrl, let url = URL(string: urlString) {
                    await updateMetadata(for: link, url: url)
                }
            }
        } catch {
            print("Error fetching pending links: \(error)")
        }
    }
    
    func updateMetadata(for content: Content, url: URL) async {
        do {
            let metadata = try await MetadataService.shared.fetchMetadata(for: url)
            content.title = metadata.title
            
            if let imageData = metadata.imageData {
                content.thumbIconUrl = saveImageToDisk(data: imageData, name: "thumb_\(content.id?.uuidString ?? UUID().uuidString)")
            }
            
            if let iconData = metadata.iconData {
                content.domainIconUrl = saveImageToDisk(data: iconData, name: "icon_\(content.id?.uuidString ?? UUID().uuidString)")
            } else if let domain = content.domainName, let favicon = MetadataService.shared.getFaviconURL(for: domain) {
                 content.domainIconUrl = favicon.absoluteString
            }
            
            // Auto Categorize if needed
            if let domain = content.domainName {
                let category = getOrCreateCategory(name: domain)
                content.category = category
                if category.thumbIcon == nil {
                     category.thumbIcon = content.domainIconUrl
                }
            }
            
            saveContext()
        } catch {
            print("Metadata fetch failed for \(url)")
        }
    }
    
    func addLink(url: URL) async {
        let domainName = MetadataService.shared.extractDomainName(from: url) ?? "Unknown"
        let category = getOrCreateCategory(name: domainName)
        
        let content = Content(context: context)
        content.id = UUID()
        content.savedLinkUrl = url.absoluteString
        content.domainName = domainName
        content.category = category
        content.creationDate = Date()
        content.isFavorite = false
        
        // Save initial state immediately
        saveContext()
        
        // Fetch Metadata asynchronously
        do {
            let metadata = try await MetadataService.shared.fetchMetadata(for: url)
            content.title = metadata.title
            // Save Images to file system or keeping as URL? User said "thumb-Icon-URL".
            // If we get Data, we should save it to disk and store the URL.
            
            if let imageData = metadata.imageData {
                content.thumbIconUrl = saveImageToDisk(data: imageData, name: "thumb_\(content.id!.uuidString)")
            } else {
                 // Try to fallback to some service or just leave it
            }
            
            if let iconData = metadata.iconData {
                 content.domainIconUrl = saveImageToDisk(data: iconData, name: "icon_\(content.id!.uuidString)")
            } else {
                // Fallback to Google Favicon
                 if let favicon = MetadataService.shared.getFaviconURL(for: domainName) {
                     content.domainIconUrl = favicon.absoluteString
                 }
            }
            
            // Apply category icon if not set
            if category.thumbIcon == nil {
                category.thumbIcon = content.domainIconUrl
            }
            
            saveContext()
        } catch {
            print("Failed to fetch metadata: \(error)")
            // Logic to retry or just show domain
            content.title = domainName
            saveContext()
        }
    }
    
    func getOrCreateCategory(name: String) -> Category {
        if let existing = categories.first(where: { $0.name == name }) {
            return existing
        }
        
        let newCategory = Category(context: context)
        newCategory.id = UUID()
        newCategory.name = name
        // thumbIcon will be set by the first link's icon
        
        saveContext()
        fetchCategories()
        return newCategory
    }
    
    func deleteLink(_ link: Content) {
        context.delete(link)
        saveContext()
    }
    
    func toggleFavorite(_ link: Content) {
        link.isFavorite.toggle()
        saveContext()
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func saveImageToDisk(data: Data, name: String) -> String? {
        // Save to App Group container so Share Extension can read it
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier) {
            let fileURL = containerURL.appendingPathComponent(name + ".png")
            do {
                try data.write(to: fileURL)
                return fileURL.absoluteString
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        return nil
    }
}
