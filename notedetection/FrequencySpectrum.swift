import Foundation

/// Result of data in frequency space.
/// Equivalent to `FrequencySpectrum.kt`.
class FrequencySpectrum {
    let size: Int
    let df: Float
    
    var frequencies: [Float]
    var spectrumReal: [Float]
    var spectrumImag: [Float]
    var amplitudeSpectrumSquared: [Float]
    var plottingSpectrumNormalized: [Float]
    
    init(size: Int, df: Float) {
        self.size = size
        self.df = df
        
        self.frequencies = (0..<size).map { Float($0) * df }
        // In Kotlin, spectrum was interleaved float array size 2*N.
        // Here we keep split arrays for easier Accelerate usage.
        self.spectrumReal = [Float](repeating: 0.0, count: size)
        self.spectrumImag = [Float](repeating: 0.0, count: size)
        
        self.amplitudeSpectrumSquared = [Float](repeating: 0.0, count: size)
        self.plottingSpectrumNormalized = [Float](repeating: 0.0, count: size)
    }
    
    func real(_ index: Int) -> Float {
        return spectrumReal[index]
    }
    
    func imag(_ index: Int) -> Float {
        return spectrumImag[index]
    }
}
