import AppIntents
import CoreSpotlight
import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct TailTagSpottingEntity: IndexedEntity, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "TailTag Spotting"
    static var defaultQuery = TailTagSpottingEntityQuery()

    let id: String
    let registration: String
    let airline: String
    let location: String
    let aircraftType: String?
    let notes: String?
    let timestamp: Date
    let thumbnailData: Data?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(registration)",
            subtitle: "\(airline) at \(location)",
            image: .init(systemName: "airplane")
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .image)
        attributes.title = registration
        attributes.displayName = "\(registration) - \(airline)"
        attributes.namedLocation = location
        attributes.timestamp = timestamp
        attributes.thumbnailData = thumbnailData
        attributes.containerDisplayName = "TailTag"
        attributes.rankingHint = 80
        attributes.userCurated = true

        var descriptionParts = [
            "Aircraft registration: \(registration)",
            "Airline: \(airline)",
            "Location: \(location)",
            "Date spotted: \(DateFormatter.spottingDetail.string(from: timestamp))"
        ]

        if let aircraftType, !aircraftType.isEmpty {
            descriptionParts.append("Aircraft type: \(aircraftType)")
        }

        if let notes, !notes.isEmpty {
            descriptionParts.append("Notes: \(notes)")
        }

        attributes.contentDescription = descriptionParts.joined(separator: "\n")
        attributes.keywords = searchableTerms
        return attributes
    }

    var searchableTerms: [String] {
        [registration, airline, location, aircraftType, notes, DateFormatter.searchFilter.string(from: timestamp)]
            .compactMap { $0 }
            .flatMap { value in
                value
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty }
                    + [value]
            }
    }

    init(
        id: UUID,
        registration: String,
        airline: String,
        location: String,
        aircraftType: String?,
        notes: String?,
        timestamp: Date,
        thumbnailData: Data?
    ) {
        self.id = id.uuidString
        self.registration = registration
        self.airline = airline
        self.location = location
        self.aircraftType = aircraftType
        self.notes = notes
        self.timestamp = timestamp
        self.thumbnailData = thumbnailData
    }

    init(entry: SpottingEntry) {
        self.init(
            id: entry.id,
            registration: entry.registration,
            airline: entry.airline,
            location: entry.location,
            aircraftType: entry.aircraftType,
            notes: entry.notes,
            timestamp: entry.timestamp,
            thumbnailData: entry.photos.first
        )
    }
}

struct TailTagPhotoAssetEntity: AppEntity, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "TailTag Photo"
    static var defaultQuery = TailTagPhotoAssetEntityQuery()

    let id: String
    let spotting: TailTagSpottingEntity
    let photoIndex: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(spotting.registration) photo",
            subtitle: "\(spotting.airline) at \(spotting.location)",
            image: .init(systemName: "photo")
        )
    }
}

struct TailTagSpottingEntityQuery: EntityStringQuery, IndexedEntityQuery {
    func entities(for identifiers: [TailTagSpottingEntity.ID]) async throws -> [TailTagSpottingEntity] {
        await MainActor.run {
            identifiers.compactMap { identifier in
                guard let id = UUID(uuidString: identifier) else { return nil }
                return TailTagSpottingEntityStore.entity(for: id)
            }
        }
    }

    func entities(matching string: String) async throws -> [TailTagSpottingEntity] {
        await MainActor.run {
            TailTagSpottingEntityStore.entities(matching: string)
        }
    }

    func suggestedEntities() async throws -> [TailTagSpottingEntity] {
        await MainActor.run {
            Array(TailTagSpottingEntityStore.allEntities().prefix(8))
        }
    }

    @available(iOS 27.0, *)
    func reindexEntities(for identifiers: [TailTagSpottingEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        let entities = try await entities(for: identifiers)
        try await TailTagSpotlightIndexer.index(entities)
    }

    @available(iOS 27.0, *)
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await TailTagSpotlightIndexer.indexAllSpottingEntries()
    }
}

struct TailTagPhotoAssetEntityQuery: EntityQuery {
    func entities(for identifiers: [TailTagPhotoAssetEntity.ID]) async throws -> [TailTagPhotoAssetEntity] {
        await MainActor.run {
            identifiers.compactMap { identifier in
                let parts = identifier.split(separator: ":")
                guard parts.count == 2,
                      let spottingID = UUID(uuidString: String(parts[0])),
                      let photoIndex = Int(parts[1]),
                      let spotting = TailTagSpottingEntityStore.entity(for: spottingID) else {
                    return nil
                }
                return TailTagPhotoAssetEntity(id: identifier, spotting: spotting, photoIndex: photoIndex)
            }
        }
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenTailTagSpottingIntent: OpenIntent {
    static var title: LocalizedStringResource { "Open TailTag Spotting" }
    static var openAppWhenRun: Bool { true }
    static var supportedModes: IntentModes { [.foreground(.immediate)] }

    var target: TailTagSpottingEntity

    func perform() async throws -> some IntentResult {
        await TailTagIntentRouter.requestSpottingOpen(for: target.id)
        return .result()
    }
}

struct OpenTailTagSpottingShortcutIntent: AppIntent {
    static var title: LocalizedStringResource { "Open TailTag Spotting" }
    static var description: IntentDescription { "Opens a specific aircraft spotting in TailTag." }
    static var openAppWhenRun: Bool { true }
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.foreground(.immediate)] }

    @Parameter(title: "Spotting")
    var spotting: TailTagSpottingEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$spotting)")
    }

    init() { }

    init(spotting: TailTagSpottingEntity) {
        self.spotting = spotting
    }

    func perform() async throws -> some IntentResult {
        await TailTagIntentRouter.requestSpottingOpen(for: spotting.id)
        return .result()
    }
}

struct AddTailTagSpottingIntent: AppIntent {
    static var title: LocalizedStringResource { "Add TailTag Spotting" }
    static var description: IntentDescription { "Opens TailTag ready to add a new aircraft spotting." }
    static var openAppWhenRun: Bool { true }
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.foreground(.immediate)] }

    func perform() async throws -> some IntentResult {
        await TailTagIntentRouter.requestAddSpotting()
        return .result()
    }
}

@MainActor
enum TailTagSpottingEntityStore {
    static func allEntries() -> [SpottingEntry] {
        let descriptor = FetchDescriptor<SpottingRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        do {
            return try ModelContainer.tailTag.mainContext.fetch(descriptor).compactMap { record in
                let photos = record.photos
                guard !photos.isEmpty else { return nil }
                return record.asEntry
            }
        } catch {
            return []
        }
    }

    static func allEntities() -> [TailTagSpottingEntity] {
        allEntries().map(TailTagSpottingEntity.init(entry:))
    }

    static func entity(for id: UUID) -> TailTagSpottingEntity? {
        entry(for: id).map(TailTagSpottingEntity.init(entry:))
    }

    static func entry(for id: UUID) -> SpottingEntry? {
        let descriptor = FetchDescriptor<SpottingRecord>(
            predicate: #Predicate { $0.id == id }
        )
        do {
            guard let record = try ModelContainer.tailTag.mainContext.fetch(descriptor).first else { return nil }
            let photos = record.photos
            guard !photos.isEmpty else { return nil }
            return record.asEntry
        } catch {
            return nil
        }
    }

    static func entities(matching searchText: String) -> [TailTagSpottingEntity] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return allEntities() }

        return allEntries()
            .filter { entry in
                entry.registration.localizedCaseInsensitiveContains(trimmedSearchText) ||
                entry.airline.localizedCaseInsensitiveContains(trimmedSearchText) ||
                entry.location.localizedCaseInsensitiveContains(trimmedSearchText) ||
                entry.aircraftType?.localizedCaseInsensitiveContains(trimmedSearchText) == true ||
                entry.notes?.localizedCaseInsensitiveContains(trimmedSearchText) == true ||
                DateFormatter.searchFilter.string(from: entry.timestamp).localizedCaseInsensitiveContains(trimmedSearchText)
            }
            .map(TailTagSpottingEntity.init(entry:))
    }

    static func suggestedSearchTerms(limit: Int = 12) -> [String] {
        var seenTerms = Set<String>()
        var suggestions: [String] = []

        for entry in allEntries() {
            let candidateTerms = [
                entry.registration,
                entry.location,
                entry.airline,
                entry.aircraftType
            ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }

            for term in candidateTerms where !term.isEmpty {
                let normalizedTerm = term.lowercased()
                guard !seenTerms.contains(normalizedTerm) else { continue }
                seenTerms.insert(normalizedTerm)
                suggestions.append(term)
                if suggestions.count == limit { return suggestions }
            }
        }

        return suggestions
    }
}

enum TailTagSpotlightIndexer {
    static let domainIdentifier = "com.Josh.TailTag.spotting"

    static func indexAllSpottingEntries() async throws {
        let entities = await MainActor.run {
            TailTagSpottingEntityStore.allEntities()
        }
        try await index(entities)
    }

    static func index(_ entry: SpottingEntry) async {
        do {
            try await index([TailTagSpottingEntity(entry: entry)])
        } catch {
            print("Spotlight indexing failed: \(error.localizedDescription)")
        }
    }

    static func index(_ entities: [TailTagSpottingEntity]) async throws {
        let items = entities.map { entity in
            let attributes = entity.attributeSet
            attributes.associateAppEntity(entity, priority: 10)
            return CSSearchableItem(
                uniqueIdentifier: entity.id,
                domainIdentifier: domainIdentifier,
                attributeSet: attributes
            )
        }
        try await CSSearchableIndex.default().indexSearchableItems(items)
    }

    static func deleteSpotting(with id: UUID) async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id.uuidString])
        } catch {
            print("Spotlight deletion failed: \(error.localizedDescription)")
        }
    }

    static func deleteAllSpottingEntries() async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
        } catch {
            print("Spotlight deletion failed: \(error.localizedDescription)")
        }
    }
}
