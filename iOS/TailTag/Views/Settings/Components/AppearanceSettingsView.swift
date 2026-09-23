import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section("Appearance") {
            AccentColorPickerView(settings: settings)
            
            SettingsColorSchemePickerView(settings: settings)
            
            NavigationLink(destination: AppIconPickerView(currentIcon: $settings.currentAppIcon)) {
                HStack {
                    Image(systemName: "app.fill")
                        .foregroundColor(settings.accentColor)
                        .frame(width: 25)
                    Text("App Icon")
                    Spacer()
                }
            }
        }
    }
}


