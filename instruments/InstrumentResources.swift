import Foundation
import Combine

// MARK: - Instrument Resources

/// Manages the state and persistence of instruments.
///
/// Equivalent to `InstrumentResources.kt`.
@MainActor
class InstrumentResources: ResourcesBase {
    
    // MARK: - Properties
    
    /// The immutable list of built-in instruments.
    let predefinedInstruments: [Instrument]
    
    /// The currently active instrument.
    /// Maps to `currentInstrument` StateFlow in Kotlin.
    @Published var currentInstrument: Instrument
    
    /// List of user-created custom instruments.
    /// Maps to `customInstruments` StateFlow in Kotlin.
    @Published var customInstruments: [Instrument]
    
    // MARK: - Initialization
    
    init() {
        // 1. Load Predefined
        self.predefinedInstruments = instrumentDatabase
        
        // 2. Initialize Current Instrument (with Persistence & Migration)
        let defaultInstrument = instrumentDatabase[0]
        
        // We manually implement the logic from 'createSerializablePreference' here
        // for the "current instrument" key.
        let savedCurrent = ResourcesBase.load(
            key: "current instrument",
            defaultValue: defaultInstrument,
            fallbackDecoder: { data in
                // onDeserializationFailure logic: Try decoding InstrumentOld
                if let old = try? JSONDecoder().decode(InstrumentOld.self, from: data) {
                    return old.toNew()
                }
                return nil
            }
        )
        
        // verifyAfterReading logic:
        self.currentInstrument = InstrumentResources.reloadPredefinedInstrumentIfNeeded(
            instrument: savedCurrent,
            predefinedInstruments: instrumentDatabase
        ) ?? defaultInstrument
        
        // 3. Initialize Custom Instruments
        // Maps to 'createSerializableListPreference("custom_instruments")'
        self.customInstruments = ResourcesBase.loadList(key: "custom_instruments")
        
        super.init(key: "instruments") // Mocking super init
    }
    
    // MARK: - Public API
    
    /// Sets the current instrument and persists it.
    func setInstrument(_ instrument: Instrument) {
        // Avoid redundant updates
        guard instrument.id != currentInstrument.id else { return }
        
        // In Kotlin: persistence is handled by the Flow collector in ResourcesBase.
        // In Swift Phase 1: We manually save on set.
        currentInstrument = instrument
        saveCurrentInstrument()
    }
    
    /// Adds a new custom instrument.
    func add(_ instrument: Instrument) {
        // Generate a new unique ID
        let newId = getNewStableId()
        let newInstrument = Instrument(
            name: instrument.name,
            nameResource: instrument.nameResource,
            strings: instrument.strings,
            icon: instrument.icon,
            stableId: newId,
            isChromatic: instrument.isChromatic
        )
        
        customInstruments.append(newInstrument)
        saveCustomInstruments()
        
        // Select the newly created instrument
        setInstrument(newInstrument)
    }
    
    /// Deletes a custom instrument.
    func remove(instrumentId: Int64) {
        guard let index = customInstruments.firstIndex(where: { $0.stableId == instrumentId }) else { return }
        customInstruments.remove(at: index)
        saveCustomInstruments()
        
        // If we deleted the current instrument, fallback to default
        if currentInstrument.stableId == instrumentId {
            setInstrument(predefinedInstruments[0])
        }
    }
    
    /// Updates an existing custom instrument.
    func update(id: Int64, name: String, icon: InstrumentIcon, strings: [MusicalNote], isChromatic: Bool) {
        guard let index = customInstruments.firstIndex(where: { $0.stableId == id }) else { return }
        
        let updated = Instrument(
            name: name,
            nameResource: nil, // Custom instruments don't have resources
            strings: strings,
            icon: icon,
            stableId: id,
            isChromatic: isChromatic
        )
        
        customInstruments[index] = updated
        saveCustomInstruments()
        
        // If this was the current instrument, update the selection too
        if currentInstrument.stableId == id {
            setInstrument(updated)
        }
    }
    
    /// Appends a list of instruments (e.g., from import).
    func appendInstruments(_ instruments: [Instrument]) {
        var modifiedList = customInstruments
        
        for instr in instruments {
            let newId = getNewStableId(existingInstruments: modifiedList)
            let newInstr = Instrument(
                name: instr.name,
                nameResource: instr.nameResource,
                strings: instr.strings,
                icon: instr.icon,
                stableId: newId,
                isChromatic: instr.isChromatic
            )
            modifiedList.append(newInstr)
        }
        
        customInstruments = modifiedList
        saveCustomInstruments()
    }
    
    // MARK: - Private Helpers
    
    private func saveCurrentInstrument() {
        ResourcesBase.save(key: "current instrument", value: currentInstrument)
    }
    
    private func saveCustomInstruments() {
        ResourcesBase.save(key: "custom_instruments", value: customInstruments)
    }
    
    private func getNewStableId(existingInstruments: [Instrument]? = nil) -> Int64 {
        let listToCheck = existingInstruments ?? customInstruments
        let currentId = currentInstrument.stableId
        
        while true {
            // Random ID between 0 and Max
            let stableId = Int64.random(in: 0..<Int64.max - 1)
            
            // Ensure uniqueness
            let conflictInCustom = listToCheck.contains(where: { $0.stableId == stableId })
            let conflictInCurrent = (currentId == stableId)
            
            if !conflictInCustom && !conflictInCurrent {
                return stableId
            }
        }
    }
    
    // Logic from the standalone function `reloadPredefinedInstrumentIfNeeded` in Kotlin
    private static func reloadPredefinedInstrumentIfNeeded(
        instrument: Instrument?,
        predefinedInstruments: [Instrument]
    ) -> Instrument? {
        guard let instrument = instrument else { return nil }
        
        // In Swift port of Instrument, getNameString() resolves the localized string.
        // However, checking strictly by content is safer for predefined mapping.
        
        let name = instrument.getNameString()
        if name.isEmpty {
            return instrument
        } else {
            // Attempt to find a predefined instrument with the same name
            // Note: In a real app, stable IDs for predefined instruments should be constant constants,
            // but the Android code relies on name matching for this reload logic.
            return predefinedInstruments.first { predefined in
                predefined.getNameString() == name
            } ?? instrument
        }
    }
}

// MARK: - ResourcesBase Stub
// Since `ResourcesBase.kt` is not yet ported, we provide a functional base implementation
// to handle the persistence logic required by InstrumentResources.

class ResourcesBase: ObservableObject {
    let storageKey: String
    
    init(key: String) {
        self.storageKey = key
    }
    
    // Helper to save Codable objects to UserDefaults
    static func save<T: Encodable>(key: String, value: T) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // Helper to load Codable objects with fallback logic
    static func load<T: Decodable>(
        key: String,
        defaultValue: T,
        fallbackDecoder: ((Data) -> T?)? = nil
    ) -> T {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return defaultValue
        }
        
        // 1. Try standard decode
        if let loaded = try? JSONDecoder().decode(T.self, from: data) {
            return loaded
        }
        
        // 2. Try fallback (e.g. migration from Old format)
        if let fallbackDecoder = fallbackDecoder, let migrated = fallbackDecoder(data) {
            // If migration worked, save it back immediately to fix the file format
            save(key: key, value: migrated)
            return migrated
        }
        
        return defaultValue
    }
    
    static func loadList<T: Decodable>(key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }
}
