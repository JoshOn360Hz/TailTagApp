import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case aircraftTypeAZ = "Aircraft Type (A-Z)"
    case aircraftTypeZA = "Aircraft Type (Z-A)"
    case airlineAZ = "Airline (A-Z)"
    case airlineZA = "Airline (Z-A)"
    case registrationAZ = "Registration (A-Z)"
    case registrationZA = "Registration (Z-A)"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dateNewest, .dateOldest:
            return "calendar"
        case .aircraftTypeAZ, .aircraftTypeZA:
            return "airplane.departure"
        case .airlineAZ, .airlineZA:
            return "building.2"
        case .registrationAZ, .registrationZA:
            return "number"
        }
    }
}
