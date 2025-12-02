import Foundation

/// Reads values from the legacy `UserDefaults` keys (Android SharedPreferences equivalents).
/// Equivalent to `PreferenceResourcesOld.kt`.
/// This class handles the reading and *conversion* of legacy raw values (indices, percents)
/// into the actual values needed by the new application.
class PreferenceResourcesOld {
    
    // MARK: - Keys
    // Matching Android XML key strings
    private let KEY_APPEARANCE = "appearance"
    private let KEY_SCREEN_ALWAYS_ON = "screen_always_on"
    private let KEY_USE_SYSTEM_COLOR_ACCENTS = "use_system_color_accents"
    private let KEY_BLACK_NIGHT_ENABLED = "black_night_enabled"
    private let KEY_OCTAVE_NOTATION = "octave_notation"
    private let KEY_SOLFEGE = "solfege"
    private let KEY_WINDOW_SIZE = "window_size"
    private let KEY_PITCH_HISTORY_DURATION = "pitch_history_duration"
    private let KEY_PITCH_HISTORY_NUM_FAULTY_VALUES = "pitch_history_num_faulty_values"
    private let KEY_NUM_MOVING_AVERAGE = "num_moving_average"
    private let KEY_SENSITIVITY = "sensitivity"
    private let KEY_TOLERANCE_IN_CENTS = "tolerance_in_cents"
    private let KEY_WAVE_WRITER_DURATION = "wave_writer_duration"
    private let KEY_TEMPERAMENT = "temperament_preference" // Assumed key for the encoded string
    
    // MARK: - Properties
    
    var appearance: NightMode? {
        guard let str = UserDefaults.standard.string(forKey: KEY_APPEARANCE) else { return nil }
        return NightMode(rawValue: str)
    }
    
    var screenAlwaysOn: Bool? { getBool(KEY_SCREEN_ALWAYS_ON) }
    var useSystemColorAccents: Bool? { getBool(KEY_USE_SYSTEM_COLOR_ACCENTS) }
    var blackNightEnabled: Bool? { getBool(KEY_BLACK_NIGHT_ENABLED) }
    
    var octaveNotation: Int? { getInt(KEY_OCTAVE_NOTATION) }
    var noteNamePrinter: String? { UserDefaults.standard.string(forKey: KEY_SOLFEGE) }
    
    /// Returns the calculated window size (e.g., 2048, 4096) from the stored index.
    var windowSize: Int? {
        guard let index = getInt(KEY_WINDOW_SIZE) else { return nil }
        return indexToWindowSize2(index)
    }
    
    /// Returns the calculated duration in seconds from the stored percentage.
    var pitchHistoryDuration: Float? {
        guard let percent = getInt(KEY_PITCH_HISTORY_DURATION) else { return nil }
        return percentToPitchHistoryDuration2(percent)
    }
    
    var pitchHistoryNumFaultyValues: Int? { getInt(KEY_PITCH_HISTORY_NUM_FAULTY_VALUES) }
    var numMovingAverage: Int? { getInt(KEY_NUM_MOVING_AVERAGE) }
    var sensitivity: Float? { getFloat(KEY_SENSITIVITY) }
    
    /// Returns the tolerance in cents from the stored index.
    var toleranceInCents: Float? {
        guard let index = getInt(KEY_TOLERANCE_IN_CENTS) else { return nil }
        return Float(indexToTolerance2(index))
    }
    
    var waveWriterDurationInSeconds: Float? { getFloat(KEY_WAVE_WRITER_DURATION) }
    
    // MARK: - Temperament Parsing
    
    // Legacy storage packed everything into one string: "Type Root RefNote RefFreq"
    private var temperamentData: TemperamentData? {
        guard let raw = UserDefaults.standard.string(forKey: KEY_TEMPERAMENT) else { return nil }
        return TemperamentData.fromString(raw)
    }
    
    var temperament: Temperament? {
        guard let type = temperamentData?.type else { return nil }
        // Basic mapping for Phase 1. Real port would map all types to Temperament instances.
        switch type {
        case .EDO12: return predefinedTemperamentEDO(12, 1)
        default: return predefinedTemperamentEDO(12, 1) // Fallback
        }
    }
    
    var rootNote: MusicalNote? { temperamentData?.rootNote }
    var referenceNote: MusicalNote? { temperamentData?.referenceNote }
    var referenceFrequency: Float? { temperamentData?.referenceFrequency }
    
    // MARK: - Helpers (Mappers)
    
    private func getBool(_ key: String) -> Bool? {
        UserDefaults.standard.object(forKey: key) != nil ? UserDefaults.standard.bool(forKey: key) : nil
    }
    private func getInt(_ key: String) -> Int? {
        UserDefaults.standard.object(forKey: key) != nil ? UserDefaults.standard.integer(forKey: key) : nil
    }
    private func getFloat(_ key: String) -> Float? {
        UserDefaults.standard.object(forKey: key) != nil ? UserDefaults.standard.float(forKey: key) : nil
    }
    
    /// `2f.pow(7 + index).roundToInt()`
    private func indexToWindowSize2(_ index: Int) -> Int {
        return Int(pow(2.0, Double(7 + index)))
    }
    
    /// Maps index 0..7 to specific tolerance values.
    private func indexToTolerance2(_ index: Int) -> Int {
        switch index {
        case 0: return 1
        case 1: return 2
        case 2: return 3
        case 3: return 5
        case 4: return 7
        case 5: return 10
        case 6: return 15
        case 7: return 20
        default: return 10 // Safe default
        }
    }
    
    /// Exponential scaling for duration.
    private func percentToPitchHistoryDuration2(_ percent: Int, durationAtFiftyPercent: Float = 3.0) -> Float {
        return durationAtFiftyPercent * pow(2.0, 0.05 * Float(percent - 50))
    }
}

// MARK: - Supporting Types

private struct TemperamentData {
    let type: TemperamentTypeOld
    let rootNote: MusicalNote?
    let referenceNote: MusicalNote?
    let referenceFrequency: Float?
    
    static func fromString(_ string: String) -> TemperamentData? {
        let parts = string.split(separator: " ").map { String($0) }
        guard parts.count >= 4 else { return nil }
        
        guard let type = TemperamentTypeOld(rawValue: parts[0]) else { return nil }
        
        // Uses the MusicalNote parser we ported in InstrumentIO
        let root = MusicalNote.fromString(parts[1])
        let refNote = MusicalNote.fromString(parts[2])
        let refFreq = Float(parts[3])
        
        return TemperamentData(
            type: type,
            rootNote: root,
            referenceNote: refNote,
            referenceFrequency: refFreq
        )
    }
}

enum TemperamentTypeOld: String {
    case EDO12, Pythagorean, Meantone1_4, Pure, EDO19, EDO24, EDO31
}

// Extension to support the parsing logic if not present in the main MusicalNote file yet
extension MusicalNote {
    static func fromString(_ raw: String) -> MusicalNote? {
        // Simple shim to reuse the logic we wrote in InstrumentIO or similar
        // In a full port, this logic belongs inside MusicalNote.swift
        return nil // Placeholder for Phase 1 compilation
    }
}
