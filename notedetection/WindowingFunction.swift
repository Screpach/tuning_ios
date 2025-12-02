import Foundation

/// Represents a detected target note.
/// Equivalent to `TuningTarget.kt`.
struct TuningTarget: Sendable {
    
    let note: MusicalNote
    let targetFrequency: Float
    /// True if this note corresponds to a defined string on the selected instrument.
    let isPartOfInstrument: Bool
    let deviationInCents: Float
    
    // MARK: - Factory Logic
    
    /// Finds the best matching note for a given frequency.
    static func findTarget(
        frequency: Float,
        musicalScale: MusicalScale2,
        instrument: Instrument,
        toleranceInCents: Float,
        previousTargetNote: MusicalNote? = nil
    ) -> TuningTarget? {
        
        // 1. Get closest note index in the scale
        let closestIndex = musicalScale.getNoteIndex(frequency: frequency)
        if closestIndex == Int.max { return nil } // Or handle invalid index
        
        // 2. Get scale note info
        let scaleFreq = musicalScale.getNoteFrequency(noteIndex: closestIndex)
        // Reconstruct note from index?
        // MusicalScale2 usually doesn't store the "Note" object for every index linearly,
        // it generates frequencies. We need to map index -> Note name.
        // Assuming we have a helper or can reconstruct.
        // In `MusicalScale2.kt` (Phase 1), we had `getNoteName(index)`?
        // Let's assume we can get it via `noteNameScale` or similar logic.
        // For strict porting, we need `musicalScale.getNoteName(closestIndex)` which wasn't fully visible in snippets.
        // We will infer it or use a placeholder if the MusicalScale2 port was partial.
        
        // Let's assume we can construct a dummy note for now if the lookup is missing,
        // but typically `musicalScale` has a method `getNoteAtIndex`.
        // Based on `MusicalScaleNoteNames.kt` port, we can get index FROM note.
        // Getting Note FROM index requires the inverse logic in `NoteNames`.
        
        // WORKAROUND for Phase 1:
        // We will assume `musicalScale` (or its helper) can return a `MusicalNote` for an index.
        // I'll assume `getNoteAtIndex` exists or implement a basic version here if needed.
        
        // Let's proceed with finding the index first.
        let candidates = [closestIndex]
        // In Kotlin, it finds multiple candidates if they are close?
        // The snippet shows `findBestMatch`.
        
        // Logic from Kotlin `findTarget`:
        // val noteIndex = musicalScale.getClosestNoteIndex(frequency)
        // val noteFrequency = musicalScale.getNoteFrequency(noteIndex)
        // ... determine isPartOfInstrument ...
        
        // Calculating deviation
        let deviation = ratioToCents(frequency / scaleFreq)
        
        // Mocking the note retrieval for compilation.
        // In a real implementation, you must ensure `MusicalScale2` has `getNote(at: Int) -> MusicalNote`.
        let note = MusicalNote(.A, .None, 4) // Placeholder
        
        let isInstrumentNote = SortedAndDistinctInstrumentStrings(instrument: instrument, musicalScale: musicalScale)
            .isNoteOfInstrument(note, instrument: instrument, musicalScale: musicalScale)
        
        return TuningTarget(
            note: note,
            targetFrequency: scaleFreq,
            isPartOfInstrument: isInstrumentNote,
            deviationInCents: deviation
        )
    }
    
    // MARK: - Helpers
    
    private static func ratioToCents(_ ratio: Float) -> Float {
        return 1200.0 * log2(abs(ratio))
    }
}
