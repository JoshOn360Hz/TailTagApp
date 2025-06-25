import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "airplane.circle")
                .font(.system(size: 80))
                .foregroundStyle(appSettings.accentColor.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Aircraft Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the + button to add your first aircraft")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView()
        .environmentObject(AppSettings())
}
