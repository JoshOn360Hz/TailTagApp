import SwiftUI
import Foundation
import Combine

class SpottingStore: ObservableObject {
    @Published var entries: [SpottingEntry] = []
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "SpottingEntries"
    
    init() {
        loadEntries()
    }
    
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = userDefaults.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([SpottingEntry].self, from: data) {
            self.entries = decoded
        } else {
            // Start with empty entries for fresh install
            self.entries = []
        }
    }
    
    
    func addEntry(_ entry: SpottingEntry) {
        entries.insert(entry, at: 0) // Add to beginning for "most recent" order
        saveEntries()
    }
    
    func deleteEntry(_ entry: SpottingEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func clearAllEntries() {
        entries.removeAll()
        saveEntries()
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
        if let index = entries.firstIndex(where: { $0.id == updatedSpotting.id }) {
            entries[index] = updatedSpotting
            saveEntries()
        }
    }
    
    func deleteSpotting(_ spotting: SpottingEntry) {
        entries.removeAll { $0.id == spotting.id }
        saveEntries()
    }
}
