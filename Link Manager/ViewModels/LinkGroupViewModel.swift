import Combine
import CoreData
import Foundation
import SwiftUI

@MainActor
class LinkGroupViewModel: ObservableObject {
    let context: NSManagedObjectContext

    @Published var groups: [LinkGroup] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchGroups()

        // Listen for changes in the context (e.g., when LinkViewModel updates thumbnails)
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,  // Observe all contexts (or specific if needed)
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.fetchGroups()
            }
        }
    }

    func fetchGroups() {
        let request = LinkGroup.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \LinkGroup.creationDate, ascending: true)
        ]

        do {
            groups = try context.fetch(request)
        } catch {
            print("Error fetching groups: \(error)")
        }
    }

    // MARK: - CRUD

    func addGroup(name: String, symbol: String? = nil, desc: String? = nil) {
        let newGroup = LinkGroup(context: context)
        newGroup.id = UUID()
        newGroup.name = name
        newGroup.creationDate = Date()
        newGroup.symbol = symbol
        newGroup.desc = desc

        saveContext()
        fetchGroups()
    }

    func updateGroup(_ group: LinkGroup, name: String, desc: String?) {
        group.name = name
        group.desc = desc
        saveContext()
        fetchGroups()
    }

    func deleteGroup(_ group: LinkGroup) {
        context.delete(group)
        saveContext()
        fetchGroups()
    }

    // MARK: - Link Management

    func renameGroup(_ group: LinkGroup, newName: String) {
        let cleaned = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        group.name = cleaned
        saveContext()
        fetchGroups()  // Trigger UI update
    }

    // MARK: - Link Management

    func addLinksToGroup(group: LinkGroup, links: [Content]) {
        group.objectWillChange.send()
        for link in links {
            group.addToLinks(link)
        }
        saveContext()
        context.refresh(group, mergeChanges: true)  // Forces persistence to sync with UI
        fetchGroups()  // Refresh lists/thumbnails
    }

    func removeLinksFromGroup(group: LinkGroup, links: [Content]) {
        group.objectWillChange.send()
        for link in links {
            group.removeFromLinks(link)
        }
        saveContext()
        context.refresh(group, mergeChanges: true)
        fetchGroups()  // Refresh lists/thumbnails
    }

    func getRecentThumbnails(for group: LinkGroup, limit: Int = 4) -> [String] {
        guard let links = group.links?.allObjects as? [Content] else { return [] }

        // Sort by creation date (newest first)
        let sortedLinks = links.sorted {
            ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
        }

        // Get valid thumbnails
        let thumbnails = sortedLinks.compactMap { $0.thumbIconUrl }.prefix(limit)
        return Array(thumbnails)
    }

    func getRecentLinks(for group: LinkGroup, limit: Int = 4) -> [Content] {
        guard let links = group.links?.allObjects as? [Content] else { return [] }

        // Sort by creation date (newest first)
        let sortedLinks = links.sorted {
            ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
        }

        return Array(sortedLinks.prefix(limit))
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context in GroupViewModel: \(error)")
        }
    }
}
