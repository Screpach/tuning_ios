import Foundation

/// Predicts the frequency of a given harmonic based on previous harmonics.
///
/// Uses the model: f = f1 * h + alpha * h^2
/// (Equivalent to f = f1 * h * (1 + beta * h))
class HarmonicPredictor {
    
    // Sums for Least Squares Fit
    private var sumFh: Float = 0
    private var sumFh2: Float = 0
    private var sumH2: Float = 0
    private var sumH3: Float = 0
    private var sumH4: Float = 0
    
    // Model parameters
    private var alpha: Float = 0
    private var beta: Float = 0
    private var f1: Float = 0
    
    /// Reset predictor.
    func clear() {
        sumFh = 0
        sumFh2 = 0
        sumH2 = 0
        sumH3 = 0
        sumH4 = 0
        alpha = 0
        beta = 0
        f1 = 0
    }
    
    /// Add new harmonic data to the model.
    /// - Parameters:
    ///   - harmonicNumber: The integer index of the harmonic (1, 2, 3...)
    ///   - frequency: The measured frequency.
    func add(harmonicNumber: Int, frequency: Float) {
        let h = Float(harmonicNumber)
        let hSqr = h * h
        let hCub = h * hSqr
        let hQuad = hSqr * hSqr
        
        sumFh += frequency * h
        sumFh2 += frequency * hSqr
        sumH2 += hSqr
        sumH3 += hCub
        sumH4 += hQuad
        
        if f1 == 0 {
            f1 = frequency / h
        } else {
            // Least squares solution for alpha and f1
            let denominator = sumH4 * sumH2 - sumH3 * sumH3
            if abs(denominator) > 1e-9 {
                alpha = (sumFh2 * sumH2 - sumFh * sumH3) / denominator
                f1 = (sumFh - alpha * sumH3) / sumH2
            }
            if abs(f1) > 1e-9 {
                beta = alpha / f1
            }
        }
    }
    
    /// Predicts the frequency for a harmonic number.
    func predictFrequency(harmonicNumber: Int) -> Float {
        let h = Float(harmonicNumber)
        // f = f1 * h + alpha * h^2
        return f1 * h + alpha * h * h
    }
}
