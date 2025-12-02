import Foundation

/// Helper to compute inharmonicity between two frequencies.
/// Formula: inharmonicity = log(fa / fb) / log(ha / hb) - 1
func computeInharmonicity(frequency1: Float, harmonicNumber1: Int, frequency2: Float, harmonicNumber2: Int) -> Float {
    let fRatio = (harmonicNumber1 > harmonicNumber2) ? (frequency1 / frequency2) : (frequency2 / frequency1)
    let hRatio = (harmonicNumber1 > harmonicNumber2) ? (Float(harmonicNumber1) / Float(harmonicNumber2)) : (Float(harmonicNumber2) / Float(harmonicNumber1))
    
    return log(fRatio) / log(hRatio) - 1.0
}

/// Class for detecting inharmonicities.
class InharmonicityDetector {
    let maxNumHarmonics: Int
    
    // Statistics accumulator
    private var statistics = UpdatableStatistics()
    
    init(maxNumHarmonics: Int) {
        self.maxNumHarmonics = maxNumHarmonics
    }
    
    var inharmonicity: Float { statistics.mean }
    
    func clear() {
        statistics.clear()
    }
    
    func add(harmonics: Harmonics) {
        // Iterate pairs
        for i in 0..<harmonics.size {
            for j in (i+1)..<harmonics.size {
                let h1 = harmonics[i]
                let h2 = harmonics[j]
                
                if h1.harmonicNumber > maxNumHarmonics || h2.harmonicNumber > maxNumHarmonics {
                    continue
                }
                
                let val = computeInharmonicity(
                    frequency1: h1.frequency, harmonicNumber1: h1.harmonicNumber,
                    frequency2: h2.frequency, harmonicNumber2: h2.harmonicNumber
                )
                
                // Weighting logic (simplified)
                let weight = sqrt(h1.spectrumAmplitudeSquared * h2.spectrumAmplitudeSquared)
                statistics.update(value: val, weight: weight)
            }
        }
    }
}
