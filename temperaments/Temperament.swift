import Foundation

/// Old/Legacy temperament class.
/// Equivalent to `Temperament.kt`.
struct Temperament: Codable, Sendable {
    
    let name: StringOrResId
    let abbreviation: StringOrResId
    let description: StringOrResId
    
    let cents: [Double]
    let equalOctaveDivision: Int?
    let noteNames: NoteNames
    let stableId: Int64
    
    // MARK: - Migration Logic
    
    /// Converts legacy object to modern Temperament3.
    func toNew() -> Temperament3 {
        // Check if it matches a predefined one
        if stableId < 0 {
            // Try to find in predefined list by content matching
            let candidates = predefinedTemperaments()
            
            // 1. EDO Match
            if let edo = equalOctaveDivision {
                return Temperament3EDO(stableId: -1 - Int64(edo) - 5, notesPerOctave: edo)
            }
            
            // 2. Content Match
            if let match = candidates.first(where: {
                areCentsEqual($0.cents(), self.cents)
            }) {
                return match
            }
            
            // 3. Fallback
            return Temperament3EDO(stableId: -1 - 12 - 5, notesPerOctave: 12)
        } else {
            // Custom
            return Temperament3Custom(
                name: name.resolve(),
                abbreviation: abbreviation.resolve(),
                description: description.resolve(),
                cents: cents,
                rationalNumbers: [],
                noteNames: noteNames.notes,
                stableId: stableId
            )
        }
    }
    
    private func areCentsEqual(_ c1: [Double], _ c2: [Double]) -> Bool {
        if c1.count != c2.count { return false }
        for i in 0..<c1.count {
            if abs(c1[i] - c2[i]) > 0.001 { return false }
        }
        return true
    }
}
