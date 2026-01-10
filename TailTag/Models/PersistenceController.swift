import CoreData
import Foundation

class PersistenceController {
    nonisolated(unsafe) static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpottingModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable external storage for binary data (photos)
            if let description = container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentStoreFileProtectionKey)
            }
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load Core Data store: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Preview Support
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample data for previews
        for i in 0..<5 {
            let entity = SpottingEntryEntity(context: viewContext)
            entity.id = UUID()
            entity.registration = "G-ABC\(i)"
            entity.airline = "Sample Airlines"
            entity.location = "EGLL"
            entity.aircraftType = "A320"
            entity.timestamp = Date().addingTimeInterval(-Double(i) * 86400)
            entity.photo = Data() // Empty data for preview
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Preview data creation failed: \(error)")
        }
        
        return controller
    }()
}
