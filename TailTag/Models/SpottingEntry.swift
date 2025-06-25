import SwiftUI
import Foundation

struct SpottingEntry: Identifiable, Hashable, Codable {
    let id: UUID
    var photo: Data
    var registration: String
    var airline: String
    var location: String
    var aircraftType: String?
    var notes: String?
    var timestamp: Date
    
    init(photo: Data, registration: String, airline: String, location: String, aircraftType: String? = nil, notes: String? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.photo = photo
        self.registration = registration
        self.airline = airline
        self.location = location
        self.aircraftType = aircraftType
        self.notes = notes
        self.timestamp = timestamp
    }
}

