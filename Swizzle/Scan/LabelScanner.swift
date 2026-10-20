import UIKit
import Vision

/// Reads bottle labels on the device: Vision finds the text in the photo, then each line is matched
/// against the catalog's brand names and label words (bottles.json `aliases`).
enum LabelScanner {
    static func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false
                do {
                    try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
                    let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: lines)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// One entry per catalog bottle found, labelled with the line of text that named it.
    static func bottles(in lines: [String], catalog: Catalog) -> [DetectedBottle] {
        var found: [DetectedBottle] = []
        var seen = Set<String>()
        for line in lines {
            let text = " \(Catalog.normalize(line)) "
            guard let match = catalog.labelTerms.first(where: { text.contains(" \($0.term) ") }),
                  !seen.contains(match.key) else { continue }
            seen.insert(match.key)
            found.append(DetectedBottle(label: displayLabel(line), key: match.key))
        }
        return found
    }

    /// Labels are often all caps; show them in title case.
    private static func displayLabel(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = trimmed == trimmed.uppercased() ? trimmed.capitalized : trimmed
        return String(label.prefix(80))
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
