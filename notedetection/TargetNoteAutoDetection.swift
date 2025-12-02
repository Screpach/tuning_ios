import Foundation

class TargetNoteAutoDetection {
    
    private let musicalScale: MusicalScale2
    private let sortedStrings: SortedAndDistinctInstrumentStrings
    private let instrument: Instrument
    
    init(musicalScale: MusicalScale2, instrument: Instrument) {
        self.musicalScale = musicalScale
        self.instrument = instrument
        self.sortedStrings = SortedAndDistinctInstrumentStrings(instrument: instrument, musicalScale: musicalScale)
    }
    
    /// Returns a frequency range [low, high] for the target note.
    func getTargetFrequencyRange(
        targetNote: MusicalNote?,
        toleranceInCents: Float
    ) -> (min: Float, max: Float) {
        
        guard let note = targetNote else { return (0, Float.greatestFiniteMagnitude) }
        
        // If not chromatic and we have defined strings, constrain to halfway between strings.
        // Otherwise, standard +/- tolerance or halfway between semitones.
        
        let centerFreq = musicalScale.getNoteFrequency(noteIndex: musicalScale.getNoteIndex2(note: note))
        
        // Simplified range logic for Phase 1
        // Usually: f * 2^(-tolerance/1200) to f * 2^(+tolerance/1200)
        let ratio = pow(2.0, toleranceInCents / 1200.0)
        return (centerFreq / ratio, centerFreq * ratio)
    }
}
