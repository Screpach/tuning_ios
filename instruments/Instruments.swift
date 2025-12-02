import SwiftUI

// MARK: - Stubs (Dependencies not yet ported)
// These allow this file to compile independently.
// They will be replaced by the actual files in future steps.

enum InstrumentIcon: String, Codable, Hashable {
    case piano, guitar, bass, ukulele, violin, cello, double_bass
}

enum BaseNote: String, Codable {
    case C, D, E, F, G, A, B
}

enum NoteModifier: String, Codable {
    case none, sharp, flat
}

struct MusicalNote: Codable, Hashable, Equatable {
    let base: BaseNote
    let modifier: NoteModifier
    let octave: Int
    
    init(_ base: BaseNote, _ modifier: NoteModifier = .none, _ octave: Int) {
        self.base = base
        self.modifier = modifier
        self.octave = octave
    }
    
    // Mocking the print logic referenced in the original file
    func asAnnotatedString(options: NotePrintOptions2) -> AttributedString {
        // Simple mock implementation
        var str = AttributedString("\(base.rawValue)\(modifier == .sharp ? "#" : "")\(octave)")
        // logic to apply fonts/superscripts would go here
        return str
    }
}

struct NotePrintOptions2: Hashable {}

// MARK: - Instrument Model

/// Represents a musical instrument.
///
/// Equivalent to `de.moekadu.tuner.instruments.Instrument`.
struct Instrument: Identifiable, Hashable, Codable, Sendable {
    
    // MARK: Properties
    
    let name: String
    /// Resource ID reference. In Swift, we use the String key for LocalizedStringResource.
    let nameResource: String?
    let strings: [MusicalNote]
    let icon: InstrumentIcon
    let stableId: Int64
    let isChromatic: BooleanLiteralType
    
    // Conformance to Identifiable
    var id: Int64 { stableId }
    
    // MARK: Constants
    
    static let NO_STABLE_ID: Int64 = Int64.max
    
    // MARK: Initialization
    
    init(name: String,
         nameResource: String?,
         strings: [MusicalNote],
         icon: InstrumentIcon,
         stableId: Int64,
         isChromatic: Bool = false) {
        self.name = name
        self.nameResource = nameResource
        self.strings = strings
        self.icon = icon
        self.stableId = stableId
        self.isChromatic = isChromatic
    }
    
    // MARK: Logic
    
    /// Tell if an instrument is a predefined instrument.
    func isPredefined() -> Bool {
        return nameResource != nil
    }
    
    /// Get instrument name as string.
    ///
    /// In iOS, we don't need to pass `Context`. We resolve the localized string directly.
    func getNameString() -> String {
        if let res = nameResource {
            // Attempt to localize using the resource key, fallback to name if missing
            return String(localized: LocalizedStringResource(stringLiteral: res), defaultValue: String.LocalizationValue(name))
        } else {
            return name
        }
    }
    
    /// Get readable representation of all strings (e.g. "A#4 - C5 - G5")
    ///
    /// - Parameters:
    ///   - notePrintOptions: How to print notes.
    ///   - font: (Optional) Font to apply to the attributed string.
    /// - Returns: An `AttributedString` containing the formatted representation.
    func getStringsString(
        notePrintOptions: NotePrintOptions2,
        font: Font? = nil
    ) -> AttributedString {
        if isChromatic {
            var str = AttributedString(String(localized: "chromatic", defaultValue: "Chromatic"))
            if let font = font { str.font = font }
            return str
        } else {
            var result = AttributedString()
            
            if let first = strings.first {
                var attrParams = first.asAnnotatedString(options: notePrintOptions)
                if let font = font { attrParams.font = font }
                result.append(attrParams)
            }
            
            for i in 1..<strings.count {
                var separator = AttributedString(" - ")
                if let font = font { separator.font = font }
                result.append(separator)
                
                var attrParams = strings[i].asAnnotatedString(options: notePrintOptions)
                if let font = font { attrParams.font = font }
                result.append(attrParams)
            }
            
            return result
        }
    }
}

// MARK: - Predefined Database

// Equivalent to `val instrumentChromatic` and `val instrumentDatabase`

let instrumentChromatic = Instrument(
    name: "Chromatic",
    nameResource: "chromatic",
    strings: [],
    icon: .piano,
    stableId: -1, // this should be set by a id generator
    isChromatic: true
)

// Global accessor for the database
let instrumentDatabase: [Instrument] = createInstrumentDatabase()

private func createInstrumentDatabase() -> [Instrument] {
    var instruments = [Instrument]()
    
    // Helper to generate ID based on current size
    func nextId() -> Int64 {
        return -1 - Int64(instruments.count)
    }
    
    // 1. Chromatic
    var chromatic = instrumentChromatic
    // We create a copy with a new ID
    chromatic = Instrument(
        name: chromatic.name,
        nameResource: chromatic.nameResource,
        strings: chromatic.strings,
        icon: chromatic.icon,
        stableId: nextId(),
        isChromatic: chromatic.isChromatic
    )
    instruments.append(chromatic)
    
    // 2. 6-string guitar
    instruments.append(Instrument(
        name: "6-string guitar",
        nameResource: "guitar_eadgbe",
        strings: [
            MusicalNote(.E, .none, 2),
            MusicalNote(.A, .none, 2),
            MusicalNote(.D, .none, 3),
            MusicalNote(.G, .none, 3),
            MusicalNote(.B, .none, 3),
            MusicalNote(.E, .none, 4)
        ],
        icon: .guitar,
        stableId: nextId()
    ))
    
    // 3. 4-string bass
    instruments.append(Instrument(
        name: "4-string bass",
        nameResource: "bass_eadg",
        strings: [
            MusicalNote(.E, .none, 1),
            MusicalNote(.A, .none, 1),
            MusicalNote(.D, .none, 2),
            MusicalNote(.G, .none, 2)
        ],
        icon: .bass,
        stableId: nextId()
    ))
    
    // 4. 5-string bass
    instruments.append(Instrument(
        name: "5-string bass",
        nameResource: "bass_beadg",
        strings: [
            MusicalNote(.B, .none, 0),
            MusicalNote(.E, .none, 1),
            MusicalNote(.A, .none, 1),
            MusicalNote(.D, .none, 2),
            MusicalNote(.G, .none, 2)
        ],
        icon: .bass,
        stableId: nextId()
    ))
    
    // 5. Ukulele
    instruments.append(Instrument(
        name: "Ukulele",
        nameResource: "ukulele_gcea",
        strings: [
            MusicalNote(.G, .none, 4),
            MusicalNote(.C, .none, 4),
            MusicalNote(.E, .none, 4),
            MusicalNote(.A, .none, 4)
        ],
        icon: .ukulele,
        stableId: nextId()
    ))
    
    // 6. Violin
    instruments.append(Instrument(
        name: "Violin",
        nameResource: "violin_gdae",
        strings: [
            MusicalNote(.G, .none, 3),
            MusicalNote(.D, .none, 4),
            MusicalNote(.A, .none, 4),
            MusicalNote(.E, .none, 5)
        ],
        icon: .violin,
        stableId: nextId()
    ))
    
    // 7. Viola
    instruments.append(Instrument(
        name: "Viola",
        nameResource: "viola_cgda",
        strings: [
            MusicalNote(.C, .none, 3),
            MusicalNote(.G, .none, 3),
            MusicalNote(.D, .none, 4),
            MusicalNote(.A, .none, 4)
        ],
        icon: .violin,
        stableId: nextId()
    ))
    
    // 8. Cello
    instruments.append(Instrument(
        name: "Cello",
        nameResource: "cello_cgda",
        strings: [
            MusicalNote(.C, .none, 2),
            MusicalNote(.G, .none, 2),
            MusicalNote(.D, .none, 3),
            MusicalNote(.A, .none, 3)
        ],
        icon: .cello,
        stableId: nextId()
    ))
    
    // 9. Double bass
    instruments.append(Instrument(
        name: "Double bass",
        nameResource: "double_bass_eadg",
        strings: [
            MusicalNote(.E, .none, 1),
            MusicalNote(.A, .none, 1),
            MusicalNote(.D, .none, 2),
            MusicalNote(.G, .none, 2)
        ],
        icon: .double_bass,
        stableId: nextId()
    ))
    
    return instruments
}
