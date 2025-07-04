import SwiftUI

struct ContentView: View {
    @StateObject private var spottingStore = SpottingStore()
    @StateObject private var appSettings = AppSettings()
    
    var body: some View {
        Group {
            if appSettings.hasCompletedOnboarding {
                mainAppView
            } else {
                OnboardingView {
                    appSettings.hasCompletedOnboarding = true
                }
                .environmentObject(appSettings)
            }
        }
    }
    
    private var mainAppView: some View {
        TabView {
            RecentView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("Recent")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(appSettings.accentColor)
        .preferredColorScheme(appSettings.colorScheme)
        .environmentObject(spottingStore)
        .environmentObject(appSettings)
    }
}




