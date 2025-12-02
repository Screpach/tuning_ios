import Foundation

/// Helper to define temperaments via circle of fifths.
/// Equivalent to `TemperamentCircleOfFifths.kt`.
struct TemperamentCircleOfFifths {
    let CG: FifthModification
    let GD: FifthModification
    let DA: FifthModification
    let AE: FifthModification
    let EB: FifthModification
    let BFsharp: FifthModification
    let FsharpCsharp: FifthModification
    let CsharpGsharp: FifthModification
    let GsharpEflat: FifthModification
    let EFlatBflat: FifthModification
    let BflatF: FifthModification
    let FC: FifthModification
    
    func toFifthsArray() -> [FifthModification] {
        return [CG, GD, DA, AE, EB, BFsharp, FsharpCsharp, CsharpGsharp, GsharpEflat, EFlatBflat, BflatF, FC]
    }
}

// MARK: - Predefined Circles

let circleOfFifthsPythagorean = TemperamentCircleOfFifths(
    CG: FifthModification(), GD: FifthModification(), DA: FifthModification(),
    AE: FifthModification(), EB: FifthModification(), BFsharp: FifthModification(),
    FsharpCsharp: FifthModification(), CsharpGsharp: FifthModification(),
    GsharpEflat: FifthModification(), EFlatBflat: FifthModification(),
    BflatF: FifthModification(), FC: FifthModification()
)

// Quarter-comma meantone (perfect major thirds)
let circleOfFifthsQuarterCommaMeanTone = TemperamentCircleOfFifths(
    CG: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    GD: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    DA: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    AE: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    EB: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    BFsharp: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    FsharpCsharp: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    CsharpGsharp: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    GsharpEflat: FifthModification(), // Wolf
    EFlatBflat: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    BflatF: FifthModification(syntonicComma: RationalNumber(-1, 4)),
    FC: FifthModification(syntonicComma: RationalNumber(-1, 4))
)
