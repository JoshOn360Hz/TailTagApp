import Vision
import UIKit
import CoreML

class AircraftTextDetector {
    
    struct DetectionResult {
        let registration: String?
        let airline: String?
        let confidence: Float
    }
    
    enum RegistrationFormat {
        case usa           // N12345
        case uk            // G-ABCD
        case germany       // D-ABCD
        case france        // F-ABCD
        case canada        // C-ABCD
        case australia     // VH-ABC
        case unknown
        
        var pattern: String {
            switch self {
            case .usa: return #"N[0-9]{1,5}[A-Z]{0,2}"#
            case .uk: return #"G-[A-Z]{4}"#
            case .germany: return #"D-[A-Z]{4}"#
            case .france: return #"F-[A-Z]{4}"#
            case .canada: return #"C-[A-Z0-9]{4}"#
            case .australia: return #"VH-[A-Z]{3}"#
            case .unknown: return #"[A-Z]{1,2}-?[A-Z0-9]{2,5}"#
            }
        }
    }
    
    // Common airline names
    private let airlines = [
        "AMERICAN", "DELTA", "UNITED", "SOUTHWEST", "JETBLUE", "ALASKA",
        "BRITISH AIRWAYS", "LUFTHANSA", "AIR FRANCE", "KLM", "EMIRATES",
        "QANTAS", "VIRGIN", "RYANAIR", "EASYJET", "NORWEGIAN",
        "CATHAY PACIFIC", "SINGAPORE", "ANA", "JAL", "TURKISH",
        "ETIHAD", "QATAR", "SWISS", "AUSTRIAN", "SAS", "FINNAIR",
        "TAP", "IBERIA", "ALITALIA", "AEROFLOT", "EMIRATES",
        // Airline codes
        "AA", "DL", "UA", "WN", "B6", "AS", "BA", "LH", "AF", "KL",
        "EK", "QF", "VS", "FR", "U2", "DY", "CX", "SQ", "NH", "JL",
        "TK", "EY", "QR", "LX", "OS", "SK", "AY", "TP", "IB", "AZ", "SU"
    ]
    
    func detectAircraftInfo(in image: UIImage, completion: @escaping (DetectionResult) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(DetectionResult(registration: nil, airline: nil, confidence: 0.0))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(DetectionResult(registration: nil, airline: nil, confidence: 0.0))
                return
            }
            
            var bestRegistration: String?
            var bestAirline: String?
            var highestConfidence: Float = 0.0
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                
                let text = topCandidate.string.uppercased()
                let cleanedText = text.replacingOccurrences(of: " ", with: "")
                
                if bestRegistration == nil {
                    for format in [RegistrationFormat.usa, .uk, .germany, .france, .canada, .australia] {
                        if cleanedText.range(of: format.pattern, options: .regularExpression) != nil {
                            bestRegistration = self.cleanRegistration(cleanedText)
                            highestConfidence = max(highestConfidence, topCandidate.confidence)
                            break
                        }
                    }
                }
                
                if bestAirline == nil {
                    for airline in self.airlines {
                        if text.contains(airline) {
                            bestAirline = airline.capitalized
                            highestConfidence = max(highestConfidence, topCandidate.confidence)
                            break
                        }
                    }
                }
                
                if bestRegistration != nil && bestAirline != nil {
                    break
                }
            }
            
            let result = DetectionResult(
                registration: bestRegistration,
                airline: bestAirline,
                confidence: highestConfidence
            )
            
            completion(result)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]
        request.automaticallyDetectsLanguage = false
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Error performing text recognition: \(error)")
                completion(DetectionResult(registration: nil, airline: nil, confidence: 0.0))
            }
        }
    }
    
    private func cleanRegistration(_ text: String) -> String? {
        let cleaned = text.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
        
        for format in [RegistrationFormat.usa, .uk, .germany, .france, .canada, .australia] {
            if cleaned.range(of: format.pattern, options: .regularExpression) != nil {
                return cleaned
            }
        }
        
        return nil
    }
}
