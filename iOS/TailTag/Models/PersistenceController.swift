import CoreData
import Foundation

// Used only for migrating data from the old CoreData store to SwiftData on first launch.
// After migration, this class is never instantiated again.
class PersistenceController {
    static let shared = PersistenceController()
    static let iCloudSyncKey = "iCloudSyncEnabled"

    let container: NSPersistentContainer?

    init(inMemory: Bool = false) {
        let c = NSPersistentContainer(name: "SpottingModel")

        if inMemory {
            c.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        var loadError: Error?
        c.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            print("CoreData store unavailable (expected after SwiftData migration): \(error)")
            container = nil
        } else {
            c.viewContext.automaticallyMergesChangesFromParent = true
            c.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container = c
        }
    }
}
