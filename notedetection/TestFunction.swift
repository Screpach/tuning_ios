import Foundation

/// Types of test functions available.
enum TestFunctionType {
    case off
    case constant
    case constantAccurate
    case linear
    case exponential
    case random
}

/// Global configuration for the active test function.
/// In a real app, this might be injected via dependency injection or debug settings.
var currentTestFunctionType: TestFunctionType = .off

/// Returns a closure that generates a sample value for a given frame and time delta.
/// - Returns: `(frame: Int, dt: Float) -> Float` or nil if disabled.
func getTestFunction() -> ((Int, Float) -> Float)? {
    switch currentTestFunctionType {
    case .off:
        return nil
        
    case .constant:
        // Constant 440Hz sine wave
        return { frame, dt in
            let freq: Float = 440.0
            return sin(Float(frame) * dt * 2 * .pi * freq)
        }
        
    case .constantAccurate:
        // Frequency aligned to sample grid to avoid spectral leakage
        return { frame, dt in
            let freqApprox: Float = 660.0
            let numSteps = round(1.0 / (freqApprox * dt))
            let freq = 1.0 / (numSteps * dt)
            // Modulo frame to keep precision high? Kotlin code did this.
            // val frameMod = frame - (frame / numSteps) * numSteps
            // In Swift:
            let frameMod = Float(frame).truncatingRemainder(dividingBy: numSteps)
            return sin(frameMod * dt * 2 * .pi * freq)
        }
        
    case .linear:
        // Linear sweep: 200Hz + 2Hz/sec
        return { frame, dt in
            let t = Float(frame) * dt
            let freq = 200.0 + 2.0 * t
            let phase = t * 2 * .pi * freq // Note: Integral of freq is better for sweeps, but matching Kotlin source
            // Kotlin: sin(frame * dt * 2 * PI * freq) -> This is actually freq(t) * t, which is a chirp.
            
            let base = sin(t * 2 * .pi * freq)
            let h2 = 0.3 * sin(2 * t * 2 * .pi * freq)
            let h3 = 0.5 * sin(3 * t * 2 * .pi * freq)
            return base + Float(h2) + Float(h3)
        }
        
    case .exponential:
        return { frame, dt in
            let t = Float(frame) * dt
            let freq = 200.0 * pow(2.0, t / 24.0)
            
            let base = sin(t * 2 * .pi * freq)
            let h2 = 0.3 * sin(2 * t * 2 * .pi * freq)
            let h3 = 0.5 * sin(3 * t * 2 * .pi * freq)
            return base + Float(h2) + Float(h3)
        }
        
    case .random:
        // Random noise
        return { _, _ in
            return Float.random(in: -1...1)
        }
    }
}
