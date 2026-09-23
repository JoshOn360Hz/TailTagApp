import SwiftUI

struct SettingsColorSchemePickerView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Scheme")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                
                // Sliding selection indicator
                GeometryReader { geometry in
                    let segmentWidth = geometry.size.width / CGFloat(3)
                    let selectedIndex = settings.colorScheme == .light ? 1 : (settings.colorScheme == .dark ? 2 : 0)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(settings.accentColor)
                        .frame(width: segmentWidth - 8) 
                        .padding(4)
                        .offset(x: CGFloat(selectedIndex) * segmentWidth)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: settings.colorScheme)
                }
                
                // Buttons row
                HStack(spacing: 0) {
                    ForEach([ColorScheme?.none, ColorScheme.light, ColorScheme.dark], id: \.self) { scheme in
                        Button(action: {
                            settings.colorScheme = scheme
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: iconForScheme(scheme))
                                    .font(.system(size: 22))
                                    .foregroundColor(settings.colorScheme == scheme ? .white : .secondary)
                                
                                Text(titleForScheme(scheme))
                                    .font(.caption)
                                    .fontWeight(settings.colorScheme == scheme ? .semibold : .regular)
                                    .foregroundColor(settings.colorScheme == scheme ? .white : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(height: 80)
        }
        .padding(.vertical, 8)
    }
    
    private func iconForScheme(_ scheme: ColorScheme?) -> String {
        switch scheme {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        default:
            return "circle.lefthalf.filled"
        }
    }
    
    private func titleForScheme(_ scheme: ColorScheme?) -> String {
        switch scheme {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        default:
            return "System"
        }
    }
}

