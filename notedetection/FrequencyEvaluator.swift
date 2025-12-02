import Foundation

/// Result of FrequencyEvaluator.
struct FrequencyEvaluationResult {
    let smoothedFrequency: Float
    let target: TuningTarget?
    let timeSinceLastDetection: Float
    let framePosition: Int
}

struct TuningTarget {
    let note: MusicalNote
    let targetFrequency: Float
    let deviationInCents: Float
}

/// Advanced frequency evaluation with note matching.
class FrequencyEvaluator {
    
    private let musicalScale: MusicalScale2
    private let instrument: Instrument
    
    init(numMovingAverage: Int,
         toleranceInCents: Float,
         pitchHistoryNumFaultyValues: Int,
         maxNoise: Float,
         minHarmonicEnergyContent: Float,
         sensitivity: Float,
         musicalScale: MusicalScale2,
         instrument: Instrument) {
        self.musicalScale = musicalScale
        self.instrument = instrument
    }
    
    func evaluate(memory: MemoryPool<FrequencyDetectionCollectedResults>, targetNote: MusicalNote?) -> FrequencyEvaluationResult {
        // 1. Detect Raw Frequency (reuse logic or internal)
        let frequency: Float = 440.0
        
        // 2. Find Target Note
        // If targetNote is provided (manual mode), use it.
        // Else, find closest note in musicalScale.
        
        // 3. Calculate Deviation
        
        return FrequencyEvaluationResult(
            smoothedFrequency: frequency,
            target: nil,
            timeSinceLastDetection: 0.0,
            framePosition: 0
        )
    }
}
