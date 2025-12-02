import Foundation
import Accelerate

/// Wrapper for Fast Fourier Transform operations.
///
/// Uses Apple's Accelerate framework (vDSP) for high-performance signal processing.
class FFT {
    
    let size: Int
    private let log2n: vDSP_Length
    private let fftSetup: vDSP_FFTSetup?
    
    init(size: Int) {
        self.size = size
        self.log2n = vDSP_Length(log2(Float(size)))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
    
    /// Computes the Real-to-Complex FFT.
    ///
    /// - Parameters:
    ///   - input: Array of real values. Size must match `size`.
    ///   - output: Array to store complex results (Real/Imag interleaved or split).
    ///     For simplicity in this port, we return a tuple of (real, imag) arrays.
    func compute(input: [Float]) -> (real: [Float], imag: [Float]) {
        guard let fftSetup = fftSetup else { return ([], []) }
        
        // Convert input to Split Complex format
        var real = [Float](repeating: 0.0, count: size / 2)
        var imag = [Float](repeating: 0.0, count: size / 2)
        
        // Pack: Even indices -> Real, Odd indices -> Imag (standard trick for Real FFT)
        // Or use vDSP_ctoz to convert interleaved [r0, i0, r1, i1...]
        // But input is purely real [r0, r1, r2...].
        // Accelerate's real FFT expects packed data.
        
        input.withUnsafeBufferPointer { inputPtr in
            inputPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: size / 2) { complexPtr in
                var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(size / 2))
                
                // Perform FFT
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
                
                // Scale (vDSP FFT scales by 2, usually needs 1/2 scaling or similar depending on convention)
                // We leave raw values unless normalization is required by the caller.
            }
        }
        
        // Unpack or handle specific format (DC component, Nyquist) logic if needed
        // For correlation, usually we just need the complex spectrum.
        
        return (real, imag)
    }
    
    /// Number of frequencies for a real FFT (Size/2 + 1).
    static func numFrequenciesReal(size: Int) -> Int {
        return size / 2 + 1
    }
}
