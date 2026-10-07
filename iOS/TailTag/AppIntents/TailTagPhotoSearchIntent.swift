import AppIntents
import Combine
import Foundation
import SwiftData
import SwiftUI

struct TailTagSearchEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "TailTag Search"
    static var defaultQuery = TailTagSearchEntityQuery()

    let id: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct TailTagSearchEntityQuery: EntityStringQuery {
    func entities(for identifiers: [TailTagSearchEntity.ID]) async throws -> [TailTagSearchEntity] {
        identifiers.map { TailTagSearchEntity(id: $0) }
    }

    func entities(matching string: String) async throws -> [TailTagSearchEntity] {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return [] }

        return [TailTagSearchEntity(id: trimmedString)]
    }

    func suggestedEntities() async throws -> [TailTagSearchEntity] {
        await MainActor.run {
            TailTagSpottingEntityStore.suggestedSearchTerms()
                .map { TailTagSearchEntity(id: $0) }
        }
    }
}

struct TailTagPhotoSearchIntent: AppIntent {
    static var title: LocalizedStringResource { "Show TailTag Photos" }
    static var description: IntentDescription {
        "Opens TailTag and shows aircraft photos matching a registration, airline, aircraft type, or location."
    }
    static var openAppWhenRun: Bool { true }
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.foreground(.dynamic)] }

    @Parameter(title: "Search", description: "A registration, airline, aircraft type, or location to show in TailTag.")
    var search: TailTagSearchEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Show photos matching \(\.$search)")
    }

    init() { }

    init(searchText: String) {
        self.search = TailTagSearchEntity(id: searchText)
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let searchText = search.id
        let results = await TailTagIntentPhotoSearch.results(matching: searchText)
        let dialog = IntentDialog(
            full: "I found \(results.count) TailTag photo results for \(searchText).",
            supporting: "Found \(results.count) TailTag results."
        )

        await TailTagIntentRouter.requestPhotoSearch(for: searchText)
        return .result(dialog: dialog, view: TailTagPhotoSearchSnippet(searchText: searchText, results: results))
    }
}

@available(iOS 26.0, *)
@AppIntent(schema: .system.search)
struct TailTagSystemSearchIntent: ShowInAppSearchResultsIntent {
    static var searchScopes: [StringSearchScope] = [.general]
    static var openAppWhenRun: Bool { true }
    static var supportedModes: IntentModes { [.foreground(.dynamic)] }

    var criteria: StringSearchCriteria

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let searchText = criteria.term
        let results = await TailTagIntentPhotoSearch.results(matching: searchText)
        let dialog = IntentDialog(
            full: "I found \(results.count) TailTag photo results for \(searchText).",
            supporting: "Found \(results.count) TailTag results."
        )

        await TailTagIntentRouter.requestPhotoSearch(for: searchText)
        return .result(dialog: dialog, view: TailTagPhotoSearchSnippet(searchText: searchText, results: results))
    }
}

struct TailTagShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TailTagPhotoSearchIntent(),
            phrases: [
                "Show photos of \(\.$search) in \(.applicationName)",
                "Show photos at \(\.$search) using \(.applicationName)",
                "Find \(\.$search) in \(.applicationName)",
                "Search \(.applicationName) for \(\.$search)"
            ],
            shortTitle: "Show Photos",
            systemImageName: "airplane"
        )

        AppShortcut(
            intent: AddTailTagSpottingIntent(),
            phrases: [
                "Add a spotting in \(.applicationName)",
                "Add aircraft in \(.applicationName)",
                "Log a plane in \(.applicationName)"
            ],
            shortTitle: "Add Spotting",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: OpenTailTagSpottingShortcutIntent(),
            phrases: [
                "Open \(\.$spotting) in \(.applicationName)",
                "Show \(\.$spotting) in \(.applicationName)"
            ],
            shortTitle: "Open Spotting",
            systemImageName: "arrow.up.forward.app"
        )
    }
}

struct TailTagIntentPhotoResult: Identifiable, Hashable {
    let id: UUID
    let photoData: Data
    let registration: String
    let airline: String
    let location: String
    let aircraftType: String?
    let timestamp: Date

    var spottingEntity: TailTagSpottingEntity {
        TailTagSpottingEntity(
            id: id,
            registration: registration,
            airline: airline,
            location: location,
            aircraftType: aircraftType,
            notes: nil,
            timestamp: timestamp,
            thumbnailData: photoData
        )
    }
}

struct TailTagPhotoSearchSnippet: View {
    let searchText: String
    let results: [TailTagIntentPhotoResult]

    private var visibleResults: [TailTagIntentPhotoResult] {
        Array(results.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TailTag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Photos for \"\(searchText)\"")
                    .font(.headline)
                Text(resultSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if visibleResults.isEmpty {
                Label("No matching aircraft photos", systemImage: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(visibleResults) { result in
                        TailTagPhotoSearchSnippetTile(result: result)
                    }
                }

                HStack {
                    if let firstResult = visibleResults.first {
                        Button(
                            "Open",
                            systemImage: "arrow.up.forward.app",
                            intent: OpenTailTagSpottingShortcutIntent(spotting: firstResult.spottingEntity)
                        )
                    }

                    Button(
                        "Show More",
                        systemImage: "magnifyingglass",
                        intent: TailTagPhotoSearchIntent(searchText: searchText)
                    )
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var resultSummary: String {
        if results.count == 1 {
            return "1 matching spotting"
        }

        return "\(results.count) matching spottings"
    }
}

private struct TailTagPhotoSearchSnippetTile: View {
    let result: TailTagIntentPhotoResult

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = UIImage(data: result.photoData), !result.photoData.isEmpty {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.tertiary)
                    .overlay {
                        Image(systemName: "airplane")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(result.registration)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(result.location)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.45))
        }
        .frame(height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

@MainActor
private enum TailTagIntentPhotoSearch {
    static func results(matching searchText: String) -> [TailTagIntentPhotoResult] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return [] }

        let descriptor = FetchDescriptor<SpottingRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let records = try ModelContainer.tailTag.mainContext.fetch(descriptor)
            return records.compactMap { record in
                guard matches(record: record, searchText: trimmedSearchText) else { return nil }
                return TailTagIntentPhotoResult(
                    id: record.id,
                    photoData: record.photos.first ?? Data(),
                    registration: record.registration,
                    airline: record.airline,
                    location: record.location,
                    aircraftType: record.aircraftType,
                    timestamp: record.timestamp
                )
            }
        } catch {
            return []
        }
    }

    private static func matches(record: SpottingRecord, searchText: String) -> Bool {
        record.registration.localizedCaseInsensitiveContains(searchText) ||
        record.airline.localizedCaseInsensitiveContains(searchText) ||
        record.location.localizedCaseInsensitiveContains(searchText) ||
        record.aircraftType?.localizedCaseInsensitiveContains(searchText) == true
    }
}

@MainActor
final class TailTagIntentRouter: ObservableObject {
    @Published private(set) var searchText: String?
    @Published private(set) var spottingIDToOpen: UUID?
    @Published private(set) var shouldShowAddSpotting = false

    private static let pendingSearchKey = "TailTagPendingPhotoSearchText"
    private static let pendingSpottingOpenKey = "TailTagPendingSpottingOpenID"
    private static let pendingAddSpottingKey = "TailTagPendingAddSpotting"
    private var defaultsObserver: NSObjectProtocol?

    init() {
        consumePendingSearch()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.consumePendingSearch()
            }
        }
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    static func requestPhotoSearch(for searchText: String) async {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return }

        UserDefaults.standard.set(trimmedSearchText, forKey: pendingSearchKey)
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: UserDefaults.standard)
    }

    static func requestSpottingOpen(for spottingID: String) async {
        guard UUID(uuidString: spottingID) != nil else { return }

        UserDefaults.standard.set(spottingID, forKey: pendingSpottingOpenKey)
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: UserDefaults.standard)
    }

    static func requestAddSpotting() async {
        UserDefaults.standard.set(true, forKey: pendingAddSpottingKey)
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: UserDefaults.standard)
    }

    func consumePendingSearch() {
        if let pendingSearchText = UserDefaults.standard.string(forKey: Self.pendingSearchKey) {
            UserDefaults.standard.removeObject(forKey: Self.pendingSearchKey)
            searchText = pendingSearchText
        }

        if let pendingSpottingID = UserDefaults.standard.string(forKey: Self.pendingSpottingOpenKey),
           let spottingID = UUID(uuidString: pendingSpottingID) {
            UserDefaults.standard.removeObject(forKey: Self.pendingSpottingOpenKey)
            spottingIDToOpen = spottingID
        }

        if UserDefaults.standard.bool(forKey: Self.pendingAddSpottingKey) {
            UserDefaults.standard.removeObject(forKey: Self.pendingAddSpottingKey)
            shouldShowAddSpotting = true
        }
    }

    func clearSearchRequest() {
        searchText = nil
    }

    func clearSpottingOpenRequest() {
        spottingIDToOpen = nil
    }

    func clearAddSpottingRequest() {
        shouldShowAddSpotting = false
    }
}
