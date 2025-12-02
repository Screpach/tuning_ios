import Foundation

/// Details about a single harmonic.
struct Harmonic: Comparable {
    var harmonicNumber: Int
    var frequency: Float
    var spectrumIndex: Int
    var spectrumAmplitudeSquared: Float
    
    static func < (lhs: Harmonic, rhs: Harmonic) -> Bool {
        return lhs.harmonicNumber < rhs.harmonicNumber
    }
}

/// Container storing several harmonics.
class Harmonics {
    var harmonics: [Harmonic]
    private let maxCapacity: Int
    
    init(maxCapacity: Int) {
        self.maxCapacity = maxCapacity
        self.harmonics = []
        self.harmonics.reserveCapacity(maxCapacity)
    }
    
    var size: Int { harmonics.count }
    
    subscript(index: Int) -> Harmonic {
        get { harmonics[index] }
        set { harmonics[index] = newValue }
    }
    
    func add(_ harmonic: Harmonic) {
        if harmonics.count < maxCapacity {
            harmonics.append(harmonic)
        }
        // If full, logic usually implies we don't add or replace worst?
        // Kotlin implementation likely manages size explicitly.
    }
    
    func clear() {
        harmonics.removeAll(keepingCapacity: true)
    }
    
    func sort() {
        harmonics.sort()
    }
}
