import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        Section("About") {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(appSettings.accentColor)
                    .frame(width: 25)
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://appsbyjosh.com/tailtag.html")!) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(appSettings.accentColor)
                        .frame(width: 25)
                    Text("TailTag Website")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    List {
        AboutSettingsView()
            .environmentObject(AppSettings())
    }
}
