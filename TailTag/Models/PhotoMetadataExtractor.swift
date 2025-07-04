import Foundation
import ImageIO

struct PhotoMetadataExtractor {
    static func extractDateFromPhoto(_ imageData: Data) -> Date? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }
        
        // Try to get date from EXIF data first (most accurate)
        if let exifDict = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateTimeOriginal = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            return dateFromEXIFString(dateTimeOriginal)
        }
        
        // Fallback to TIFF datetime
        if let tiffDict = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateTime = tiffDict[kCGImagePropertyTIFFDateTime as String] as? String {
            return dateFromEXIFString(dateTime)
        }
        
        // Additional fallback for GPS timestamp
        if let gpsDict = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let gpsDateStamp = gpsDict[kCGImagePropertyGPSDateStamp as String] as? String,
           let gpsTimeStamp = gpsDict[kCGImagePropertyGPSTimeStamp as String] as? String {
            return dateFromGPSData(dateStamp: gpsDateStamp, timeStamp: gpsTimeStamp)
        }
        
        return nil
    }
    
    private static func dateFromEXIFString(_ exifDateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: exifDateString)
    }
    
    private static func dateFromGPSData(dateStamp: String, timeStamp: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let combinedString = "\(dateStamp) \(timeStamp)"
        return formatter.date(from: combinedString)
    }
}
