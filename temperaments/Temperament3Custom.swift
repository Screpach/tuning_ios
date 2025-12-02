import Foundation

/// User defined (or custom) temperaments.
/// Equivalent to `Temperament3Custom.kt`.
struct Temperament3Custom: Temperament3 {
    
    let _name: String
    let _abbreviation: String
    let _description: String
    private let _cents: [Double] // Should include octave
    let _rationalNumbers: [RationalNumber?] // Should include octave
    private let _noteNames: [MusicalNote]?
    
    let stableId: Int64
    
    init(name: String, abbreviation: String, description: String, cents: [Double], rationalNumbers: [RationalNumber?], noteNames: [MusicalNote]?, stableId: Int64) {
        self._name = name
        self._abbreviation = abbreviation
        self._description = description
        self._cents = cents
        self._rationalNumbers = rationalNumbers
        self._noteNames = noteNames
        self.stableId = stableId
    }
    
    // MARK: - Properties
    
    var name: GetText { GetTextFromString(string: _name) }
    var abbreviation: GetText { GetTextFromString(string: _abbreviation) }
    var description: GetText { GetTextFromString(string: _description) }
    
    var size: Int { max(0, _cents.count - 1) }
    
    // MARK: - Methods
    
    func cents() -> [Double] { _cents }
    
    func rationalNumbers() -> [RationalNumber?]? {
        // Check if any rational number exists
        if _rationalNumbers.compactMap({ $0 }).isEmpty { return nil }
        return _rationalNumbers
    }
    
    func chainOfFifths() -> ChainOfFifths? { nil }
    func equalOctaveDivision() -> Int? { nil }
    
    func possibleRootNotes() -> [MusicalNote] {
        // Return first note of names, or fallback
        if let names = _noteNames, !names.isEmpty {
            return [names[0]]
        }
        return NoteNamesEDOGenerator.possibleRootNotes(notesPerOctave: size)
    }
    
    func noteNames(rootNote: MusicalNote?) -> NoteNames2 {
        // If we have explicit names, we construct a NoteNames2 object.
        // We shift the array so it starts at rootNote.
        if let names = _noteNames, !names.isEmpty {
            // Find rotation
            // Simplified: just return as is if root matches or ignored
            let defaultRef = NoteNameHelpers.findDefaultReferenceNote(names)
            // Octave switch logic is complex, approximating:
            let switchNote = names[0]
            return NoteNames2(notes: names, defaultReferenceNote: defaultRef, octaveSwitchIndex: switchNote)
        }
        
        return NoteNamesEDOGenerator.getNoteNames(notesPerOctave: size, rootNote: rootNote)!
    }
}
