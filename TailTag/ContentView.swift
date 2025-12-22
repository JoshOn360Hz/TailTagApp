import SwiftUI

enum TailTagTab {
    case recent
    case search
    case settings
}

struct ContentView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedTab: TailTagTab = .recent

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
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Recent", systemImage: "clock", value: TailTagTab.recent) {
                    RecentView()
                        .environmentObject(spottingStore)
                        .environmentObject(appSettings)
                }

                Tab("Search", systemImage: "magnifyingglass", value: TailTagTab.search, role: .search) {
                    SearchView()
                        .environmentObject(spottingStore)
                        .environmentObject(appSettings)
                }

                Tab("Settings", systemImage: "gearshape", value: TailTagTab.settings) {
                    SettingsView()
                        .environmentObject(spottingStore)
                        .environmentObject(appSettings)
                }
            }
            .accentColor(appSettings.accentColor)
            .preferredColorScheme(appSettings.colorScheme)
            .tabViewStyle(.tabBarOnly)

        } else {
            TabView(selection: $selectedTab) {
                Tab("Recent", systemImage: "clock", value: TailTagTab.recent) {
                    RecentView()
                        .environmentObject(spottingStore)
                        .environmentObject(appSettings)
                }

                Tab("Search", systemImage: "magnifyingglass", value: TailTagTab.search) {
                    SearchView()
                        .environmentObject(spottingStore)
                        .environmentObject(appSettings)
                }

                Tab("Settings", systemImage: "gearshape", value: TailTagTab.settings) {
                    SettingsView()
                        .environmentObject(spottingStore)
                        .environmentObject(appSettings)
                }
            }
            .accentColor(appSettings.accentColor)
            .preferredColorScheme(appSettings.colorScheme)
            .tabViewStyle(.tabBarOnly)
        }
    }
}
