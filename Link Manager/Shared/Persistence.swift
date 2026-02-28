import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentCloudKitContainer
    // MARK: - App Group Identifier
    // REPLACE WITH YOUR ACTUAL APP GROUP ID
    static let appGroupIdentifier = "group.com.hiren.LinkManager"
    init(inMemory: Bool = false) {
        // Explicitly load the model to ensure it works in both App and Extension targets
        // Explicitly load the model to ensure it works in both App and Extension targets
        let bundle = Bundle(for: PersistenceController.self)
        
        // Try to find the compiled model path (momd for versioned, mom for unversioned)
        guard let modelURL = bundle.url(forResource: "LinkManager", withExtension: "momd") ??
                             bundle.url(forResource: "LinkManager", withExtension: "mom") else {
            fatalError("Error: Could not find 'LinkManager.momd' OR 'LinkManager.mom' in bundle: \(bundle.bundlePath). \n\nCRITICAL FIX: Open Xcode, select 'LinkManager.xcdatamodeld' (or .xcdatamodel), and in the File Inspector (Right Side), CHECK 'ShareExtension' under Target Membership.")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error: Could not load NSManagedObjectModel from \(modelURL)")
        }
        container = NSPersistentCloudKitContainer(name: "LinkManager", managedObjectModel: model)
        
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
                // fatalError("Unresolved error \(error), \(error.userInfo)")
                print("CORE DATA ERROR: Failed to load persistent stores: \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
