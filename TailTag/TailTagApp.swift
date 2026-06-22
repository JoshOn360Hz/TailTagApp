import AppIntents
import SwiftUI
import CoreData

@main
struct TailTagApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var spottingStore = SpottingStore()
    @StateObject private var appSettings = AppSettings()
    @StateObject private var intentRouter = TailTagIntentRouter()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(spottingStore)
                .environmentObject(appSettings)
                .environmentObject(intentRouter)
                .task {
                    TailTagShortcutsProvider.updateAppShortcutParameters()
                    do {
                        try await TailTagSpotlightIndexer.indexAllSpottingEntries()
                    } catch {
                        print("Spotlight indexing failed: \(error.localizedDescription)")
                    }
                }
        }
    }
}


