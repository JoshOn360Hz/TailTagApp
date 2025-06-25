import SwiftUI
import PhotosUI

struct AddSpottingView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var registration = ""
    @State private var airline = ""
    @State private var location = ""
    @State private var aircraftType = ""
    @State private var notes = ""
    @State private var timestamp = Date()
    
    private var canSave: Bool {
        !registration.isEmpty && !airline.isEmpty && !location.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Photo Picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Add Photo", systemImage: "camera")
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                }
                
                Section("Aircraft Details") {
                    TextField("Registration ", text: $registration)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("Airline", text: $airline)
                    
                    TextField("Location (e.g., EGLL or Heathrow)", text: $location)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("Aircraft Type", text: $aircraftType)
                        .textInputAutocapitalization(.characters)
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Date & Time") {
                    DatePicker("Date Spotted", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Add Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSpotting()
                    }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? appSettings.accentColor : .secondary)
                }
            }
        }
    }
    
    private func saveSpotting() {
        let entry = SpottingEntry(
            photo: photoData ?? Data(),
            registration: registration.trimmingCharacters(in: .whitespacesAndNewlines),
            airline: airline.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            aircraftType: aircraftType.isEmpty ? nil : aircraftType.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: timestamp
        )
        
        spottingStore.addEntry(entry)
        dismiss()
    }
}

#Preview {
    AddSpottingView()
        .environmentObject(SpottingStore())
        .environmentObject(AppSettings())
}
