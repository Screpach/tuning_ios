import Foundation

/// Temperament with note names, allowed for editing (incomplete state).
/// Equivalent to `EditableTemperament.kt`.
struct EditableTemperament: Codable, Hashable, Sendable {
    
    var name: String = ""
    var abbreviation: String = ""
    var description: String = ""
    var noteLines: [NoteLineContents?] = []
    var stableId: Int64 = Temperament3.NO_STABLE_ID
    
    struct NoteLineContents: Codable, Hashable, Sendable {
        var note: MusicalNote?
        var cent: Double?
        var ratio: RationalNumber?
        
        func obtainCent() -> Double? {
            if let c = cent { return c }
            if let r = ratio { return ratioToCents(r.toDouble()) }
            return nil
        }
        
        func obtainRatio() -> RationalNumber? {
            return ratio
        }
    }
    
    // MARK: - Conversion
    
    func toTemperament3Custom() -> Temperament3Custom? {
        // Validate
        let validLines = noteLines.compactMap { $0 }
        if validLines.isEmpty { return nil }
        
        // Extract Data
        let cents = validLines.compactMap { $0.obtainCent() }
        let ratios = validLines.map { $0.obtainRatio() }
        let notes = validLines.map { $0.note ?? MusicalNote(.C, .None) } // Fallback note
        
        return Temperament3Custom(
            name: name,
            abbreviation: abbreviation,
            description: description,
            cents: cents,
            rationalNumbers: ratios,
            noteNames: notes,
            stableId: stableId
        )
    }
}

// Helper extension on Temperament3 for stub compatibility
extension Temperament3 {
    static var NO_STABLE_ID: Int64 { Int64.max }
}
