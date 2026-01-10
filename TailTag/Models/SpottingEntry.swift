import SwiftUI
import Foundation

struct SpottingEntry: Identifiable, Hashable, Codable {
    let id: UUID
    var photos: [Data]
    var registration: String
    var airline: String
    var location: String
    var aircraftType: String?
    var notes: String?
    var timestamp: Date
    
    // Computed property for backward compatibility
    var photo: Data {
        photos.first ?? Data()
    }
    
    init(id: UUID = UUID(), photos: [Data], registration: String, airline: String, location: String, aircraftType: String? = nil, notes: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.photos = photos.isEmpty ? [Data()] : photos
        self.registration = registration
        self.airline = airline
        self.location = location
        self.aircraftType = aircraftType
        self.notes = notes
        self.timestamp = timestamp
    }
    
    // Convenience initializer for single photo (backward compatibility)
    init(id: UUID = UUID(), photo: Data, registration: String, airline: String, location: String, aircraftType: String? = nil, notes: String? = nil, timestamp: Date = Date()) {
        self.init(id: id, photos: [photo], registration: registration, airline: airline, location: location, aircraftType: aircraftType, notes: notes, timestamp: timestamp)
    }
}


