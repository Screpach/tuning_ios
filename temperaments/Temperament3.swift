import Foundation

/// Interface for all temperaments.
/// Equivalent to `Temperament3.kt`.
protocol Temperament3: Codable, Sendable {
    
    var stableId: Int64 { get }
    
    var name: GetText { get }
    var abbreviation: GetText { get }
    var description: GetText { get }
    
    var size: Int { get }
    
    /// Cents including the octave (size + 1).
    func cents() -> [Double]
    
    /// Rational numbers including octave, if available.
    func rationalNumbers() -> [RationalNumber?]?
    
    func chainOfFifths() -> ChainOfFifths?
    
    func equalOctaveDivision() -> Int?
    
    func possibleRootNotes() -> [MusicalNote]
    
    func noteNames(rootNote: MusicalNote?) -> NoteNames2
}
