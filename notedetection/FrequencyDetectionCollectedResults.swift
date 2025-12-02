import Foundation

/// Collects all results in the process of frequency detection.
class FrequencyDetectionCollectedResults: Sendable {
    
    // MARK: - Properties
    
    let sizeOfTimeSeries: Int
    let sampleRate: Int
    
    // Buffers (Managed by MemoryPool in real implementation)
    var timeSeries: [Float]
    var spectrum: FrequencySpectrum
    var autoCorrelation: AutoCorrelation
    
    var timeSeriesStandardDeviation: Float = 0.0
    var memory: MemoryPool<FrequencyDetectionCollectedResults>? // Back reference for recycling
    
    // MARK: - Initialization
    
    init(sizeOfTimeSeries: Int, sampleRate: Int) {
        self.sizeOfTimeSeries = sizeOfTimeSeries
        self.sampleRate = sampleRate
        
        self.timeSeries = [Float](repeating: 0.0, count: sizeOfTimeSeries)
        
        // Initialize Spectrum
        // FFT size logic (usually next power of 2 or 2*N)
        let spectrumSize = sizeOfTimeSeries // simplified
        self.spectrum = FrequencySpectrum(size: spectrumSize, df: Float(sampleRate) / Float(spectrumSize))
        
        // Initialize Correlation
        self.autoCorrelation = AutoCorrelation(size: sizeOfTimeSeries, dt: 1.0 / Float(sampleRate))
    }
    
    // MARK: - Memory Management
    
    func decRef() {
        // memory?.recycle(self)
    }
    
    func incRef() {
        // ref counting logic
    }
}
