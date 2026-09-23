import SwiftUI

struct AppIconPickerView: View {
    @Binding var currentIcon: String?
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    let iconOptions: [(name: String, filename: String?)] = [
        ("Default", nil),
        ("Dark Blue", "icon-dark-blue"),
        ("Dark Green", "icon-dark-green"),
        ("Dark Mint", "icon-dark-mint"),
        ("Dark Orange", "icon-dark-orange"),
        ("Dark Purple", "icon-dark-purple"),
        ("Dark Red", "icon-dark-red"),
        ("Light Green", "icon-light-green"),
        ("Light Mint", "icon-light-mint"),
        ("Light Orange", "icon-light-orange"),
        ("Light Purple", "icon-light-purple"),
        ("Light Red", "icon-light-red")
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 20) {
                ForEach(iconOptions, id: \.filename) { option in
                    Button {
                        selectIcon(option.filename)
                    } label: {
                        IconOptionView(option: option, isSelected: option.filename == currentIcon)
                            .environmentObject(settings)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func changeAppIcon(to iconName: String?) {
#if canImport(UIKit)
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Failed to change icon: \(error.localizedDescription)")
            } else {
                print("App icon changed to: \(iconName ?? "default")")
            }
        }
#endif
    }
    
    private func selectIcon(_ iconName: String?) {
        changeAppIcon(to: iconName)
        currentIcon = iconName
        settings.currentAppIcon = iconName
        
        // Haptic feedback
#if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
#endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        AppIconPickerView(currentIcon: .constant(nil))
            .environmentObject(AppSettings())
    }
}
