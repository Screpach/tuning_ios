import Foundation

/// Temperament based on a list of rational numbers.
/// Equivalent to `Temperament3RationalNumbers.kt`.
struct Temperament3RationalNumbersEDONames: Temperament3 {
    
    let name: GetText
    let abbreviation: GetText
    let description: GetText
    let rationalNumbersArray: [RationalNumber]
    let stableId: Int64
    let uniqueIdentifier: String
    
    var size: Int { rationalNumbersArray.count - 1 }
    
    func cents() -> [Double] {
        return rationalNumbersArray.map { ratioToCents($0.toDouble()) }
    }
    
    func rationalNumbers() -> [RationalNumber?]? {
        // Convert [RationalNumber] to [RationalNumber?] for protocol conformance
        return rationalNumbersArray.map { $0 }
    }
    
    func chainOfFifths() -> ChainOfFifths? { nil }
    func equalOctaveDivision() -> Int? { nil }
    
    func possibleRootNotes() -> [MusicalNote] {
        return NoteNamesEDOGenerator.possibleRootNotes(notesPerOctave: size)
    }
    
    func noteNames(rootNote: MusicalNote?) -> NoteNames2 {
        return NoteNamesEDOGenerator.getNoteNames(notesPerOctave: size, rootNote: rootNote)!
    }
}
