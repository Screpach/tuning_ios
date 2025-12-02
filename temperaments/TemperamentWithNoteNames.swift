import Foundation

/// Legacy wrapper for temperament and note names.
/// Equivalent to `TemperamentWithNoteNames.kt`.
struct TemperamentWithNoteNames: Codable, Sendable {
    let temperament: Temperament
    let noteNames: NoteNames?
    
    func toNew() -> Temperament3Custom {
        // Resolve legacy resources
        let resolvedName = temperament.name.resolve()
        let resolvedAbbr = temperament.abbreviation.resolve()
        let resolvedDesc = temperament.description.resolve()
        
        return Temperament3Custom(
            name: resolvedName,
            abbreviation: resolvedAbbr,
            description: resolvedDesc,
            cents: temperament.cents,
            rationalNumbers: [], // Legacy usually didn't store these here
            noteNames: noteNames?.notes,
            stableId: temperament.stableId
        )
    }
}
