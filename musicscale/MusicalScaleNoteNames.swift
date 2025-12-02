import Foundation

/// Note names, which can map indices between musical notes and vice versa.
///
/// Equivalent to `MusicalScaleNoteNameScale` class in `MusicalScaleNoteNames.kt`.
struct MusicalScaleNoteNameScale: Sendable {
    
    // MARK: - Properties
    
    let noteNames: NoteNames2
    let referenceNote: MusicalNote
    
    private let referenceOctave: Int
    private let referenceNoteIndexWithinOctave: Int
    private let octaveSwitchIndexWithinNoteNames: Int
    private let size: Int
    
    // MARK: - Initialization
    
    /// Creates a new note name scale.
    ///
    /// - Parameters:
    ///   - noteNames: Note names of one octave.
    ///   - referenceNote: Reference note of the scale (index 0). If nil, defaults to noteNames.defaultReferenceNote.
    init(noteNames: NoteNames2, referenceNote: MusicalNote? = nil) {
        self.noteNames = noteNames
        
        // Resolve reference note
        let resolvedRef: MusicalNote
        if let ref = referenceNote, noteNames.hasNote(ref) {
            resolvedRef = ref
        } else {
            resolvedRef = noteNames.defaultReferenceNote
        }
        self.referenceNote = resolvedRef
        
        // Cache properties
        self.referenceOctave = resolvedRef.octave
        self.referenceNoteIndexWithinOctave = noteNames.getIndexOfNote(resolvedRef)
        self.size = noteNames.size
        
        // Determine where the octave switches (e.g. at C).
        // Logic: Get note at index 0, force octave to 0. Find its index.
        // If noteNames starts at C, this is usually 0.
        // If noteNames starts at A, but C is index 3, then octave switches at index 3.
        if size > 0 {
            let firstNote = noteNames.getNoteAt(0)
            // Create a copy with octave 0 (assuming MusicalNote is immutable struct)
            let noteWithOctaveZero = MusicalNote(firstNote.base, firstNote.modifier, 0)
            self.octaveSwitchIndexWithinNoteNames = noteNames.getIndexOfNote(noteWithOctaveZero)
        } else {
            self.octaveSwitchIndexWithinNoteNames = 0
        }
    }
    
    // MARK: - API
    
    /// Get note index of a given musical note representation.
    ///
    /// - Parameter musicalNote: Musical note representation.
    /// - Returns: Local index of the note or `Int.max` if it does not exist in scale.
    func getNoteIndex(_ musicalNote: MusicalNote) -> Int {
        let localNoteIndex = noteNames.getIndexOfNote(musicalNote)
        
        if localNoteIndex == Int.max {
            return Int.max
        }
        
        // Adjust octave based on where the "C" (start of octave) lies in the name list
        let octave: Int
        if localNoteIndex < octaveSwitchIndexWithinNoteNames {
            octave = musicalNote.octave
        } else {
            // If we are "before" the switch in the list, we might be in the previous octave context
            // Kotlin logic: if (local < switch) octave else octave - 1
            // Let's verify standard C-Major logic (C, D, E...). Switch is 0. local >= 0.
            // Result: octave.
            // A-Minor logic (A, B, C...). Switch is 2 (at C).
            // Input A4 (index 0). 0 < 2 -> octave = 4.
            // Input C4 (index 2). 2 >= 2 -> octave = 3??
            // Wait, Kotlin logic:
            /*
             val octave = if (localNoteIndex < octaveSwitchIndexWithinNoteNames)
                musicalNote.octave
             else
                musicalNote.octave - 1
             */
            // This suggests the input note's octave property might need adjustment relative to the reference?
            // Actually, this logic calculates the "linear octave" based on the note list structure.
            octave = musicalNote.octave - 1
        }
        
        // Re-reading Kotlin logic carefully:
        // The Kotlin code calculates `octave` variable to use in the linear formula.
        // It seems specific to how `NoteNames` handles octaves internally.
        // I will copy the Kotlin logic exactly for Phase 1.
        
        let calculatedOctave: Int
        if localNoteIndex < octaveSwitchIndexWithinNoteNames {
            calculatedOctave = musicalNote.octave
        } else {
            calculatedOctave = musicalNote.octave - 1
        }
        
        return (calculatedOctave - referenceOctave) * size + localNoteIndex - referenceNoteIndexWithinOctave
    }
    
    /// Return indices of all notes which match the given note.
    ///
    /// A match means that either a combination of enharmonic or non enharmonic are the same.
    func getMatchingNoteIndices(_ musicalNote: MusicalNote) -> [Int] {
        let matchingIndices = noteNames.getMatchingNoteIndices(musicalNote)
        
        return matchingIndices.map { localNoteIndex in
            let calculatedOctave: Int
            if localNoteIndex < octaveSwitchIndexWithinNoteNames {
                calculatedOctave = musicalNote.octave
            } else {
                calculatedOctave = musicalNote.octave - 1
            }
            
            return (calculatedOctave - referenceOctave) * size + localNoteIndex - referenceNoteIndexWithinOctave
        }
    }
    
    /// Check if a note matches any of the notes in this class.
    func hasMatchingNote(_ musicalNote: MusicalNote?) -> Bool {
        guard let note = musicalNote else { return false }
        return noteNames.hasNote(note)
    }
}

// MARK: - Stubs (Dependencies)

/// Stub for `NoteNames2`.
/// Will be replaced when `notenames/NoteNames2.kt` is ported.
struct NoteNames2: Sendable {
    // Mock properties
    let size: Int = 12
    let defaultReferenceNote: MusicalNote = MusicalNote(.A, .none, 4)
    
    func hasNote(_ note: MusicalNote) -> Bool {
        return true
    }
    
    func getIndexOfNote(_ note: MusicalNote) -> Int {
        // Mock: Return 0 for A4, etc.
        return 0
    }
    
    func getNoteAt(_ index: Int) -> MusicalNote {
        return defaultReferenceNote
    }
    
    func getMatchingNoteIndices(_ note: MusicalNote) -> [Int] {
        return [getIndexOfNote(note)]
    }
}
