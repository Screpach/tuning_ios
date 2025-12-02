import Foundation

protocol AcousticWeighting: Sendable {
    func applyToAmplitude(amplitude: Float, freq: Float) -> Float
}

struct AcousticZeroWeighting: AcousticWeighting {
    func applyToAmplitude(amplitude: Float, freq: Float) -> Float {
        return amplitude
    }
}

struct AcousticAWeighting: AcousticWeighting {
    func applyToAmplitude(amplitude: Float, freq: Float) -> Float {
        return amplitude * getWeightingFactor(freq)
    }
    
    private let weighting1000 = getWeightingFactorNonNormalized(1000.0)
    
    private func getWeightingFactor(_ freq: Float) -> Float {
        return getWeightingFactorNonNormalized(freq) / weighting1000
    }
    
    private static func getWeightingFactorNonNormalized(_ freq: Float) -> Float {
        let f2 = freq * freq
        let term1 = pow(12194.0 * f2, 2.0)
        let term2 = (f2 + pow(20.6, 2.0))
        let term3 = sqrt((f2 + pow(107.7, 2.0)) * (f2 + pow(737.9, 2.0)))
        let term4 = (f2 + pow(12194.0, 2.0))
        
        return term1 / (term2 * term3 * term4)
    }
}

struct AcousticCWeighting: AcousticWeighting {
    func applyToAmplitude(amplitude: Float, freq: Float) -> Float {
        return amplitude * getWeightingFactor(freq)
    }
    
    private let weighting1000 = getWeightingFactorNonNormalized(1000.0)
    
    private func getWeightingFactor(_ freq: Float) -> Float {
        return getWeightingFactorNonNormalized(freq) / weighting1000
    }
    
    private static func getWeightingFactorNonNormalized(_ freq: Float) -> Float {
        let f2 = freq * freq
        let num = pow(12194.0 * f2, 2.0)
        let den = (f2 + pow(20.6, 2.0)) * (f2 + pow(12194.0, 2.0))
        return num / den
    }
}
