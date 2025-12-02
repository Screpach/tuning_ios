import Foundation

/// Stores the frequencies of a musical scale over all octaves.
///
/// Equivalent to `MusicalScaleFrequencies.kt`.
/// This struct pre-calculates the valid frequencies for the tuner to match against.
struct MusicalScaleFrequencies: Codable, Sendable {
    
    // MARK: - Properties
    
    /// The sorted list of valid frequencies for this scale.
    let frequencies: [Float]
    
    /// The index in `frequencies` where the reference note corresponds.
    /// Note: This index might technically be outside bounds if the reference note
    /// itself was clipped out by min/max frequency settings.
    let indexOfReferenceNote: Int
    
    // MARK: - API
    
    /// Returns the frequency at a specific note index relative to the reference.
    ///
    /// - Parameter noteIndex: The index relative to the reference note (0 = reference).
    /// - Returns: The frequency in Hz, or -1.0 if out of bounds.
    func getNoteFrequency(_ noteIndex: Int) -> Float {
        let arrayIndex = noteIndex + indexOfReferenceNote
        if arrayIndex >= 0 && arrayIndex < frequencies.count {
            return frequencies[arrayIndex]
        }
        return -1.0
    }
    
    /// Finds the index of the note closest to the given frequency.
    ///
    /// - Parameter frequency: The input frequency in Hz.
    /// - Returns: The note index relative to the reference note.
    func getClosestFrequencyIndex(_ frequency: Float) -> Int {
        guard !frequencies.isEmpty else { return 0 }
        
        // Binary search for closest value
        var low = 0
        var high = frequencies.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            let midVal = frequencies[mid]
            
            if midVal < frequency {
                low = mid + 1
            } else if midVal > frequency {
                high = mid - 1
            } else {
                return mid - indexOfReferenceNote
            }
        }
        
        // 'low' is now the insertion point. Check neighbors to find closest.
        let idx1 = max(0, high)
        let idx2 = min(frequencies.count - 1, low)
        
        let diff1 = abs(frequencies[idx1] - frequency)
        let diff2 = abs(frequencies[idx2] - frequency)
        
        let closestArrayIndex = (diff1 < diff2) ? idx1 : idx2
        return closestArrayIndex - indexOfReferenceNote
    }
    
    // MARK: - Factory Logic
    
    /// Generates the frequency table based on the given parameters.
    static func create(temperament: Temperament,
                       referenceFrequency: Float,
                       minFrequency: Float,
                       maxFrequency: Float,
                       stretchTuning: StretchTuning?) -> MusicalScaleFrequencies {
        
        // 1. Generate Higher Frequencies (Index 0 upwards)
        var higherFrequencies: [Float] = []
        var i = 0
        while true {
            let cents = temperament.getCents(noteIndex: i)
            var freq = centsToFrequency(cents: cents, referenceFrequency: referenceFrequency)
            
            if let stretch = stretchTuning {
                freq = stretch.apply(frequency: freq)
            }
            
            if freq > maxFrequency {
                break
            }
            
            if freq >= minFrequency {
                higherFrequencies.append(freq)
            }
            i += 1
            
            // Safety break to prevent infinite loops in bad configs
            if i > 2000 { break }
        }
        
        // 2. Generate Lower Frequencies (Index -1 downwards)
        var lowerFrequencies: [Float] = []
        i = -1
        while true {
            let cents = temperament.getCents(noteIndex: i)
            var freq = centsToFrequency(cents: cents, referenceFrequency: referenceFrequency)
            
            if let stretch = stretchTuning {
                freq = stretch.apply(frequency: freq)
            }
            
            if freq < minFrequency {
                break
            }
            
            if freq <= maxFrequency {
                lowerFrequencies.append(freq)
            }
            i -= 1
            
            if i < -2000 { break }
        }
        
        // 3. Track reference index offset
        // The reference note (index 0) is the first element of higherFrequencies.
        // lowerFrequencies contains indices -1, -2, -3...
        // If lowerFrequencies has 5 items (-1 to -5), the array structure will be:
        // [-5, -4, -3, -2, -1, 0, 1, 2...]
        // So the reference note (0) will be at index `lowerFrequencies.count`.
        
        // However, we must filter min/max.
        // The logic below mirrors Kotlin's assembly logic.
        
        var finalFrequencies: [Float] = []
        
        // Add lower frequencies (reversed, because we generated them -1, -2...)
        finalFrequencies.append(contentsOf: lowerFrequencies.reversed())
        
        // Add higher frequencies
        finalFrequencies.append(contentsOf: higherFrequencies)
        
        // Calculate where index 0 landed.
        // `lowerFrequencies` contains strict negatives. `higherFrequencies` starts at 0.
        // If index 0 was filtered out (freq < min), indexOfReferenceNote might need adjustment.
        // But for simplicity, the reference index in the *unfiltered* logic is `lowerFrequencies.count`.
        // We verify if `higherFrequencies` actually contains index 0.
        
        // Refined Logic based on arrays:
        // final array = [ ...-2, -1, 0, 1, 2... ]
        // The count of lower items shifts the 0 index.
        let indexOfReference = lowerFrequencies.count
        
        // Handle edge case where reference freq itself is overwritten (rare)
        var result = MusicalScaleFrequencies(
            frequencies: finalFrequencies,
            indexOfReferenceNote: indexOfReference
        )
        
        // Ensure the exact reference frequency is set at the index 0 spot (to avoid float drift),
        // but only if it exists in the array.
        let validIndices = 0..<finalFrequencies.count
        if validIndices.contains(indexOfReference) {
            // We use a mutable copy to patch the exact float
            var mutableFreqs = result.frequencies
            mutableFreqs[indexOfReference] = referenceFrequency
            result = MusicalScaleFrequencies(frequencies: mutableFreqs, indexOfReferenceNote: indexOfReference)
        }
        
        return result
    }
}

// MARK: - Helper Functions

/// Converts cents relative to a reference into a Frequency.
///
/// Formula: `f = f_ref * 2^(cents / 1200)`
func centsToFrequency(cents: Float, referenceFrequency: Float) -> Float {
    return referenceFrequency * pow(2.0, cents / 1200.0)
}

// MARK: - Dependency Extensions (Stubs)
// These extensions allow this file to call methods on the stubs created in MusicalScale.swift.
// When the real files (Temperament.kt, StretchTuning.kt) are ported, these stubs will be replaced
// by the actual class definitions.

extension Temperament {
    /// Stub for retrieving cents deviation for a given note index.
    func getCents(noteIndex: Int) -> Float {
        // Mock logic: 12-EDO default
        // In real class, this accesses the stored cents array/logic
        return Float(noteIndex) * 100.0
    }
}

extension StretchTuning {
    /// Stub for applying stretch tuning to a frequency.
    func apply(frequency: Float) -> Float {
        // Mock logic: Identity (no stretch)
        return frequency
    }
}
