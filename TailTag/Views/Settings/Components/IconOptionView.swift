import SwiftUI

struct IconOptionView: View {
    let option: (name: String, filename: String?)
    let isSelected: Bool
    @EnvironmentObject private var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 8) {
            iconImage
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(16)
                .frame(width: 72, height: 72)
            
            Text(option.name)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? settings.accentColor : Color.clear, lineWidth: 3)
        )
    }
    
    private var iconImage: Image {
#if canImport(UIKit)
        let iconName = option.filename ?? "icon-default"
        if let uiImage = UIImage(named: iconName) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "app.fill")
        }
#else
        return Image(systemName: "app.fill")
#endif
    }
}

#Preview {
    HStack {
        IconOptionView(option: ("Default", nil), isSelected: true)
            .environmentObject(AppSettings())
        IconOptionView(option: ("Blue", "icon-blue"), isSelected: false)
            .environmentObject(AppSettings())
    }
    .padding()
}
