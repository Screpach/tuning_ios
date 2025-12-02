import Foundation

struct MaximumOfPolynomialFit {
    let time: Float
    let value: Float
}

/// Finds the peak of a parabola fitted to three points.
func getPeakOfPolynomialFit(
    valueLeft: Float, valueCenter: Float, valueRight: Float,
    timeCenter: Float, dt: Float
) -> MaximumOfPolynomialFit {
    
    // Parabola y = a*x^2 + b*x + c
    // Shift coordinate system so timeCenter is 0. x points are -1, 0, 1.
    
    let denominator = valueLeft - 2 * valueCenter + valueRight
    if abs(denominator) < 1e-9 {
        // Linear or flat, return center
        return MaximumOfPolynomialFit(time: timeCenter, value: valueCenter)
    }
    
    // Relative shift of peak (-0.5 to 0.5)
    let tRel = (valueLeft - valueRight) / (2 * denominator)
    
    // Coefficients
    let a = 0.5 * denominator
    let b = 0.5 * (valueRight - valueLeft)
    let c = valueCenter
    
    let peakValue = a * tRel * tRel + b * tRel + c
    let peakTime = dt * tRel + timeCenter
    
    return MaximumOfPolynomialFit(time: peakTime, value: peakValue)
}

/// Helper for array access
func getPeakOfPolynomialFitArray(indexCenter: Int, data: [Float]) -> MaximumOfPolynomialFit {
    if indexCenter <= 0 || indexCenter >= data.count - 1 {
        return MaximumOfPolynomialFit(time: Float(indexCenter), value: data[indexCenter])
    }
    
    return getPeakOfPolynomialFit(
        valueLeft: data[indexCenter - 1],
        valueCenter: data[indexCenter],
        valueRight: data[indexCenter + 1],
        timeCenter: Float(indexCenter),
        dt: 1.0
    )
}
