import SwiftUI

struct AccentColorPickerView: View {
    @ObservedObject var settings: AppSettings
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accent Color")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(AccentColorOption.defaultOptions) { option in
                    Button(action: {
                        settings.accentColor = option.color
                    }) {
                        ZStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 44, height: 44)
                                .shadow(color: Color(.systemGray3).opacity(0.3), radius: 4, x: 0, y: 2)

                            if isColorSelected(option.color) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 18, height: 18)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(option.color)
                                }
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.3), value: settings.accentColor.description)
                            }
                        }
                        .accessibilityLabel(option.name)
                        .accessibilityAddTraits(isColorSelected(option.color) ? .isSelected : [])
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func isColorSelected(_ color: Color) -> Bool {
        color.description == settings.accentColor.description
    }
}

