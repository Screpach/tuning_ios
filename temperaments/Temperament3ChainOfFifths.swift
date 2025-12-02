import Foundation

// MARK: - No Enharmonics Variant

/// Temperament based on a chain of fifths with simple note naming.
struct Temperament3ChainOfFifthsNoEnharmonics: Temperament3 {
    let name: GetText
    let abbreviation: GetText
    let description: GetText
    let stableId: Int64
    
    let fifths: [FifthModification]
    let rootIndex: Int
    let uniqueIdentifier: String
    
    var size: Int { fifths.count + 1 }
    
    private var _chainOfFifths: ChainOfFifths {
        ChainOfFifths(fifths: fifths, rootIndex: rootIndex)
    }
    
    func cents() -> [Double] {
        // Calculate ratios and convert to cents
        // We append 1200.0 for the octave
        var c = _chainOfFifths.getSortedRatios().map { ratioToCents($0) }
        c.append(1200.0)
        return c
    }
    
    func chainOfFifths() -> ChainOfFifths? { _chainOfFifths }
    func equalOctaveDivision() -> Int? { nil }
    func rationalNumbers() -> [RationalNumber?]? { nil }
    
    func possibleRootNotes() -> [MusicalNote] {
        return NoteNamesChainOfFifthsGenerator.possibleRootNotes()
    }
    
    func noteNames(rootNote: MusicalNote?) -> NoteNames2 {
        // Assuming generator exists (stubbed in previous step as returning nil/basic)
        // Fallback to 12-EDO for safety if generator not full
        if let names = NoteNamesChainOfFifthsGenerator.generateNoteNames(chainOfFifths: _chainOfFifths) {
            return names
        }
        // Fallback
        return NoteNamesEDOGenerator.getNoteNames(notesPerOctave: 12, rootNote: nil)!
    }
}

// MARK: - EDO Names Variant

/// Temperament based on chain of fifths but using EDO naming (usually 12-tone).
struct Temperament3ChainOfFifthsEDONames: Temperament3 {
    let name: GetText
    let abbreviation: GetText
    let description: GetText
    let stableId: Int64
    
    let fifths: [FifthModification]
    let rootIndex: Int
    let uniqueIdentifier: String
    
    var size: Int { fifths.count + 1 }
    
    private var _chainOfFifths: ChainOfFifths {
        ChainOfFifths(fifths: fifths, rootIndex: rootIndex)
    }
    
    func cents() -> [Double] {
        var c = _chainOfFifths.getSortedRatios().map { ratioToCents($0) }
        c.append(1200.0)
        return c
    }
    
    func chainOfFifths() -> ChainOfFifths? { _chainOfFifths }
    func equalOctaveDivision() -> Int? { nil }
    func rationalNumbers() -> [RationalNumber?]? { nil }
    
    func possibleRootNotes() -> [MusicalNote] {
        return NoteNamesEDOGenerator.possibleRootNotes(notesPerOctave: size)
    }
    
    func noteNames(rootNote: MusicalNote?) -> NoteNames2 {
        return NoteNamesEDOGenerator.getNoteNames(notesPerOctave: size, rootNote: rootNote)!
    }
}
