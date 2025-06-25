import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var spottingStore: SpottingStore
    @State private var showResetConfirmation = false
    
    var body: some View {
        Section("App") {
            Link(destination: URL(string: "mailto:support@tailtag.app?subject=TailTag%20App%20Support")!) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(appSettings.accentColor)
                        .frame(width: 25)
                    Text("Need Help?")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.red)
                        .frame(width: 25)
                    Text("Reset All Settings")
                }
            }
            .alert("Reset All Settings", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAppSettings()
                }
            } message: {
                Text("This will reset all app settings to their defaults and clear all spotting data. This action cannot be undone.")
            }
        }
    }
    
    private func resetAppSettings() {
        appSettings.accentColor = .blue
        appSettings.colorScheme = nil
        appSettings.currentAppIcon = nil
        
        spottingStore.clearAllEntries()
    }
}

#Preview {
    List {
        AppSettingsView()
            .environmentObject(AppSettings())
            .environmentObject(SpottingStore())
    }
}
