import Foundation

/// A legacy or serialization representation of an Instrument.
///
/// Equivalent to `InstrumentOld.kt`.
/// Used for migrating or decoding instruments that might not have a stable ID match
/// but need to be reconciled against the current database.
struct InstrumentOld: Codable {
    
    // MARK: - Properties
    
    private let name: String?
    /// Legacy Android Resource ID. Unused in iOS logic but kept for decoding compatibility.
    private let nameResource: Int?
    let strings: [MusicalNote]
    let icon: InstrumentIcon
    let stableId: Int64
    let isChromatic: Bool
    
    // MARK: - Initialization
    
    init(name: String?,
         nameResource: Int?,
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
    
    // MARK: - Migration Logic
    
    /// Converts this legacy/data object into a full `Instrument`.
    ///
    /// If `name` is missing, it attempts to find a matching predefined instrument
    /// in the global `instrumentDatabase`.
    func toNew() -> Instrument {
        if name == nil {
            // Attempt to find a matching predefined instrument
            let match = instrumentDatabase.first { candidate in
                // Compare Icon (using rawValue/name)
                // In Swift, comparing the enum case checks equality.
                // Kotlin checked `icon.name == it.icon.name` which is equivalent to direct equality.
                candidate.icon == self.icon &&
                
                // Compare String Count
                candidate.strings.count == self.strings.count &&
                
                // Compare Chromatic Flag
                candidate.isChromatic == self.isChromatic &&
                
                // Compare String Content (Deep Equality)
                // Since MusicalNote is Equatable, simple equality works.
                candidate.strings == self.strings
            }
            
            // Return match or default to the first instrument (usually Chromatic)
            return match ?? instrumentDatabase[0]
            
        } else {
            // It's likely a custom instrument with a specific name.
            return Instrument(
                name: name!, // Force unwrap is safe due to check above
                nameResource: nil, // Android Int ID cannot be used here; custom instruments use the raw name.
                strings: strings,
                icon: icon,
                stableId: stableId,
                isChromatic: isChromatic
            )
        }
    }
}
