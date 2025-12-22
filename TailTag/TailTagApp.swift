import SwiftUI
import CoreData

@main
struct TailTagApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var spottingStore = SpottingStore()
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(spottingStore)
                .environmentObject(appSettings)
        }
    }
}


