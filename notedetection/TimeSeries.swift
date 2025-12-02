import Foundation

/// Stores a time series of data with constant time spacing.
/// Equivalent to `TimeSeries.kt`.
class TimeSeries: Sendable {
    
    let size: Int
    let dt: Float
    
    /// Frame position of the start of this series.
    var framePosition: Int = 0
    
    /// The data values.
    var values: [Float]
    
    /// Creates a new TimeSeries.
    /// - Parameters:
    ///   - size: Number of values.
    ///   - dt: Time difference between two successive samples (1/sampleRate).
    init(size: Int, dt: Float) {
        self.size = size
        self.dt = dt
        self.values = [Float](repeating: 0.0, count: size)
    }
    
    /// Access data at given index.
    subscript(index: Int) -> Float {
        get { values[index] }
        set { values[index] = newValue }
    }
}
