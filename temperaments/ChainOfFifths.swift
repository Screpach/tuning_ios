import Foundation

/// Chain of fifths definition of a temperament.
/// Equivalent to `ChainOfFifths.kt`.
struct ChainOfFifths: Codable, Equatable, Sendable {
    
    let fifths: [FifthModification]
    let rootIndex: Int
    
    // MARK: - Factory
    
    static func create(fifths: [FifthModification], rootIndex: Int) -> ChainOfFifths {
        return ChainOfFifths(fifths: fifths, rootIndex: rootIndex)
    }
    
    // MARK: - Logic
    
    func getClosingCircleCorrection() -> FifthModification {
        var total = FifthModification(pythagoreanComma: RationalNumber(-1, 1))
        for fifth in fifths {
            total -= fifth
        }
        return total
    }
    
    func getRatiosAlongFifths() -> [Double] {
        var ratios = [Double](repeating: 1.0, count: fifths.count + 1)
        ratios[rootIndex] = 1.0
        
        let threeHalf = RationalNumber(3, 2)
        var fifthRatio = RationalNumber(1, 1)
        var totalCorrection = FifthModification()
        
        // Go Up
        if rootIndex < fifths.count {
            for i in rootIndex..<fifths.count {
                totalCorrection = totalCorrection + fifths[i] // using operator +
                fifthRatio *= threeHalf
                
                // Keep ratio between 1 and 2 (normalize octave)
                while fifthRatio.numerator > 2 * fifthRatio.denominator {
                    fifthRatio /= 2
                }
                
                ratios[i + 1] = fifthRatio.toDouble() * totalCorrection.toDouble()
            }
        }
        
        // Go Down
        fifthRatio = RationalNumber(1, 1)
        totalCorrection = FifthModification()
        if rootIndex > 0 {
            for i in (0..<rootIndex).reversed() {
                totalCorrection -= fifths[i]
                fifthRatio /= threeHalf
                
                while fifthRatio.numerator < fifthRatio.denominator {
                    fifthRatio *= 2
                }
                
                ratios[i] = fifthRatio.toDouble() * totalCorrection.toDouble()
            }
        }
        
        return ratios
    }
    
    func getSortedRatios() -> [Double] {
        return getRatiosAlongFifths().sorted()
    }
}
