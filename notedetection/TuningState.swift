import Foundation

/// Represents the tuning status relative to a target note.
enum TuningState: Sendable {
    case inTune
    case tooLow
    case tooHigh
    case unknown
}

// Helper usually found in this file or imported
private func centsToRatio(_ cents: Float) -> Float {
    return pow(2.0, cents / 1200.0)
}

/// Checks if a frequency matches a target within tolerance.
///
/// - Parameters:
///   - frequency: The detected frequency.
///   - targetFrequency: The goal frequency.
///   - toleranceInCents: Allowed deviation in cents.
/// - Returns: A `TuningState`.
func checkTuning(frequency: Float, targetFrequency: Float, toleranceInCents: Float) -> TuningState {
    if frequency < 0 || targetFrequency < 0 || toleranceInCents < 0 {
        return .unknown
    }
    
    let ratio = centsToRatio(toleranceInCents)
    let lowerBound = targetFrequency / ratio
    let upperBound = targetFrequency * ratio
    
    if frequency < lowerBound {
        return .tooLow
    } else if frequency > upperBound {
        return .tooHigh
    } else {
        return .inTune
    }
}
