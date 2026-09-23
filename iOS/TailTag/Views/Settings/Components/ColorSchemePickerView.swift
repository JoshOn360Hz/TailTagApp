import SwiftUI

struct ColorSchemePickerView: View {
    @Binding var selectedScheme: ColorScheme?
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color Scheme")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 8) {
                ForEach(AppColorScheme.allCases) { scheme in
                    Button {
                        selectedScheme = scheme.colorScheme
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: scheme.icon)
                                .font(.title2)
                            
                            Text(scheme.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(isSchemeSelected(scheme) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isSchemeSelected(scheme) 
                            ? appSettings.accentColor 
                            : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                .opacity(isSchemeSelected(scheme) ? 0 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func isSchemeSelected(_ scheme: AppColorScheme) -> Bool {
        scheme.colorScheme == selectedScheme
    }
}

