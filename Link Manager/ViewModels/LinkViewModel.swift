import Combine
import CoreData
import Foundation
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
            await sanitizeDomains()  // Run one-time cleanups or regular checks
        }
    }

    func refresh() async {
        // Force refresh of all objects to pick up changes from Share Extension (separate process)
        context.refreshAllObjects()

        fetchCategories()
        await processPendingLinks()
        await sanitizeDomains()  // Ensure we capture any new issues
    }

    func sanitizeDomains() async {
        let request = Content.fetchRequest()
        // Improve predicate to find only potential issues if possible, but fetching all is safer for small dataset

        do {
            let allLinks = try context.fetch(request)
            var hasChanges = false

            for link in allLinks {
                if let urlString = link.savedLinkUrl, let url = URL(string: urlString) {
                    let currentDomain = link.domainName
                    let correctDomain =
                        MetadataService.shared.extractDomainName(from: url) ?? "Unknown"

                    if currentDomain != correctDomain {
                        // Fix Domain
                        link.domainName = correctDomain

                        // Fix Category
                        let oldCategory = link.category
                        let newCategory = getOrCreateCategory(name: correctDomain)

                        if oldCategory != newCategory {
                            link.category = newCategory

                            // Check empty old category
                            if let oldCategory = oldCategory {
                                checkAndDeleteEmptyCategory(oldCategory)
                            }
                        }

                        hasChanges = true
                    }
                }
            }

            if hasChanges {
                saveContext()
                fetchCategories()
            }
        } catch {
            print("Sanitize error: \(error)")
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

            // Update title
            content.title = metadata.title

            // Update description (subtitle) if exists and not user provided (maybe?)
            // Actually, if user provided a subtitle, we might want to keep it?
            // Or only if subtitle is nil? Let's assume metadata description populates if empty.
            if content.subtitle == nil || content.subtitle?.isEmpty == true {
                content.subtitle = metadata.description
            }

            // Images
            if let imageData = metadata.imageData {
                let timestamp = Int(Date().timeIntervalSince1970)
                content.thumbIconUrl = saveImageToDisk(
                    data: imageData,
                    name: "thumb_\(content.id?.uuidString ?? UUID().uuidString)_\(timestamp)")
            }

            // Uses the RESOLVED URL for domain extraction (e.g. gets "Amazon" from "amzn.in" -> "amazon.in")
            let resolvedDomainName =
                MetadataService.shared.extractDomainName(from: metadata.url) ?? "Unknown"

            // Domain Icon
            if let iconData = metadata.iconData {
                let timestamp = Int(Date().timeIntervalSince1970)
                content.domainIconUrl = saveImageToDisk(
                    data: iconData,
                    name: "icon_\(content.id?.uuidString ?? UUID().uuidString)_\(timestamp)")
            } else if let favicon = MetadataService.shared.getFaviconURL(for: resolvedDomainName) {
                content.domainIconUrl = favicon.absoluteString
            }

            // Update Category and Domain Name if changed by resolution
            if content.domainName != resolvedDomainName {
                content.domainName = resolvedDomainName
                let newCategory = getOrCreateCategory(name: resolvedDomainName)

                // Move category if needed
                if content.category != newCategory {
                    let oldCategory = content.category
                    content.category = newCategory

                    // Check if old category needs deletion
                    if let oldCategory = oldCategory {
                        checkAndDeleteEmptyCategory(oldCategory)
                    }
                }
            } else {
                // Initial categorization if empty
                if content.category == nil {
                    let category = getOrCreateCategory(name: resolvedDomainName)
                    content.category = category
                }
            }

            // Ensure category icon is set or updated with the latest high-quality icon
            if let category = content.category, let domainIcon = content.domainIconUrl {
                // Always update the category icon to match the link's domain icon
                // This ensures that if we fetch a better icon later, the category gets it too.
                category.thumbIcon = domainIcon
            }

            saveContext()
        } catch {
            print("Metadata fetch failed for \(url)")
        }
    }

    func addLink(url: URL, subtitle: String? = nil) async -> Content {
        let domainName = MetadataService.shared.extractDomainName(from: url) ?? "Unknown"
        let category = getOrCreateCategory(name: domainName)

        let content = Content(context: context)
        content.id = UUID()
        content.savedLinkUrl = url.absoluteString
        content.domainName = domainName
        content.category = category
        content.creationDate = Date()
        content.isFavorite = false
        content.subtitle = subtitle  // Save user provided description

        // Save initial state immediately
        saveContext()

        // Fetch Metadata asynchronously using the shared update logic
        await updateMetadata(for: content, url: url)

        // Final save ensures everything is persisted
        saveContext()

        return content
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
        // Capture category before deleting the link
        let category = link.category

        context.delete(link)

        // Check if category is now empty (excluding deleted items)
        if let category = category {
            checkAndDeleteEmptyCategory(category)
        }

        saveContext()
        fetchCategories()
    }

    func deleteLinks(_ contents: [Content]) {
        // Collect involved categories
        let involvedCategories = Set(contents.compactMap { $0.category })

        for content in contents {
            context.delete(content)
        }

        // Cleanup empty categories
        for category in involvedCategories {
            checkAndDeleteEmptyCategory(category)
        }

        saveContext()
        fetchCategories()
    }

    func deleteLinks(in category: Category) {
        if let contents = category.contents?.allObjects as? [Content] {
            deleteLinks(contents)
            // The category itself will be deleted by deleteLinks check if it becomes empty (which it will)
        }
    }

    func deleteAllLinks() {
        let request: NSFetchRequest<NSFetchRequestResult> = Content.fetchRequest()
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)

        // Also delete all categories
        let catRequest: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
        let catBatchDelete = NSBatchDeleteRequest(fetchRequest: catRequest)

        do {
            try context.execute(batchDelete)
            try context.execute(catBatchDelete)
            context.reset()  // Reset context to clear cache
            fetchCategories()
        } catch {
            print("Batch delete failed: \(error)")
        }
    }

    private func checkAndDeleteEmptyCategory(_ category: Category) {
        if let contents = category.contents?.allObjects as? [Content] {
            let activeContents = contents.filter { !$0.isDeleted }
            if activeContents.isEmpty {
                context.delete(category)
            }
        }
    }

    func toggleFavorite(_ link: Content) {
        link.isFavorite.toggle()
        saveContext()
    }

    func updateLink(_ content: Content, title: String, urlString: String) async {
        content.title = title

        // Check if URL changed
        if content.savedLinkUrl != urlString, let newUrl = URL(string: urlString) {
            let oldCategory = content.category

            content.savedLinkUrl = urlString

            // Extract new domain
            let newDomain = MetadataService.shared.extractDomainName(from: newUrl) ?? "Unknown"

            // If domain changed, move category
            if content.domainName != newDomain || content.category?.name != newDomain {
                content.domainName = newDomain
                let newCategory = getOrCreateCategory(name: newDomain)
                content.category = newCategory

                // If the new category doesn't have an icon yet, we'll wait for updateMetadata or set it there
            }

            // Check if old category is empty now
            if let oldCategory = oldCategory, oldCategory != content.category {
                if let contents = oldCategory.contents?.allObjects as? [Content], contents.isEmpty {
                    context.delete(oldCategory)
                }
            }

            // Fetch updated metadata (icons, final title if user didn't set one, etc)
            await updateMetadata(for: content, url: newUrl)
        }

        saveContext()
        fetchCategories()
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
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier)
        {
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
