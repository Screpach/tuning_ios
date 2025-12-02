import Foundation

// MARK: - Musical Scale (Legacy/DTO)

/// Old musical scale class.
/// Equivalent to `MusicalScale` in Kotlin.
/// Used primarily for serialization/persistence of scale settings.
struct MusicalScale: Codable {
    let temperament: Temperament
    // Root note of the scale (e.g. for Just Intonation)
    let rootNote: MusicalNote?
    // Reference note (e.g. A4)
    let referenceNote: MusicalNote?
    // Reference frequency (e.g. 440Hz)
    let referenceFrequency: Float
    let frequencyMin: Float
    let frequencyMax: Float
    let stretchTuning: StretchTuning?
}

// MARK: - Musical Scale 2 (Runtime Logic)

/// The core musical scale logic.
/// Equivalent to `MusicalScale2` in Kotlin.
/// Handles frequency calculations, note matching, and temperament application.
struct MusicalScale2: Identifiable, Sendable {
    
    // MARK: Properties
    
    let id = UUID()
    
    let temperament: Temperament
    let rootNote: MusicalNote?
    let referenceNote: MusicalNote?
    let referenceFrequency: Float
    let frequencyMin: Float
    let frequencyMax: Float
    let stretchTuning: StretchTuning?
    
    // MARK: Internal Helpers (Delegates)
    // These handle the heavy mathematical lookups.
    // In a full port, these would be initialized with the scale parameters.
    
    private let musicalScaleFrequencies: MusicalScaleFrequencies
    private let noteNameScale: MusicalScaleNoteNameScale
    
    // MARK: Initialization
    
    init(temperament: Temperament,
         rootNote: MusicalNote?,
         referenceNote: MusicalNote?,
         referenceFrequency: Float,
         frequencyMin: Float,
         frequencyMax: Float,
         stretchTuning: StretchTuning?) {
        
        self.temperament = temperament
        self.rootNote = rootNote
        self.referenceNote = referenceNote
        self.referenceFrequency = referenceFrequency
        self.frequencyMin = frequencyMin
        self.frequencyMax = frequencyMax
        self.stretchTuning = stretchTuning
        
        // Initialize helpers (Mocked for Phase 1 until those files are ported)
        self.musicalScaleFrequencies = MusicalScaleFrequencies()
        self.noteNameScale = MusicalScaleNoteNameScale()
    }
    
    // MARK: Logic API
    
    /// Get frequency of a note index.
    func getNoteFrequency(noteIndex: Int) -> Float {
        return musicalScaleFrequencies.getNoteFrequency(noteIndex)
    }
    
    /// Get note index for a specific frequency.
    /// Returns the closest note index.
    func getNoteIndex(frequency: Float) -> Int {
        return musicalScaleFrequencies.getClosestFrequencyIndex(frequency)
    }
    
    /// Get note index of a given musical note representation.
    /// Returns `Int.max` if not in scale.
    func getNoteIndex2(note: MusicalNote) -> Int {
        return noteNameScale.getNoteIndex(note)
    }
    
    /// Get indices of matching notes.
    /// "Match" means that any combination of enharmonic/non-enharmonic is the same.
    func getMatchingNoteIndices(note: MusicalNote) -> [Int] {
        return noteNameScale.getMatchingNoteIndices(note)
    }
    
    /// Check if the scale has a matching note.
    func hasMatchingNote(note: MusicalNote?) -> Bool {
        return noteNameScale.hasMatchingNote(note)
    }
    
    // MARK: Factory Methods
    
    static func createTestEdo12() -> MusicalScale2 {
        // Equivalent to Kotlin's companion object method
        return MusicalScale2(
            temperament: predefinedTemperamentEDO(12, 1),
            rootNote: nil,
            referenceNote: nil,
            referenceFrequency: 440.0,
            frequencyMin: 30.0,
            frequencyMax: 18000.0,
            stretchTuning: nil
        )
    }
}

// MARK: - Stubs & Dependencies
// These are required to make the code above compile independent of the missing files.
// They will be replaced/removed as we port the actual logic files.

// 1. Temperament Stubs
class Temperament: Codable, Sendable {
    // Placeholder for Temperament hierarchy
}

func predefinedTemperamentEDO(_ count: Int, _ id: Int64) -> Temperament {
    return Temperament()
}

// 2. Stretch Tuning Stub
struct StretchTuning: Codable, Sendable, Hashable {}

// 3. Helper Class Stubs (Logic Delegates)
// These likely exist in `MusicalScaleFrequencies.kt` and `MusicalScaleNoteNameScale.kt`

struct MusicalScaleFrequencies: Sendable {
    func getNoteFrequency(_ index: Int) -> Float {
        // Mock logic: A4 = 440Hz, index 0. Simple semitone step.
        return 440.0 * pow(2.0, Float(index) / 12.0)
    }
    
    func getClosestFrequencyIndex(_ frequency: Float) -> Int {
        // Mock logic
        return Int(12.0 * log2(frequency / 440.0))
    }
}

struct MusicalScaleNoteNameScale: Sendable {
    func getNoteIndex(_ note: MusicalNote) -> Int {
        // Mock logic
        return 0
    }
    
    func getMatchingNoteIndices(_ note: MusicalNote) -> [Int] {
        return []
    }
    
    func hasMatchingNote(_ note: MusicalNote?) -> Bool {
        return note != nil
    }
}

// 4. MusicalNote (Redefined here if this file is tested in isolation,
//    but strictly relying on the previous definition is better.
//    Adding extension to ensure compatibility if stub is missing).

extension MusicalNote {
    // Helper to allow `MusicalNote?` usage if the original struct didn't have specific methods needed here.
}
