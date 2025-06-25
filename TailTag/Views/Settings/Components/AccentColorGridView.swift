import SwiftUI

struct AccentColorGridView: View {
    @Binding var selectedColor: Color
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accent Color")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AccentColorOption.defaultOptions) { option in
                    Button {
                        selectedColor = option.color
                    } label: {
                        ZStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 40, height: 40)
                            
                            if isColorSelected(option.color) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func isColorSelected(_ color: Color) -> Bool {
        color.description == selectedColor.description
    }
}

#Preview {
    AccentColorGridView(selectedColor: .constant(.blue))
        .padding()
}
