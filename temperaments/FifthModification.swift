import Foundation

/// Defines how a fifth deviates from the pure ratio (3/2).
/// Equivalent to `FifthModification.kt`.
struct FifthModification: Codable, Equatable, Sendable {
    
    var pythagoreanComma: RationalNumber
    var syntonicComma: RationalNumber
    var schisma: RationalNumber
    
    init(pythagoreanComma: RationalNumber = RationalNumber(0, 1),
         syntonicComma: RationalNumber = RationalNumber(0, 1),
         schisma: RationalNumber = RationalNumber(0, 1)) {
        self.pythagoreanComma = pythagoreanComma
        self.syntonicComma = syntonicComma
        self.schisma = schisma
        simplify()
    }
    
    // MARK: - Constants
    
    static let pythagoreanCommaRatio = RationalNumber(531441, 524288)
    static let syntonicCommaRatio = RationalNumber(81, 80)
    static let schismaRatio = RationalNumber(32805, 32768)
    
    // MARK: - Logic
    
    func toDouble() -> Double {
        // ratio = 1.0 * (P_ratio ^ P_exp) * (S_ratio ^ S_exp) ...
        // Note: Comma ratios are roughly 1.01, so we multiply them.
        
        // P_ratio^P_val
        let pVal = pythagoreanComma.numerator != 0 ?
            Foundation.pow(FifthModification.pythagoreanCommaRatio.toDouble(), pythagoreanComma.toDouble()) : 1.0
        
        let sVal = syntonicComma.numerator != 0 ?
            Foundation.pow(FifthModification.syntonicCommaRatio.toDouble(), syntonicComma.toDouble()) : 1.0
        
        let scVal = schisma.numerator != 0 ?
            Foundation.pow(FifthModification.schismaRatio.toDouble(), schisma.toDouble()) : 1.0
        
        return pVal * sVal * scVal
    }
    
    // MARK: - Operators
    
    static func + (lhs: FifthModification, rhs: FifthModification) -> FifthModification {
        var res = FifthModification(
            pythagoreanComma: RationalNumber(
                lhs.pythagoreanComma.numerator * rhs.pythagoreanComma.denominator + rhs.pythagoreanComma.numerator * lhs.pythagoreanComma.denominator,
                lhs.pythagoreanComma.denominator * rhs.pythagoreanComma.denominator
            ),
            syntonicComma: RationalNumber(
                lhs.syntonicComma.numerator * rhs.syntonicComma.denominator + rhs.syntonicComma.numerator * lhs.syntonicComma.denominator,
                lhs.syntonicComma.denominator * rhs.syntonicComma.denominator
            ),
            schisma: RationalNumber(
                lhs.schisma.numerator * rhs.schisma.denominator + rhs.schisma.numerator * lhs.schisma.denominator,
                lhs.schisma.denominator * rhs.schisma.denominator
            )
        )
        res.simplify()
        return res
    }
    
    static func - (lhs: FifthModification, rhs: FifthModification) -> FifthModification {
        return lhs + (-rhs)
    }
    
    static prefix func - (val: FifthModification) -> FifthModification {
        return FifthModification(
            pythagoreanComma: -val.pythagoreanComma,
            syntonicComma: -val.syntonicComma,
            schisma: -val.schisma
        )
    }
    
    static func -= (lhs: inout FifthModification, rhs: FifthModification) {
        lhs = lhs - rhs
    }
    
    // MARK: - Simplification
    
    mutating func simplify() {
        // 1 pythagoreanComma = 1 syntonicComma + 1 schisma
        // Logic to keep numbers simple if possible
        
        // Case 1: Syntonic == Schisma -> convert to Pythagorean
        if syntonicComma == schisma && !syntonicComma.isZero {
            // This assumes coefficients are equal.
            // P = S + Sc = 2S
            // Logic in Kotlin: if (syntonic == schisma) P += schisma (adding 1 unit? or value?)
            // Kotlin snippet says: pythagoreanComma += schisma
            
            // RationalNumber addition is needed here.
            // Since RationalNumber is struct, we need to implement addition for it or do it manually.
            // Implementing basic add helper here for simplification
            
            pythagoreanComma = addRationals(pythagoreanComma, schisma)
            schisma.setZero()
            syntonicComma.setZero()
        }
        // Other simplification cases from Kotlin...
        // pythagorean == -schisma -> syntonic += pythagorean
        else if pythagoreanComma == -schisma && !pythagoreanComma.isZero {
            syntonicComma = addRationals(syntonicComma, pythagoreanComma)
            schisma.setZero()
            pythagoreanComma.setZero()
        }
        else if pythagoreanComma == -syntonicComma && !pythagoreanComma.isZero {
            schisma = addRationals(schisma, pythagoreanComma)
            pythagoreanComma.setZero()
            syntonicComma.setZero()
        }
    }
    
    private func addRationals(_ a: RationalNumber, _ b: RationalNumber) -> RationalNumber {
        return RationalNumber(a.numerator * b.denominator + b.numerator * a.denominator, a.denominator * b.denominator)
    }
}
