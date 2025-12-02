import Foundation

// MARK: - Enums

enum BaseNote: String, Codable, CaseIterable, Sendable {
    case C, D, E, F, G, A, B, None
}

/// Modifiers for base notes.
/// Ordering implies sharpness level (flattest to sharpest) for printing purposes.
enum NoteModifier: String, Codable, CaseIterable, Sendable {
    // Flattened
    case FlatFlatFlatDownDownDown, FlatFlatFlatDownDown, FlatFlatFlatDown
    case FlatFlatFlat, FlatFlatFlatUp, FlatFlatFlatUpUp
    case FlatFlatDownDownDown, FlatFlatDownDown, FlatFlatDown
    case FlatFlat, FlatFlatUp, FlatFlatUpUp
    case FlatDownDownDown, FlatDownDown, FlatDown
    case Flat, FlatUp, FlatUpUp
    
    // Natural
    case NaturalDownDownDown, NaturalDownDown, NaturalDown
    case None // Natural / None
    case NaturalUp, NaturalUpUp, NaturalUpUpUp
    
    // Sharp
    case SharpDownDownDown, SharpDownDown, SharpDown
    case Sharp, SharpUp, SharpUpUp
    case SharpSharpDownDownDown, SharpSharpDownDown, SharpSharpDown
    case SharpSharp, SharpSharpUp, SharpSharpUpUp
    case SharpSharpSharpDownDownDown, SharpSharpSharpDownDown, SharpSharpSharpDown
    case SharpSharpSharp, SharpSharpSharpUp, SharpSharpSharpUpUp, SharpSharpSharpUpUpUp
    
    /// Converts the modifier to a rough integer sharpness value.
    /// Used by Chain of Fifths logic.
    /// Simplification: None=0, Sharp=1, Flat=-1, SharpSharp=2, etc.
    /// Up/Down arrows are ignored for basic fifths logic but could be added as fractional steps.
    func toSharpness() -> Int {
        if self.rawValue.contains("FlatFlatFlat") { return -3 }
        if self.rawValue.contains("FlatFlat") { return -2 }
        if self.rawValue.contains("Flat") { return -1 }
        if self.rawValue.contains("SharpSharpSharp") { return 3 }
        if self.rawValue.contains("SharpSharp") { return 2 }
        if self.rawValue.contains("Sharp") { return 1 }
        return 0
    }
}

// MARK: - MusicalNote

/// Represents a specific musical note.
/// Equivalent to `MusicalNote.kt`.
struct MusicalNote: Codable, Hashable, Sendable {
    
    let base: BaseNote
    let modifier: NoteModifier
    let octave: Int
    
    // Extended properties for EDO/Enharmonics
    let octaveOffset: Int
    let enharmonicBase: BaseNote
    let enharmonicModifier: NoteModifier
    let enharmonicOctaveOffset: Int
    
    // MARK: Initialization
    
    init(_ base: BaseNote,
         _ modifier: NoteModifier = .None,
         _ octave: Int = 4,
         octaveOffset: Int = 0,
         enharmonicBase: BaseNote? = nil,
         enharmonicModifier: NoteModifier? = nil,
         enharmonicOctaveOffset: Int = 0) {
        
        self.base = base
        self.modifier = modifier
        self.octave = octave
        self.octaveOffset = octaveOffset
        self.enharmonicBase = enharmonicBase ?? base
        self.enharmonicModifier = enharmonicModifier ?? modifier
        self.enharmonicOctaveOffset = enharmonicOctaveOffset
    }
    
    // Legacy constructor shim for code using positional args
    init(base: BaseNote, modifier: NoteModifier, enharmonicBase: BaseNote, enharmonicModifier: NoteModifier) {
        self.init(base, modifier, 4, octaveOffset: 0, enharmonicBase: enharmonicBase, enharmonicModifier: enharmonicModifier, enharmonicOctaveOffset: 0)
    }
    
    // MARK: - Logic
    
    /// Creates a copy with a new octave.
    func copy(octave: Int) -> MusicalNote {
        return MusicalNote(
            base, modifier, octave,
            octaveOffset: octaveOffset,
            enharmonicBase: enharmonicBase,
            enharmonicModifier: enharmonicModifier,
            enharmonicOctaveOffset: enharmonicOctaveOffset
        )
    }
    
    func switchEnharmonic() -> MusicalNote {
        // Swap base/modifier with enharmonicBase/enharmonicModifier
        // And adjust octave based on offsets
        let newOctave = octave + enharmonicOctaveOffset - octaveOffset
        
        return MusicalNote(
            enharmonicBase,
            enharmonicModifier,
            newOctave,
            octaveOffset: enharmonicOctaveOffset,
            enharmonicBase: base,
            enharmonicModifier: modifier,
            enharmonicOctaveOffset: octaveOffset
        )
    }
    
    func equalsIgnoreOctave(_ other: MusicalNote) -> Bool {
        // Compare main note
        if base == other.base && modifier == other.modifier { return true }
        // Compare with own enharmonic
        if enharmonicBase == other.base && enharmonicModifier == other.modifier { return true }
        // Compare own base with other enharmonic
        if base == other.enharmonicBase && modifier == other.enharmonicModifier { return true }
        return false
    }
    
    func match(_ other: MusicalNote, ignoreOctave: Bool) -> Bool {
        if ignoreOctave {
            return equalsIgnoreOctave(other)
        } else {
            return self == other
        }
    }
    
    // MARK: - Parsing
    
    static func fromString(_ string: String) -> MusicalNote? {
        // 1. Try Key-Value format (verbose)
        if string.contains("base=") {
            var base = BaseNote.None
            var modifier = NoteModifier.None
            var octave = 4
            var octaveOffset = 0
            var enharmonicBase = BaseNote.None
            var enharmonicModifier = NoteModifier.None
            var enharmonicOctaveOffset = 0
            
            let parts = string.split(separator: " ")
            for part in parts {
                let kv = part.split(separator: "=")
                guard kv.count == 2 else { continue }
                let key = String(kv[0])
                let value = String(kv[1])
                
                switch key {
                case "base": base = BaseNote(rawValue: value) ?? .None
                case "modifier": modifier = NoteModifier(rawValue: value) ?? .None
                case "octave": octave = Int(value) ?? 4
                case "octaveOffset": octaveOffset = Int(value) ?? 0
                case "enharmonicBase": enharmonicBase = BaseNote(rawValue: value) ?? .None
                case "enharmonicModifier": enharmonicModifier = NoteModifier(rawValue: value) ?? .None
                case "enharmonicOctaveOffset": enharmonicOctaveOffset = Int(value) ?? 0
                default: break
                }
            }
            
            // If enharmonics weren't parsed, default them to base
            let finalEnhBase = (enharmonicBase == .None) ? base : enharmonicBase
            let finalEnhMod = (enharmonicModifier == .None) ? modifier : enharmonicModifier
            
            return MusicalNote(
                base, modifier, octave,
                octaveOffset: octaveOffset,
                enharmonicBase: finalEnhBase,
                enharmonicModifier: finalEnhMod,
                enharmonicOctaveOffset: enharmonicOctaveOffset
            )
        }
        
        // 2. Try Compact format (A#4) - Fallback for InstrumentIO
        return parseCompact(string)
    }
    
    private static func parseCompact(_ raw: String) -> MusicalNote? {
        guard !raw.isEmpty else { return nil }
        let chars = Array(raw)
        
        let baseStr = String(chars[0])
        guard let base = BaseNote(rawValue: baseStr) else { return nil }
        
        var idx = 1
        var mod = NoteModifier.None
        
        // Check modifier char
        if idx < chars.count {
            if chars[idx] == "#" { mod = .Sharp; idx+=1 }
            else if chars[idx] == "b" { mod = .Flat; idx+=1 }
        }
        
        // Check octave
        var oct = 4
        if idx < chars.count {
            let rest = String(chars[idx...])
            oct = Int(rest) ?? 4
        }
        
        return MusicalNote(base, mod, oct)
    }
}
