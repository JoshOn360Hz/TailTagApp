import SwiftUI
import PhotosUI
import Vision

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
    @State private var isDateFromPhoto = false
    @State private var isRegistrationFromPhoto = false
    @State private var isAirlineFromPhoto = false
    @State private var isProcessingImage = false
    
    private let textDetector = AircraftTextDetector()
    
    private var canSave: Bool {
        photoData != nil && !registration.isEmpty && !airline.isEmpty && !location.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
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
                        Task { @MainActor in
                            guard !isProcessingImage else { return }
                            isProcessingImage = true
                            
                            defer { isProcessingImage = false }
                            
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                // Compress image data immediately to prevent memory issues
                                let compressedData = SpottingStore.compressImageData(data)
                                photoData = compressedData
                                
                                if let photoDate = PhotoMetadataExtractor.extractDateFromPhoto(data) {
                                    timestamp = photoDate
                                    isDateFromPhoto = true
                                } else {
                                    isDateFromPhoto = false
                                }
                                
                                // Use compressed data for detection to reduce memory usage
                                if let uiImage = UIImage(data: compressedData) {
                                    await detectAircraftInfoFromImage(uiImage)
                                }
                            }
                        }
                    }
                }
                
                Section("Aircraft Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Registration ", text: $registration)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: registration) { _, _ in
                                isRegistrationFromPhoto = false
                            }
                        
                        if isRegistrationFromPhoto {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(appSettings.accentColor)
                                    .font(.caption)
                                Text("Registration detected from photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Airline", text: $airline)
                            .onChange(of: airline) { _, _ in
                                isAirlineFromPhoto = false
                            }
                        
                        if isAirlineFromPhoto {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(appSettings.accentColor)
                                    .font(.caption)
                                Text("Airline detected from photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
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
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker("Date Spotted", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                            .onChange(of: timestamp) { _, _ in
                                isDateFromPhoto = false
                            }
                        
                        if isDateFromPhoto {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(appSettings.accentColor)
                                    .font(.caption)
                                Text("Date automatically set from photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
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
        guard let photoData = photoData else {
            print("Error: Cannot save entry without photo")
            return
        }
        
        let entry = SpottingEntry(
            photo: photoData,
            registration: registration.trimmingCharacters(in: .whitespacesAndNewlines),
            airline: airline.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            aircraftType: aircraftType.isEmpty ? nil : aircraftType.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: timestamp
        )
        
        Task { @MainActor in
            spottingStore.addEntry(entry)
            dismiss()
        }
    }
    
    private func detectAircraftInfoFromImage(_ image: UIImage) async {
        await withCheckedContinuation { continuation in
            textDetector.detectAircraftInfo(in: image) { result in
                Task { @MainActor in
                    guard !Task.isCancelled else {
                        continuation.resume()
                        return
                    }
                    
                    if let detectedRegistration = result.registration,
                       result.confidence > 0.6,
                       self.registration.isEmpty {
                        self.registration = detectedRegistration
                        self.isRegistrationFromPhoto = true
                    }
                    
                    if let detectedAirline = result.airline,
                       result.confidence > 0.6,
                       self.airline.isEmpty {
                        self.airline = detectedAirline
                        self.isAirlineFromPhoto = true
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: min(maxDimension, size.width), height: min(maxDimension, size.width) / aspectRatio)
        } else {
            newSize = CGSize(width: min(maxDimension, size.height) * aspectRatio, height: min(maxDimension, size.height))
        }
        
        if newSize.width < size.width || newSize.height < size.height {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resizedImage ?? image
        }
        
        return image
    }
}

#Preview {
    AddSpottingView()
        .environmentObject(SpottingStore())
        .environmentObject(AppSettings())
}
