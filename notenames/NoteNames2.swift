import Foundation

/// Class containing the notes of one octave.
/// Equivalent to `NoteNames2.kt`.
struct NoteNames2: Codable, Sendable, Equatable {
    
    let notes: [MusicalNote]
    let defaultReferenceNote: MusicalNote
    
    /// The note where the octave index increments.
    /// e.g. In C-Major, this is C. (B3 -> C4).
    let octaveSwitchIndex: MusicalNote
    
    var size: Int { notes.count }
    
    // MARK: - Logic
    
    func getNoteIndex(_ note: MusicalNote) -> Int {
        return notes.firstIndex { $0.equalsIgnoreOctave(note) } ?? -1
    }
    
    func getNoteAt(_ index: Int) -> MusicalNote {
        guard index >= 0 && index < notes.count else { return defaultReferenceNote }
        return notes[index]
    }
    
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
    
    func hasMatch(_ note: MusicalNote) -> Bool {
        return notes.contains { $0.match(note, ignoreOctave: true) }
    }
    
    // MARK: - Transformations
    
    /// Switches primary and enharmonic definitions for all notes.
    func switchEnharmonic() -> NoteNames2 {
        let switchedNotes = notes.map { $0.switchEnharmonic() }
        return NoteNames2(
            notes: switchedNotes,
            defaultReferenceNote: defaultReferenceNote.switchEnharmonic(),
            octaveSwitchIndex: octaveSwitchIndex.switchEnharmonic()
        )
    }
}
