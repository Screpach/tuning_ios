import Foundation

class SortedAndDistinctInstrumentStrings {
    
    let sortedAndDistinctNoteIndices: [Int]
    
    init(instrument: Instrument, musicalScale: MusicalScale2) {
        self.sortedAndDistinctNoteIndices = SortedAndDistinctInstrumentStrings.sortStrings(
            instrument: instrument,
            scale: musicalScale
        )
    }
    
    var numDifferentNotes: Int { sortedAndDistinctNoteIndices.count }
    
    /// Returns true if the note is part of the instrument strings.
    func isNoteOfInstrument(_ note: MusicalNote?, instrument: Instrument, musicalScale: MusicalScale2) -> Bool {
        guard let note = note else { return false }
        if instrument.isChromatic {
            return musicalScale.hasMatchingNote(note: note)
        }
        
        let indices = musicalScale.getMatchingNoteIndices(note: note)
        for idx in indices {
            // Binary search in sorted list
            // Swift doesn't have built-in binary search for arrays, using linear contains for simplicity in Phase 1
            if sortedAndDistinctNoteIndices.contains(idx) {
                return true
            }
        }
        return false
    }
    
    private static func sortStrings(instrument: Instrument, scale: MusicalScale2) -> [Int] {
        if instrument.isChromatic || instrument.strings.isEmpty {
            return []
        }
        
        var indices = Set<Int>()
        for stringNote in instrument.strings {
            let matches = scale.getMatchingNoteIndices(note: stringNote)
            for m in matches {
                indices.insert(m)
            }
        }
        
        return indices.sorted()
    }
}
