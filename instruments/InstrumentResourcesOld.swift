import Foundation

/// Accessor for legacy instrument settings.
///
/// Equivalent to `InstrumentResourcesOld.kt`.
/// This class handles reading data from the old storage format (SharedPreferences in Android),
/// typically used for migration or backward compatibility.
class InstrumentResourcesOld {
    
    // MARK: - Constants / Keys
    
    private static let CUSTOM_SECTION_EXPANDED_KEY = "custom_section_expanded"
    private static let PREDEFINED_SECTION_EXPANDED_KEY = "predefined_section_expanded"
    
    private static let CURRENT_INSTRUMENT_ID_KEY = "instrument_id"
    private static let SECTION_OF_CURRENT_INSTRUMENT_KEY = "instrument_section"
    
    private static let CUSTOM_INSTRUMENTS_KEY = "custom_instruments"
    
    // MARK: - Dependencies
    
    /// The immutable list of built-in instruments (Global reference).
    private let predefinedInstruments: [Instrument] = instrumentDatabase
    
    // MARK: - Properties
    
    /// Returns the expanded state of the predefined section, or nil if not set.
    var predefinedInstrumentsExpanded: Bool? {
        getBoolean(Self.PREDEFINED_SECTION_EXPANDED_KEY)
    }
    
    /// Returns the expanded state of the custom section, or nil if not set.
    var customInstrumentsExpanded: Bool? {
        getBoolean(Self.CUSTOM_SECTION_EXPANDED_KEY)
    }
    
    /// Parses and returns the legacy custom instruments list.
    var customInstruments: [Instrument]? {
        guard let rawString = getString(Self.CUSTOM_INSTRUMENTS_KEY) else {
            return nil
        }
        // Uses the InstrumentIO parser we ported earlier
        return InstrumentIO.readFromContent(rawString)
    }
    
    /// Resolves the legacy current instrument by ID.
    var currentInstrument: Instrument? {
        guard let key = getLong(Self.CURRENT_INSTRUMENT_ID_KEY) else {
            return nil
        }
        
        // 1. Try to find in custom instruments (if any exist)
        if let customList = customInstruments,
           let match = customList.first(where: { $0.stableId == key }) {
            return match
        }
        
        // 2. Fallback to predefined instruments
        return predefinedInstruments.first(where: { $0.stableId == key })
    }
    
    // MARK: - Private Helpers
    
    /// Helper to mimic SharedPreferences behavior (distinguishing nil vs false/0).
    private func getBoolean(_ key: String) -> Bool? {
        // UserDefaults.object(forKey:) returns nil if key doesn't exist.
        // UserDefaults.bool(forKey:) returns false if key doesn't exist.
        // We need to know if it actually exists.
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.bool(forKey: key)
        }
        return nil
    }
    
    private func getLong(_ key: String) -> Int64? {
        if let val = UserDefaults.standard.object(forKey: key) as? NSNumber {
            return val.int64Value
        }
        return nil
    }
    
    private func getString(_ key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
}
