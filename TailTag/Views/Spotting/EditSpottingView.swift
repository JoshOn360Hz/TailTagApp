import SwiftUI
import PhotosUI
import Vision

struct EditSpottingView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    let spotting: SpottingEntry
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var registration: String
    @State private var airline: String
    @State private var location: String
    @State private var aircraftType: String
    @State private var notes: String
    @State private var timestamp: Date
    @State private var showingDeleteAlert = false
    @State private var isDateFromPhoto = false
    @State private var isRegistrationFromPhoto = false
    @State private var isAirlineFromPhoto = false
    
    private let textDetector = AircraftTextDetector()
    
    init(spotting: SpottingEntry) {
        self.spotting = spotting
        _photoData = State(wrappedValue: spotting.photo)
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
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(appSettings.accentColor)
                                .frame(width: 25)
                            TextField("Registration", text: $registration)
                                .onChange(of: registration) { _, _ in
                                    isRegistrationFromPhoto = false
                                }
                        }
                        
                        if isRegistrationFromPhoto {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(appSettings.accentColor)
                                    .font(.caption)
                                    .frame(width: 25)
                                Text("Registration detected from photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "airplane")
                                .foregroundColor(appSettings.accentColor)
                                .frame(width: 25)
                            TextField("Airline", text: $airline)
                                .onChange(of: airline) { _, _ in
                                    isAirlineFromPhoto = false
                                }
                        }
                        
                        if isAirlineFromPhoto {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(appSettings.accentColor)
                                    .font(.caption)
                                    .frame(width: 25)
                                Text("Airline detected from photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(appSettings.accentColor)
                                .frame(width: 25)
                            DatePicker("Date Spotted", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                                .onChange(of: timestamp) { _, _ in
                                    isDateFromPhoto = false
                                }
                        }
                        
                        if isDateFromPhoto {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(appSettings.accentColor)
                                    .font(.caption)
                                    .frame(width: 25)
                                Text("Date automatically set from photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
            Task { @MainActor in
                guard let newPhoto = newPhoto else { return }
                do {
                    // loadTransferable may return optional Data
                    if let data = try await newPhoto.loadTransferable(type: Data.self) {
                        // Compress image before storing to prevent memory issues
                        let compressedData = SpottingStore.compressImageData(data)
                        photoData = compressedData

                        // Extract date from photo metadata
                        if let photoDate = PhotoMetadataExtractor.extractDateFromPhoto(data) {
                            timestamp = photoDate
                            isDateFromPhoto = true
                        } else {
                            isDateFromPhoto = false
                        }

                        // Detect aircraft information from photo using compressed version
                        if let uiImage = UIImage(data: compressedData) {
                            detectAircraftInfoFromImage(uiImage)
                        }
                    } else {
                        // No transferable data loaded
                        isDateFromPhoto = false
                    }
                } catch {
                    // Handle any transfer errors gracefully
                    isDateFromPhoto = false
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
        guard let photoData = photoData else { return }
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
    
    private func detectAircraftInfoFromImage(_ image: UIImage) {
        textDetector.detectAircraftInfo(in: image) { result in
            DispatchQueue.main.async {
                // Auto-fill registration if detected and current field is empty or matches original
                if let detectedRegistration = result.registration,
                   result.confidence > 0.6,
                   (self.registration.isEmpty || self.registration == self.spotting.registration) {
                    self.registration = detectedRegistration
                    self.isRegistrationFromPhoto = true
                }
                
                // Auto-fill airline if detected and current field is empty or matches original
                if let detectedAirline = result.airline,
                   result.confidence > 0.6,
                   (self.airline.isEmpty || self.airline == self.spotting.airline) {
                    self.airline = detectedAirline
                    self.isAirlineFromPhoto = true
                }
            }
        }
    }
}

