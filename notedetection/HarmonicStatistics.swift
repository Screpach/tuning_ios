import Foundation

class HarmonicStatistics {
    
    var frequency: Float { frequencyStatistics.mean }
    var frequencyVariance: Float { frequencyStatistics.variance }
    var frequencyStandardDeviation: Float { frequencyStatistics.standardDeviation }
    
    private var frequencyStatistics = UpdatableStatistics()
    
    func clear() {
        frequencyStatistics.clear()
    }
    
    func evaluate(harmonics: Harmonics, weighting: AcousticWeighting) {
        clear()
        
        for harmonic in harmonics.harmonics {
            let amplitude = sqrt(harmonic.spectrumAmplitudeSquared)
            let weight = weighting.applyToAmplitude(amplitude: amplitude, freq: harmonic.frequency)
            
            // Normalize harmonic frequency to fundamental
            let frequencyBase = harmonic.frequency / Float(harmonic.harmonicNumber)
            
            frequencyStatistics.update(value: frequencyBase, weight: weight)
        }
    }
}
