import Foundation

/// Equal division temperaments.
/// Equivalent to `Temperament3EDO.kt`.
struct Temperament3EDO: Temperament3 {
    
    let stableId: Int64
    let notesPerOctave: Int
    
    // MARK: - Properties
    
    var name: GetText {
        GetTextFromResIdWithIntArg(resourceKey: "equal_temperament_x", arg: notesPerOctave)
    }
    
    var abbreviation: GetText {
        GetTextFromResIdWithIntArg(resourceKey: "equal_temperament_x_abbr", arg: notesPerOctave)
    }
    
    var description: GetText {
        GetTextFromResIdWithIntArg(resourceKey: "equal_temperament_x_desc", arg: notesPerOctave)
    }
    
    var size: Int { notesPerOctave }
    
    // MARK: - Methods
    
    func cents() -> [Double] {
        return (0...notesPerOctave).map { Double($0) * 1200.0 / Double(notesPerOctave) }
    }
    
    func chainOfFifths() -> ChainOfFifths? {
        if notesPerOctave == 12 {
            // 12-EDO is a closed chain where each fifth is tempered by 1/12 Pythagorean comma
            // P_comma = -1/12
            let mod = FifthModification(pythagoreanComma: RationalNumber(-1, 12))
            let fifths = [FifthModification](repeating: mod, count: 11)
            return ChainOfFifths(fifths: fifths, rootIndex: 0)
        }
        return nil
    }
    
    func equalOctaveDivision() -> Int? {
        return notesPerOctave
    }
    
    func rationalNumbers() -> [RationalNumber?]? {
        return nil
    }
    
    func possibleRootNotes() -> [MusicalNote] {
        return NoteNamesEDOGenerator.possibleRootNotes(notesPerOctave: notesPerOctave)
    }
    
    func noteNames(rootNote: MusicalNote?) -> NoteNames2 {
        // Force unwrap as we assume generator works for valid EDOs
        return NoteNamesEDOGenerator.getNoteNames(notesPerOctave: notesPerOctave, rootNote: rootNote)
            ?? NoteNamesEDOGenerator.getNoteNames(notesPerOctave: 12, rootNote: nil)!
    }
}
