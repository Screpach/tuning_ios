import Foundation

/// Represents a rational number (fraction).
/// Equivalent to `RationalNumber.kt`.
struct RationalNumber: Codable, Equatable, Sendable, CustomStringConvertible {
    var numerator: Int
    var denominator: Int
    
    init(_ numerator: Int, _ denominator: Int) {
        self.numerator = numerator
        self.denominator = denominator
        reduce()
    }
    
    var isZero: Bool { numerator == 0 }
    var description: String { "\(numerator)/\(denominator)" }
    
    // MARK: - Math
    
    func toDouble() -> Double {
        return Double(numerator) / Double(denominator)
    }
    
    func toFloat() -> Float {
        return Float(numerator) / Float(denominator)
    }
    
    mutating func reduce() {
        if denominator == 0 { return } // Avoid crash, though mathematically undefined
        if denominator < 0 {
            numerator = -numerator
            denominator = -denominator
        }
        let common = RationalNumber.gcd(numerator, denominator)
        if common != 0 {
            numerator /= common
            denominator /= common
        }
    }
    
    // MARK: - Operators
    
    static func * (lhs: RationalNumber, rhs: RationalNumber) -> RationalNumber {
        return RationalNumber(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)
    }
    
    static func * (lhs: RationalNumber, rhs: Int) -> RationalNumber {
        return RationalNumber(lhs.numerator * rhs, lhs.denominator)
    }
    
    static func / (lhs: RationalNumber, rhs: RationalNumber) -> RationalNumber {
        return RationalNumber(lhs.numerator * rhs.denominator, lhs.denominator * rhs.numerator)
    }
    
    static func / (lhs: RationalNumber, rhs: Int) -> RationalNumber {
        return RationalNumber(lhs.numerator, lhs.denominator * rhs)
    }
    
    static func *= (lhs: inout RationalNumber, rhs: RationalNumber) {
        lhs = lhs * rhs
    }
    
    static func /= (lhs: inout RationalNumber, rhs: RationalNumber) {
        lhs = lhs / rhs
    }
    
    static func *= (lhs: inout RationalNumber, rhs: Int) {
        lhs = lhs * rhs
    }
    
    static func /= (lhs: inout RationalNumber, rhs: Int) {
        lhs = lhs / rhs
    }
    
    static prefix func - (val: RationalNumber) -> RationalNumber {
        return RationalNumber(-val.numerator, val.denominator)
    }
    
    func pow(_ exponent: Int) -> RationalNumber {
        var n = 1
        var d = 1
        for _ in 0..<exponent {
            n *= numerator
            d *= denominator
        }
        return RationalNumber(n, d)
    }
    
    mutating func setZero() {
        numerator = 0
        denominator = 1
    }
    
    // MARK: - Helpers
    
    static func gcd(_ a: Int, _ b: Int) -> Int {
        let absA = abs(a)
        let absB = abs(b)
        return calculateGcd(absA, absB)
    }
    
    private static func calculateGcd(_ a: Int, _ b: Int) -> Int {
        if b == 0 { return a }
        return calculateGcd(b, a % b)
    }
}
