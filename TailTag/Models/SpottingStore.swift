import SwiftUI
import Foundation
import Combine
import CoreData

@MainActor
class SpottingStore: ObservableObject {
    @Published var entries: [SpottingEntry] = []
    
    private let persistenceController: PersistenceController
    private let viewContext: NSManagedObjectContext
    private let userDefaults = UserDefaults.standard
    private let migrationKey = "HasMigratedToCoreData"
    private let oldEntriesKey = "SpottingEntries"
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        
        // Migrate from UserDefaults on first launch
        migrateFromUserDefaultsIfNeeded()
        
        // Load entries from Core Data
        loadEntries()
    }
    
    // MARK: - Migration from UserDefaults
    private func migrateFromUserDefaultsIfNeeded() {
        // Check if already migrated
        guard !userDefaults.bool(forKey: migrationKey) else { return }
        
        // Try to load old data from UserDefaults
        guard let data = userDefaults.data(forKey: oldEntriesKey),
              let oldEntries = try? JSONDecoder().decode([SpottingEntry].self, from: data),
              !oldEntries.isEmpty else {
            // No data to migrate or already empty
            userDefaults.set(true, forKey: migrationKey)
            return
        }
        
        print("Migrating \(oldEntries.count) entries from UserDefaults to Core Data...")
        
        // Migrate each entry to Core Data
        for entry in oldEntries {
            let entity = SpottingEntryEntity(context: viewContext)
            entity.id = entry.id
            entity.photos = entry.photos.map { SpottingStore.compressImageData($0) }
            entity.photo = entry.photos.first.map { SpottingStore.compressImageData($0) } // Keep for backward compatibility
            entity.registration = entry.registration
            entity.airline = entry.airline
            entity.location = entry.location
            entity.aircraftType = entry.aircraftType
            entity.notes = entry.notes
            entity.timestamp = entry.timestamp
        }
        
        // Save to Core Data
        do {
            try viewContext.save()
            // Mark migration as complete
            userDefaults.set(true, forKey: migrationKey)
            // Remove old data from UserDefaults
            userDefaults.removeObject(forKey: oldEntriesKey)
            print("Migration completed successfully!")
        } catch {
            print("Migration failed: \(error.localizedDescription)")
        }
    }
    
    // Compress image data for storage optimization
    static func compressImageData(_ data: Data, maxSizeKB: Int = 800) -> Data {
        guard let image = UIImage(data: data) else { return data }
        
        // Start with higher quality and reduce if needed
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        let maxBytes = maxSizeKB * 1024
        
        // Reduce quality until under size limit
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        // If still too large, resize the image
        if let data = imageData, data.count > maxBytes {
            let scale = sqrt(Double(maxBytes) / Double(data.count))
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            imageData = resizedImage?.jpegData(compressionQuality: 0.7)
        }
        
        return imageData ?? data
    }
    
    // MARK: - Core Data Operations
    private func loadEntries() {
        let fetchRequest: NSFetchRequest<SpottingEntryEntity> = SpottingEntryEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SpottingEntryEntity.timestamp, ascending: false)]
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            entries = entities.compactMap { entity in
                guard let id = entity.id,
                      let registration = entity.registration,
                      let airline = entity.airline,
                      let location = entity.location,
                      let timestamp = entity.timestamp else {
                    return nil
                }
                
                // Try to load photos array first, fallback to single photo for backward compatibility
                var photosList: [Data] = []
                if let photos = entity.photos as? [Data] {
                    photosList = photos
                } else if let photo = entity.photo {
                    photosList = [photo]
                }
                
                guard !photosList.isEmpty else { return nil }
                
                return SpottingEntry(
                    id: id,
                    photos: photosList,
                    registration: registration,
                    airline: airline,
                    location: location,
                    aircraftType: entity.aircraftType,
                    notes: entity.notes,
                    timestamp: timestamp
                )
            }
        } catch {
            print("Error loading entries from Core Data: \(error.localizedDescription)")
            entries = []
        }
    }
    
    private func saveContext() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
            loadEntries() // Refresh entries array
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CRUD Operations
    func addEntry(_ entry: SpottingEntry) {
        let entity = SpottingEntryEntity(context: viewContext)
        entity.id = entry.id
        entity.photos = entry.photos.map { SpottingStore.compressImageData($0) }
        entity.photo = entry.photos.first.map { SpottingStore.compressImageData($0) } // Keep for backward compatibility
        entity.registration = entry.registration
        entity.airline = entry.airline
        entity.location = entry.location
        entity.aircraftType = entry.aircraftType
        entity.notes = entry.notes
        entity.timestamp = entry.timestamp
        
        saveContext()
    }
    
    func deleteEntry(_ entry: SpottingEntry) {
        let fetchRequest: NSFetchRequest<SpottingEntryEntity> = SpottingEntryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            entities.forEach { viewContext.delete($0) }
            saveContext()
        } catch {
            print("Error deleting entry: \(error.localizedDescription)")
        }
    }
    
    func clearAllEntries() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SpottingEntryEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
            loadEntries()
        } catch {
            print("Error clearing entries: \(error.localizedDescription)")
        }
    }
    
    
    func filteredEntries(searchText: String) -> [SpottingEntry] {
        guard !searchText.isEmpty else { return entries }
        
        return entries.filter { entry in
            entry.registration.localizedCaseInsensitiveContains(searchText) ||
            entry.airline.localizedCaseInsensitiveContains(searchText) ||
            entry.location.localizedCaseInsensitiveContains(searchText) ||
            (entry.aircraftType?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    
    var mostRecentEntries: [SpottingEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }
    
    
    func updateSpotting(_ updatedSpotting: SpottingEntry) {
        let fetchRequest: NSFetchRequest<SpottingEntryEntity> = SpottingEntryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", updatedSpotting.id as CVarArg)
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            if let entity = entities.first {
                entity.photos = updatedSpotting.photos.map { SpottingStore.compressImageData($0) }
                entity.photo = updatedSpotting.photos.first.map { SpottingStore.compressImageData($0) } // Keep for backward compatibility
                entity.registration = updatedSpotting.registration
                entity.airline = updatedSpotting.airline
                entity.location = updatedSpotting.location
                entity.aircraftType = updatedSpotting.aircraftType
                entity.notes = updatedSpotting.notes
                entity.timestamp = updatedSpotting.timestamp
                saveContext()
            }
        } catch {
            print("Error updating entry: \(error.localizedDescription)")
        }
    }
    
    func deleteSpotting(_ spotting: SpottingEntry) {
        deleteEntry(spotting)
    }
    
    
    func sortedEntries(by sortOption: SortOption) -> [SpottingEntry] {
        switch sortOption {
        case .dateNewest:
            return entries.sorted { $0.timestamp > $1.timestamp }
        case .dateOldest:
            return entries.sorted { $0.timestamp < $1.timestamp }
        case .aircraftTypeAZ:
            return entries.sorted { 
                let type1 = $0.aircraftType?.lowercased() ?? ""
                let type2 = $1.aircraftType?.lowercased() ?? ""
                return type1 < type2
            }
        case .aircraftTypeZA:
            return entries.sorted { 
                let type1 = $0.aircraftType?.lowercased() ?? ""
                let type2 = $1.aircraftType?.lowercased() ?? ""
                return type1 > type2
            }
        case .airlineAZ:
            return entries.sorted { $0.airline.lowercased() < $1.airline.lowercased() }
        case .airlineZA:
            return entries.sorted { $0.airline.lowercased() > $1.airline.lowercased() }
        case .registrationAZ:
            return entries.sorted { $0.registration.lowercased() < $1.registration.lowercased() }
        case .registrationZA:
            return entries.sorted { $0.registration.lowercased() > $1.registration.lowercased() }
        }
    }
    
    func filteredAndSortedEntries(searchText: String, sortOption: SortOption) -> [SpottingEntry] {
        let filtered = filteredEntries(searchText: searchText)
        return sortEntries(filtered, by: sortOption)
    }
    
    private func sortEntries(_ entries: [SpottingEntry], by sortOption: SortOption) -> [SpottingEntry] {
        switch sortOption {
        case .dateNewest:
            return entries.sorted { $0.timestamp > $1.timestamp }
        case .dateOldest:
            return entries.sorted { $0.timestamp < $1.timestamp }
        case .aircraftTypeAZ:
            return entries.sorted { 
                let type1 = $0.aircraftType?.lowercased() ?? ""
                let type2 = $1.aircraftType?.lowercased() ?? ""
                return type1 < type2
            }
        case .aircraftTypeZA:
            return entries.sorted { 
                let type1 = $0.aircraftType?.lowercased() ?? ""
                let type2 = $1.aircraftType?.lowercased() ?? ""
                return type1 > type2
            }
        case .airlineAZ:
            return entries.sorted { $0.airline.lowercased() < $1.airline.lowercased() }
        case .airlineZA:
            return entries.sorted { $0.airline.lowercased() > $1.airline.lowercased() }
        case .registrationAZ:
            return entries.sorted { $0.registration.lowercased() < $1.registration.lowercased() }
        case .registrationZA:
            return entries.sorted { $0.registration.lowercased() > $1.registration.lowercased() }
        }
    }
}
