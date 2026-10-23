import CoreHaptics
import UIKit

/// The app's few vibrations, so each moment always feels the same.
@MainActor
enum Haptics {
    /// A finished label scan.
    static func scanned() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// A scan that couldn't be read, or an ask that failed.
    static func failed() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Saving a recipe, or adding a bottle to the shopping list.
    static func saved() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Removing a saved recipe or a list item: lighter than saving.
    static func removed() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
    }

    private static var engine: CHHapticEngine?

    /// New drinks from Ask the bartender: a longer, soft swell instead of a tap.
    static func poured() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            if engine == nil {
                let new = try CHHapticEngine()
                new.isAutoShutdownEnabled = true
                engine = new
            }
            guard let engine else { return }
            try engine.start()
            let swell = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
                             CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)],
                relativeTime: 0, duration: 0.7)
            // Rises in, holds, then fades out.
            let curve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [.init(relativeTime: 0, value: 0.2), .init(relativeTime: 0.25, value: 1),
                                .init(relativeTime: 0.45, value: 1), .init(relativeTime: 0.7, value: 0)],
                relativeTime: 0)
            let pattern = try CHHapticPattern(events: [swell], parameterCurves: [curve])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
