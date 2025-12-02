import Foundation

/// Store auto correlation result.
class AutoCorrelation {
    let size: Int
    let dt: Float
    
    var times: [Float]
    var values: [Float]
    var plotValuesNormalized: [Float]
    var plotValuesNormalizedZero: Float = 0.0
    
    init(size: Int, dt: Float) {
        self.size = size
        self.dt = dt
        self.times = (0..<size).map { Float($0) * dt }
        self.values = [Float](repeating: 0.0, count: size)
        self.plotValuesNormalized = [Float](repeating: 0.0, count: size)
    }
    
    subscript(index: Int) -> Float {
        return values[index]
    }
}
