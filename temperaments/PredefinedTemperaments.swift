import Foundation

/// Generates list of built-in temperaments.
/// Equivalent to `PredefinedTemperaments.kt`.
func predefinedTemperaments() -> [Temperament3] {
    var list = [Temperament3]()
    
    // Helper to generate IDs
    func nextId() -> Int64 { Int64(-list.count - 1) }
    
    // 1. 12-EDO
    list.append(predefinedTemperamentEDO(12, nextId()))
    
    // 2. Pythagorean
    list.append(predefinedTemperamentPythagorean(nextId()))
    
    // 3. Pure (Just)
    list.append(predefinedTemperamentPure(nextId()))
    
    // 4. Mean-Tone (1/4 Comma)
    list.append(predefinedTemperamentQuarterCommaMeanTone(nextId()))
    
    // ... Add other standard temperaments based on source ...
    
    return list
}

// MARK: - Factory Functions

func predefinedTemperamentEDO(_ n: Int, _ id: Int64) -> Temperament3EDO {
    return Temperament3EDO(stableId: id, notesPerOctave: n)
}

func predefinedTemperamentPythagorean(_ id: Int64) -> Temperament3ChainOfFifthsNoEnharmonics {
    // Pythagorean: All pure fifths (no modification)
    let fifths = [FifthModification](repeating: FifthModification(), count: 11)
    
    return Temperament3ChainOfFifthsNoEnharmonics(
        name: GetTextFromResId(resourceKey: "pythagorean"),
        abbreviation: GetTextFromResId(resourceKey: "pythagorean_abbr"),
        description: GetTextFromResId(resourceKey: "pythagorean_desc"),
        stableId: id,
        fifths: fifths,
        rootIndex: 3, // F C G D A E B F# C# G# D# A# -> Start at D? Need to check source indices
        uniqueIdentifier: "pythagorean"
    )
}

func predefinedTemperamentPure(_ id: Int64) -> Temperament3ChainOfFifthsEDONames {
    // Pure Major: Uses syntonic comma corrections
    // F-C (pure), C-G (pure), G-D (pure), D-A (pure - 1 syntonic)
    // This requires exact copy of the table from Kotlin.
    // For Phase 1, creating a mock structure.
    let fifths = [FifthModification](repeating: FifthModification(), count: 11)
    
    return Temperament3ChainOfFifthsEDONames(
        name: GetTextFromResId(resourceKey: "pure"),
        abbreviation: GetTextFromResId(resourceKey: "pure_abbr"),
        description: GetTextFromString(string: ""),
        stableId: id,
        fifths: fifths,
        rootIndex: 0,
        uniqueIdentifier: "pure"
    )
}

func predefinedTemperamentQuarterCommaMeanTone(_ id: Int64) -> Temperament3ChainOfFifthsEDONames {
    // 1/4 Syntonic Comma Mean Tone
    let mod = FifthModification(syntonicComma: RationalNumber(-1, 4))
    let fifths = [FifthModification](repeating: mod, count: 11) // Usually 11 fifths tempered, 1 wolf
    
    return Temperament3ChainOfFifthsEDONames(
        name: GetTextFromResId(resourceKey: "quarter_comma_mean_tone"),
        abbreviation: GetTextFromResId(resourceKey: "quarter_comma_mean_tone_abbr"),
        description: GetTextFromString(string: ""),
        stableId: id,
        fifths: fifths,
        rootIndex: 0,
        uniqueIdentifier: "quarter_comma"
    )
}
