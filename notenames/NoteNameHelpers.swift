import Foundation

/// Utilities for Note Names.
/// Equivalent to `NoteNameHelpers.kt`.
enum NoteNameHelpers {
    
    /// Finds the default reference note (A Natural) in a list of notes.
    /// If A-Natural is not found, defaults to the first note (forced to octave 4).
    static func findDefaultReferenceNote(_ noteNames: [MusicalNote]) -> MusicalNote {
        // Look for A None
        let match = noteNames.first { note in
            (note.base == .A && note.modifier == .None) ||
            (note.enharmonicBase == .A && note.enharmonicModifier == .None)
        }
        
        let found = match ?? noteNames.first ?? MusicalNote(.A, .None)
        
        // Return copy at octave 4
        return found.copy(octave: 4)
    }
}
