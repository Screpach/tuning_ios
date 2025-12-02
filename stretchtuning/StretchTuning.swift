import Foundation

// MARK: - Model Definition

/// Represents a stretch tuning curve.
///
/// Equivalent to `de.moekadu.tuner.stretchtuning.StretchTuning`.
/// Defines how frequencies should be shifted (in cents) across the spectrum.
struct StretchTuning: Identifiable, Hashable, Codable, Sendable {
    
    // MARK: - Constants
    
    static let NO_KEY: Int = Int.max
    static let NO_STABLE_ID: Int64 = Int64.max
    
    // MARK: - Properties
    
    let name: String
    let description: String
    let unstretchedFrequencies: [Double]
    let stretchInCents: [Double]
    let keys: [Int]
    let stableId: Int64
    
    var id: Int64 { stableId }
    
    // MARK: - Initialization
    
    init(name: String,
         description: String,
         unstretchedFrequencies: [Double],
         stretchInCents: [Double],
         keys: [Int]? = nil,
         stableId: Int64) {
        self.name = name
        self.description = description
        self.unstretchedFrequencies = unstretchedFrequencies
        self.stretchInCents = stretchInCents
        self.stableId = stableId
        
        // If keys are not provided, generate them (or use default if empty)
        if let keys = keys {
            self.keys = keys
        } else {
            // Generate simple unique keys if creating fresh
            // In a real port, we'd use the random generation logic if strictly needed,
            // but for mapped types, indices often suffice.
            self.keys = (0..<unstretchedFrequencies.count).map { _ in Int.random(in: 0..<Int.max) }
        }
    }
    
    // MARK: - Application Logic
    
    /// Applies the stretch tuning to a given frequency.
    ///
    /// - Parameter frequency: The base frequency (unstretched).
    /// - Returns: The stretched frequency.
    func apply(frequency: Float) -> Float {
        let correction = getCents(frequency: frequency)
        // f_stretched = f * 2^(cents / 1200)
        return frequency * pow(2.0, correction / 1200.0)
    }
    
    /// Calculates the cent correction for a given frequency.
    func getCents(frequency: Float) -> Float {
        guard !unstretchedFrequencies.isEmpty else { return 0.0 }
        
        // 1. Convert to Double for precision matching
        let freq = Double(frequency)
        
        // 2. Handle Edge Cases (Out of bounds)
        if freq <= unstretchedFrequencies.first! {
            return Float(stretchInCents.first!)
        }
        if freq >= unstretchedFrequencies.last! {
            return Float(stretchInCents.last!)
        }
        
        // 3. Binary Search for interval
        // Find first element greater than freq
        var insertionIndex = 0
        var low = 0
        var high = unstretchedFrequencies.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            if unstretchedFrequencies[mid] < freq {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        insertionIndex = low
        
        // 4. Interpolate
        // Interval is between [i-1] and [i]
        let i = insertionIndex
        let f0 = unstretchedFrequencies[i - 1]
        let f1 = unstretchedFrequencies[i]
        let c0 = stretchInCents[i - 1]
        let c1 = stretchInCents[i]
        
        // Logarithmic Interpolation (Linear in Pitch space)
        // ratio = (log(f) - log(f0)) / (log(f1) - log(f0))
        let logF = log2(freq)
        let logF0 = log2(f0)
        let logF1 = log2(f1)
        
        let ratio = (logF - logF0) / (logF1 - logF0)
        let interpolatedCents = c0 + (c1 - c0) * ratio
        
        return Float(interpolatedCents)
    }
    
    // MARK: - Modification (Immutable)
    
    /// Returns a new instance with the added point.
    func add(unstretchedFrequency: Double, stretchVal: Double, key: Int = Int.random(in: 0..<Int.max)) -> StretchTuning {
        // Find position
        var position = 0
        var found = false
        
        // Simple linear scan for insertion point (Kotlin binarySearch equivalent)
        for i in 0..<unstretchedFrequencies.count {
            if abs(unstretchedFrequencies[i] - unstretchedFrequency) < 0.0001 {
                position = i
                found = true
                break
            }
            if unstretchedFrequencies[i] > unstretchedFrequency {
                position = i
                break
            }
            position = i + 1
        }
        
        if found {
            return modify(at: position, unstretchedFrequency: unstretchedFrequency, stretchVal: stretchVal, key: keys[position])
        } else {
            var newFreqs = unstretchedFrequencies
            var newCents = stretchInCents
            var newKeys = keys
            
            newFreqs.insert(unstretchedFrequency, at: position)
            newCents.insert(stretchVal, at: position)
            newKeys.insert(key, at: position)
            
            return StretchTuning(
                name: name,
                description: description,
                unstretchedFrequencies: newFreqs,
                stretchInCents: newCents,
                keys: newKeys,
                stableId: stableId
            )
        }
    }
    
    func modify(at index: Int, unstretchedFrequency: Double, stretchVal: Double, key: Int) -> StretchTuning {
        guard index >= 0 && index < unstretchedFrequencies.count else { return self }
        
        var newFreqs = unstretchedFrequencies
        var newCents = stretchInCents
        var newKeys = keys
        
        newFreqs[index] = unstretchedFrequency
        newCents[index] = stretchVal
        newKeys[index] = key
        
        return StretchTuning(
            name: name,
            description: description,
            unstretchedFrequencies: newFreqs,
            stretchInCents: newCents,
            keys: newKeys,
            stableId: stableId
        )
    }
    
    func remove(at index: Int) -> StretchTuning {
        guard index >= 0 && index < unstretchedFrequencies.count else { return self }
        
        var newFreqs = unstretchedFrequencies
        var newCents = stretchInCents
        var newKeys = keys
        
        newFreqs.remove(at: index)
        newCents.remove(at: index)
        newKeys.remove(at: index)
        
        return StretchTuning(
            name: name,
            description: description,
            unstretchedFrequencies: newFreqs,
            stretchInCents: newCents,
            keys: newKeys,
            stableId: stableId
        )
    }
}
