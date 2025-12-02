import Foundation

/// Class containing the notes of one octave.
/// Equivalent to `NoteNames.kt`.
struct NoteNames: Codable, Sendable {
    
    let notes: [MusicalNote]
    let defaultReferenceNote: MusicalNote
    
    var size: Int { notes.count }
    
    /// Returns the index of a note within the octave array.
    /// Octave index of the input note is ignored.
    func getNoteIndex(_ note: MusicalNote) -> Int {
        return notes.firstIndex { $0.equalsIgnoreOctave(note) } ?? -1 // Kotlin returns -1 or Int.max? Check usage.
        // Actually NoteNames2 uses indexOfFirst which returns -1.
        // If legacy code expects Int.max for "not found", we should check.
        // For now -1 is standard.
    }
    
    /// Returns indices of all matching notes (including enharmonics).
    func getMatchingNoteIndices(_ note: MusicalNote) -> [Int] {
        var indices = [Int]()
        for (i, candidate) in notes.enumerated() {
            if candidate.match(note, ignoreOctave: true) {
                indices.append(i)
            }
        }
        return indices
    }
    
    func hasNote(_ note: MusicalNote) -> Bool {
        return notes.contains { $0.equalsIgnoreOctave(note) }
    }
}
