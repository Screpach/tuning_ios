import Foundation

// MARK: - Constants

let STRETCH_TUNING_ID_NO_STRETCH: Int64 = -1
let STRETCH_TUNING_ID_RAILSBACK: Int64 = -2

// MARK: - Model Definition
// Defined here because StretchTuning.kt has not been provided yet.

/// Represents a stretch tuning curve (e.g. for Piano).
/// Equivalent to `de.moekadu.tuner.stretchtuning.StretchTuning`.
struct StretchTuning: Identifiable, Hashable, Codable, Sendable {
    let name: String
    let description: String
    let unstretchedFrequencies: [Double]
    let stretchInCents: [Double]
    let stableId: Int64
    
    var id: Int64 { stableId }
    
    // Helper for localization keys
    init(nameKey: String, descriptionKey: String, unstretchedFrequencies: [Double], stretchInCents: [Double], stableId: Int64) {
        // In a real app, we would verify these keys exist in Localizable.xcstrings
        self.name = nameKey
        self.description = descriptionKey
        self.unstretchedFrequencies = unstretchedFrequencies
        self.stretchInCents = stretchInCents
        self.stableId = stableId
    }
}

// MARK: - Database

/// Generates the list of built-in stretch tunings.
/// Equivalent to `predefinedStretchTunings()` in Kotlin.
func predefinedStretchTunings() -> [StretchTuning] {
    var result = [StretchTuning]()
    
    // 1. No Stretch
    result.append(StretchTuning(
        nameKey: "no_stretch_tuning",
        descriptionKey: "stretch_tuning_off",
        unstretchedFrequencies: [],
        stretchInCents: [],
        stableId: STRETCH_TUNING_ID_NO_STRETCH
    ))
    
    // 2. Railsback (Piano)
    // Note: The data arrays below are partially sourced from the snippet.
    // You MUST complete the arrays with data from your original file.
    result.append(StretchTuning(
        nameKey: "railsback",
        descriptionKey: "railsback_description",
        unstretchedFrequencies: [
            28.409, 33.377, 39.215, 46.074, 54.132, 63.599, 74.723, 87.792, 103.146, 121.186,
            142.381, 167.283, 196.541, 230.915, 271.302, 318.752, 374.501,
            // TODO: Copy the remaining values from your Android source here.
            // 440.0, ...
        ],
        stretchInCents: [
            // TODO: Copy the stretchInCents values from your Android source here.
            // The snippet provided did not show this array.
        ],
        stableId: STRETCH_TUNING_ID_RAILSBACK
    ))
    
    return result
}

