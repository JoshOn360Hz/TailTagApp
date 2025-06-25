import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var spottingStore: SpottingStore
    
    var body: some View {
        NavigationView {
            List {
                AppearanceSettingsView(settings: appSettings)
                
                AppSettingsView()
                
                AboutSettingsView()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
    }
}


