import Foundation
import SwiftUI

// MARK: - Migration Logic

/// Handles migration of preferences from legacy versions (V6/XML) to the current format.
/// Equivalent to `PreferenceMigrations.kt`.
enum PreferenceMigrations {
    
    /// Performs the migration from V6 legacy settings.
    ///
    /// - Parameters:
    ///   - newPreferenceResources: The target for general settings.
    ///   - newTemperamentResources: The target for temperament settings.
    ///   - newInstrumentResources: The target for instrument settings.
    /// - Returns: `true` if migration was performed, `false` if it was skipped (already done).
    @MainActor
    static func migrateFromV6(
        newPreferenceResources: PreferenceResources,
        newTemperamentResources: TemperamentResources,
        newInstrumentResources: InstrumentResources
    ) -> Bool {
        
        // 1. Check if migration is already complete
        if newPreferenceResources.migrationsFromV6Complete {
            return false
        }
        
        // 2. Load Legacy Resources
        let from = PreferenceResourcesOld()
        
        // 3. Migrate General Preferences
        if let mode = from.appearance {
            newPreferenceResources.writeAppearance(mode)
        }
        
        if let alwaysOn = from.screenAlwaysOn {
            newPreferenceResources.writeScreenAlwaysOn(alwaysOn)
        }
        
        if let useSystem = from.useSystemColorAccents {
            newPreferenceResources.writeUseSystemColorAccents(useSystem)
        }
        
        if let blackNight = from.blackNightEnabled {
            newPreferenceResources.writeBlackNightEnabled(blackNight)
        }
        
        if let notation = from.octaveNotation {
            // Map legacy int to Enum
            let notationEnum = (notation == 0) ? OctaveNotation.scientific : OctaveNotation.helmholtz
            newPreferenceResources.writeOctaveNotation(notationEnum)
        }
        
        if let solfege = from.noteNamePrinter {
            // Map legacy solfege setting to NotePrintOptions
            let options: NotePrintOptions
            switch solfege {
            case "Standard": options = .flatSharp
            case "East": options = .solfege
            case "FixedDo": options = .fixedDo
            default: options = .flatSharp
            }
            newPreferenceResources.writeNotePrintOptions(options)
        }
        
        if let windowSize = from.windowSize {
            newPreferenceResources.writeWindowSize(windowSize)
        }
        
        if let duration = from.pitchHistoryDuration {
            // Replicate rounding logic: ((it / 0.25f).roundToInt() * 0.25f).coerceIn(0.25f, 10f)
            let rounded = (round(duration / 0.25) * 0.25).clamped(to: 0.25...10.0)
            newPreferenceResources.writePitchHistoryDuration(rounded)
        }
        
        if let faulty = from.pitchHistoryNumFaultyValues {
            newPreferenceResources.writePitchHistoryNumFaultyValues(faulty)
        }
        
        if let avg = from.numMovingAverage {
            newPreferenceResources.writeNumMovingAverage(avg)
        }
        
        if let sens = from.sensitivity {
            newPreferenceResources.writeSensitivity(sens)
        }
        
        if let tolerance = from.toleranceInCents {
            newPreferenceResources.writeToleranceInCents(tolerance)
        }
        
        if let waveDuration = from.waveWriterDurationInSeconds {
            newPreferenceResources.writeWaveWriterDurationInSeconds(waveDuration)
        }
        
        // 4. Migrate Temperament Settings
        newTemperamentResources.writeMusicalScale(
            temperament: from.temperament,
            referenceNote: from.referenceNote,
            rootNote: from.rootNote,
            referenceFrequency: from.referenceFrequency
        )
        
        // 5. Migrate Instrument Settings
        // We use the InstrumentResourcesOld class we ported earlier.
        let fromInstruments = InstrumentResourcesOld()
        
        if let expanded = fromInstruments.customInstrumentsExpanded {
            newInstrumentResources.writeCustomInstrumentsExpanded(expanded)
        }
        
        if let expanded = fromInstruments.predefinedInstrumentsExpanded {
            newInstrumentResources.writePredefinedInstrumentsExpanded(expanded)
        }
        
        if let customList = fromInstruments.customInstruments {
            newInstrumentResources.appendInstruments(customList)
        }
        
        if let current = fromInstruments.currentInstrument {
            newInstrumentResources.setInstrument(current)
        }
        
        // 6. Mark Complete
        newPreferenceResources.writeMigrationsFromV6Complete()
        
        return true
    }
}

// MARK: - Legacy Accessor (PreferenceResourcesOld)

/// Reads values from the legacy `UserDefaults` keys (Android SharedPreferences equivalents).
/// Equivalent to `PreferenceResourcesOld` (which was implicitly used in the Kotlin snippet).
class PreferenceResourcesOld {
    
    // Keys matching Android XML strings
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
    
    // Properties
    var appearance: NightMode? {
        guard let str = UserDefaults.standard.string(forKey: KEY_APPEARANCE) else { return nil }
        // Kotlin uses "NightMode.valueOf(str)"
        return NightMode(rawValue: str)
    }
    
    var screenAlwaysOn: Bool? { getBool(KEY_SCREEN_ALWAYS_ON) }
    var useSystemColorAccents: Bool? { getBool(KEY_USE_SYSTEM_COLOR_ACCENTS) }
    var blackNightEnabled: Bool? { getBool(KEY_BLACK_NIGHT_ENABLED) }
    
    var octaveNotation: Int? { getInt(KEY_OCTAVE_NOTATION) }
    var noteNamePrinter: String? { UserDefaults.standard.string(forKey: KEY_SOLFEGE) }
    var windowSize: Int? { getInt(KEY_WINDOW_SIZE) }
    
    var pitchHistoryDuration: Float? { getFloat(KEY_PITCH_HISTORY_DURATION) }
    var pitchHistoryNumFaultyValues: Int? { getInt(KEY_PITCH_HISTORY_NUM_FAULTY_VALUES) }
    var numMovingAverage: Int? { getInt(KEY_NUM_MOVING_AVERAGE) }
    var sensitivity: Float? { getFloat(KEY_SENSITIVITY) }
    var toleranceInCents: Float? { getFloat(KEY_TOLERANCE_IN_CENTS) }
    var waveWriterDurationInSeconds: Float? { getFloat(KEY_WAVE_WRITER_DURATION) }
    
    // Temperament Legacy Placeholders
    // In a real port, these would read from keys like "temperament", "root_note", etc.
    // For now we return nil to skip unless specific keys are known.
    var temperament: Temperament? { nil }
    var referenceNote: MusicalNote? { nil }
    var rootNote: MusicalNote? { nil }
    var referenceFrequency: Float? { nil }
    
    // Helpers
    private func getBool(_ key: String) -> Bool? {
        UserDefaults.standard.object(forKey: key) != nil ? UserDefaults.standard.bool(forKey: key) : nil
    }
    private func getInt(_ key: String) -> Int? {
        UserDefaults.standard.object(forKey: key) != nil ? UserDefaults.standard.integer(forKey: key) : nil
    }
    private func getFloat(_ key: String) -> Float? {
        UserDefaults.standard.object(forKey: key) != nil ? UserDefaults.standard.float(forKey: key) : nil
    }
}

// MARK: - Stubs & Dependencies
// These stubs are required because PreferenceResources, TemperamentResources, and others
// have NOT been ported yet. They allow this file to compile independently.

// 1. PreferenceResources Stub
@MainActor
class PreferenceResources: ResourcesBase {
    // In the real implementation, these will be @Published properties backed by Preference<T>
    var migrationsFromV6Complete: Bool = false
    
    func writeMigrationsFromV6Complete() {}
    func writeAppearance(_ mode: NightMode) {}
    func writeScreenAlwaysOn(_ value: Bool) {}
    func writeUseSystemColorAccents(_ value: Bool) {}
    func writeBlackNightEnabled(_ value: Bool) {}
    func writeOctaveNotation(_ value: OctaveNotation) {}
    func writeNotePrintOptions(_ value: NotePrintOptions) {}
    func writeWindowSize(_ value: Int) {}
    func writePitchHistoryDuration(_ value: Float) {}
    func writePitchHistoryNumFaultyValues(_ value: Int) {}
    func writeNumMovingAverage(_ value: Int) {}
    func writeSensitivity(_ value: Float) {}
    func writeToleranceInCents(_ value: Float) {}
    func writeWaveWriterDurationInSeconds(_ value: Float) {}
}

// 2. TemperamentResources Stub
@MainActor
class TemperamentResources: ObservableObject {
    func writeMusicalScale(temperament: Temperament?, referenceNote: MusicalNote?, rootNote: MusicalNote?, referenceFrequency: Float?) {}
}

// 3. InstrumentResources Extensions for Migration
// Extending the class we ported in `InstrumentResources.swift`
extension InstrumentResources {
    func writeCustomInstrumentsExpanded(_ value: Bool) {}
    func writePredefinedInstrumentsExpanded(_ value: Bool) {}
    // `setInstrument` and `appendInstruments` are already present in the main file
}

// 4. Enums
enum OctaveNotation: Int, Codable {
    case scientific, helmholtz
}

enum NotePrintOptions: Int, Codable {
    case flatSharp, solfege, fixedDo
}

// 5. Math Helper
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
