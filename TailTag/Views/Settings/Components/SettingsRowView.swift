import SwiftUI

struct SettingsRowView: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: (() -> Void)?
    
    init(icon: String, title: String, iconColor: Color = .blue, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsRowView(
        icon: "app.badge",
        title: "App Icon",
        iconColor: .blue
    ) {
        print("Tapped")
    }
    .padding()
}
