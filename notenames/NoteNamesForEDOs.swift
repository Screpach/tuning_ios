import Foundation

/// Create note names for EDO scales.
/// Equivalent to `NoteNamesForEDOs.kt`.
enum NoteNamesEDOGenerator {
    
    static func possibleRootNotes(notesPerOctave: Int) -> [MusicalNote] {
        return generateNoteNamesImpl(notesPerOctave)
    }
    
    static func getNoteNames(notesPerOctave: Int, rootNote: MusicalNote?) -> NoteNames2? {
        if notesPerOctave > 72 { return nil }
        
        let noteNames = generateNoteNamesImpl(notesPerOctave)
        guard !noteNames.isEmpty else { return nil }
        
        let defaultReference = NoteNameHelpers.findDefaultReferenceNote(noteNames)
        let octaveSwitchIndex = noteNames[0]
        
        // Root Note Shifting Logic (if rootNote is provided)
        // This reorders the array so it starts at rootNote
        var finalNotes = noteNames
        if let root = rootNote {
            if let rootIndex = noteNames.firstIndex(where: { $0.equalsIgnoreOctave(root) }) {
                // Rotate array
                let part1 = finalNotes[rootIndex...]
                let part2 = finalNotes[..<rootIndex]
                finalNotes = Array(part1 + part2)
            }
        }
        
        return NoteNames2(
            notes: finalNotes,
            defaultReferenceNote: defaultReference,
            octaveSwitchIndex: octaveSwitchIndex
        )
    }
    
    // MARK: - Implementation
    
    private static func generateNoteNamesImpl(_ notesPerOctave: Int) -> [MusicalNote] {
        var names = [MusicalNote]()
        
        // Basic EDO Naming Logic (Simplified port)
        // Standard Western 12-EDO
        if notesPerOctave == 12 {
            return [
                MusicalNote(.C, .None, 4, octaveOffset: 0, enharmonicBase: .B, enharmonicModifier: .Sharp, enharmonicOctaveOffset: 1), // C / B#
                MusicalNote(.C, .Sharp, 4, octaveOffset: 0, enharmonicBase: .D, enharmonicModifier: .Flat, enharmonicOctaveOffset: 0), // C# / Db
                MusicalNote(.D, .None),
                MusicalNote(.D, .Sharp, 4, octaveOffset: 0, enharmonicBase: .E, enharmonicModifier: .Flat, enharmonicOctaveOffset: 0),
                MusicalNote(.E, .None),
                MusicalNote(.F, .None),
                MusicalNote(.F, .Sharp, 4, octaveOffset: 0, enharmonicBase: .G, enharmonicModifier: .Flat, enharmonicOctaveOffset: 0),
                MusicalNote(.G, .None),
                MusicalNote(.G, .Sharp, 4, octaveOffset: 0, enharmonicBase: .A, enharmonicModifier: .Flat, enharmonicOctaveOffset: 0),
                MusicalNote(.A, .None),
                MusicalNote(.A, .Sharp, 4, octaveOffset: 0, enharmonicBase: .B, enharmonicModifier: .Flat, enharmonicOctaveOffset: 0),
                MusicalNote(.B, .None)
            ]
        }
        
        // For other EDOs, we would implement the full Fifth-based generator logic.
        // Returning 12-EDO fallback or empty for now to match Phase 1 scope.
        return names
    }
}
