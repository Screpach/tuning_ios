import Foundation

/// Class for computing online mean and variance.
///
/// Equivalent to `UpdatableStatistics.kt`.
/// Uses the weighted incremental algorithm of Welford to calculate statistics
/// without storing the full history of values.
/// See: https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
struct UpdatableStatistics: Sendable {
    
    // MARK: - State
    
    /// Current sum of weights.
    private var weightSum: Float = 0.0
    
    /// Intermediate value needed for variance.
    private var S: Float = 0.0
    
    /// Current mean value.
    private(set) var mean: Float = 0.0
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Computed Properties
    
    /// Current variance.
    var variance: Float {
        return (weightSum == 0.0) ? 0.0 : S / weightSum
    }
    
    /// Current standard deviation.
    var standardDeviation: Float {
        return sqrt(variance)
    }
    
    // MARK: - Mutating Methods
    
    /// Reset to zero.
    mutating func clear() {
        weightSum = 0.0
        S = 0.0
        mean = 0.0
    }
    
    /// Update the statistics with an additional value and weight.
    ///
    /// - Parameters:
    ///   - value: Value which should be considered in mean and variance.
    ///   - weight: Weight for weighted mean and variance.
    mutating func update(value: Float, weight: Float) {
        weightSum += weight
        
        let meanOld = mean
        // mean_new = mean_old + (weight / weightSum) * (value - mean_old)
        mean = meanOld + (weight / weightSum) * (value - meanOld)
        
        // S_new = S_old + weight * (value - mean_old) * (value - mean_new)
        S += weight * (value - meanOld) * (value - mean)
    }
}
