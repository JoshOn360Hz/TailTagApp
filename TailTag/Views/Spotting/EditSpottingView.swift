import SwiftUI
import PhotosUI

struct EditSpottingView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    let spotting: SpottingEntry
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data
    @State private var registration: String
    @State private var airline: String
    @State private var location: String
    @State private var aircraftType: String
    @State private var notes: String
    @State private var timestamp: Date
    @State private var showingDeleteAlert = false
    
    init(spotting: SpottingEntry) {
        self.spotting = spotting
        _photoData = State(initialValue: spotting.photo)
        _registration = State(initialValue: spotting.registration)
        _airline = State(initialValue: spotting.airline)
        _location = State(initialValue: spotting.location)
        _aircraftType = State(initialValue: spotting.aircraftType ?? "")
        _notes = State(initialValue: spotting.notes ?? "")
        _timestamp = State(initialValue: spotting.timestamp)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Photo") {
                    HStack {
                        if let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "camera")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Change Photo")
                                .foregroundColor(appSettings.accentColor)
                        }
                        
                        Spacer()
                    }
                }
                
                Section("Aircraft Details") {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(appSettings.accentColor)
                            .frame(width: 25)
                        TextField("Registration", text: $registration)
                    }
                    
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(appSettings.accentColor)
                            .frame(width: 25)
                        TextField("Airline", text: $airline)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(appSettings.accentColor)
                            .frame(width: 25)
                        TextField("Location", text: $location)
                    }
                    
                    HStack {
                        Image(systemName: "airplane.circle")
                            .foregroundColor(appSettings.accentColor)
                            .frame(width: 25)
                        TextField("Aircraft Type (Optional)", text: $aircraftType)
                    }
                }
                
                Section("Additional Info") {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(appSettings.accentColor)
                            .frame(width: 25)
                        DatePicker("Date Spotted", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(appSettings.accentColor)
                            .frame(width: 25)
                            .padding(.top, 8)
                        TextField("Notes (Optional)", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Spotting")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidEntry)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                if let newPhoto = newPhoto,
                   let data = try? await newPhoto.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
        .alert("Delete Spotting", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSpotting()
            }
        } message: {
            Text("This will permanently delete this spotting. This action cannot be undone.")
        }
    }
    
    private var isValidEntry: Bool {
        !registration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !airline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveChanges() {
        var updatedSpotting = spotting
        updatedSpotting.photo = photoData
        updatedSpotting.registration = registration.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSpotting.airline = airline.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSpotting.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSpotting.aircraftType = aircraftType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : aircraftType.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSpotting.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSpotting.timestamp = timestamp
        
        spottingStore.updateSpotting(updatedSpotting)
        dismiss()
    }
    
    private func deleteSpotting() {
        spottingStore.deleteSpotting(spotting)
        dismiss()
    }
}

