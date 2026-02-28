import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    // MARK: - App Group Identifier
    // REPLACE WITH YOUR ACTUAL APP GROUP ID
    static let appGroupIdentifier = "group.com.hiren.LinkManager"

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "LinkManager")
        
        // Configure the container to use an App Group location
        if let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier)?.appendingPathComponent("LinkManager.sqlite") {
             let storeDescription = NSPersistentStoreDescription(url: storeURL)
             // Enable cloud kit sync if needed, or just local sharing
             // storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.hiren.LinkManager")
             container.persistentStoreDescriptions = [storeDescription]
        }

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
