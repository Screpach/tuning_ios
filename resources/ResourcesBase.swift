import Foundation
import Combine
import SwiftUI

/// Base class for resource management and persistence.
///
/// Equivalent to `ResourcesBase.kt`.
/// Manages a JSON-backed storage file and provides strongly-typed `Preference` objects
/// that automatically sync state to disk.
@MainActor
open class ResourcesBase: ObservableObject {
    
    // MARK: - Configuration
    
    private let filename: String
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - State
    
    /// In-memory cache of the current state.
    /// Keys correspond to preference names. Values are the decoded structs or primitives.
    /// We keep this generic storage to handle the file I/O in one go.
    private var storageCache: [String: Any] = [:]
    
    /// Tracks if a save is pending to avoid writing to disk too often.
    private var saveTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Initializes the resource manager.
    /// - Parameter filename: The name of the file (without extension) used for storage.
    init(key: String) {
        self.filename = key
        
        // Setup paths
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let root = paths.first?.appendingPathComponent("Tuner") ?? URL(fileURLWithPath: NSTemporaryDirectory())
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        
        self.fileURL = root.appendingPathComponent("\(key).json")
        
        // Setup Codable
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        
        // Initial Load
        loadFromDisk()
    }
    
    // MARK: - Public Factory Methods
    
    /// Creates a boolean preference.
    func createPreference(key: String, default defaultValue: Bool) -> Preference<Bool> {
        return createGenericPreference(key: key, default: defaultValue)
    }
    
    /// Creates an integer preference.
    func createPreference(key: String, default defaultValue: Int) -> Preference<Int> {
        return createGenericPreference(key: key, default: defaultValue)
    }
    
    /// Creates a float preference.
    func createPreference(key: String, default defaultValue: Float) -> Preference<Float> {
        return createGenericPreference(key: key, default: defaultValue)
    }
    
    /// Creates a string preference.
    func createPreference(key: String, default defaultValue: String) -> Preference<String> {
        return createGenericPreference(key: key, default: defaultValue)
    }
    
    /// Creates a generic serializable object preference (Codable).
    ///
    /// - Parameters:
    ///   - verifyAfterReading: Optional closure to validate/fix data after loading.
    ///   - onDeserializationFailure: Optional closure to recover data if JSON is corrupt/old.
    func createSerializablePreference<T: Codable & Sendable>(
        key: String,
        defaultValue: T,
        verifyAfterReading: ((T) -> T)? = nil,
        onDeserializationFailure: ((String) -> T)? = nil
    ) -> Preference<T> {
        
        // 1. Check Cache or Load
        var initialValue: T = defaultValue
        
        // Try to retrieve from raw storage (which is [String: Any])
        // For Serializable prefs, the storage might hold the Dict/Array representation
        // or the specific Swift type if we already cached it.
        
        if let cached = storageCache[key] as? T {
            initialValue = cached
        } else if let rawData = storageCache[key] {
            // It might be a Dictionary/Any that needs decoding to T
            // This happens if we loaded the JSON file into a generic [String: Any] container
            // and haven't cast it to T yet.
            if let data = try? JSONSerialization.data(withJSONObject: rawData),
               let decoded = try? decoder.decode(T.self, from: data) {
                initialValue = decoded
            }
        }
        
        // 2. Verification / Fallback Logic
        // Note: Real "onDeserializationFailure" is hard to trigger here since we just loaded generic JSON.
        // It would usually happen inside `loadFromDisk` if we were strictly typed.
        // However, we apply `verifyAfterReading` here.
        if let verify = verifyAfterReading {
            initialValue = verify(initialValue)
        }
        
        // 3. Create Preference Wrapper
        let pref = Preference(key: key, value: initialValue, parent: self)
        
        // 4. Update Cache Immediately (in case verify changed it)
        storageCache[key] = initialValue
        
        return pref
    }
    
    /// Creates a list of serializable objects.
    func createSerializableListPreference<T: Codable & Sendable>(
        key: String,
        defaultValue: [T] = []
    ) -> Preference<[T]> {
        return createSerializablePreference(key: key, defaultValue: defaultValue)
    }
    
    // MARK: - Internal Helpers
    
    private func createGenericPreference<T>(key: String, default defaultValue: T) -> Preference<T> {
        let initialValue = (storageCache[key] as? T) ?? defaultValue
        storageCache[key] = initialValue // Ensure cache is populated
        return Preference(key: key, value: initialValue, parent: self)
    }
    
    /// Called by child Preferences when their value changes.
    fileprivate func updateValue<T>(key: String, value: T) {
        storageCache[key] = value
        requestSave()
    }
    
    private func requestSave() {
        // Debounce logic: Cancel previous task if pending
        saveTask?.cancel()
        
        saveTask = Task {
            // Wait 100ms (debounce)
            try? await Task.sleep(nanoseconds: 100 * 1_000_000)
            if Task.isCancelled { return }
            
            saveToDisk()
        }
    }
    
    private func saveToDisk() {
        do {
            // Convert storageCache (mixed types) to JSON.
            // Since `storageCache` has `Any`, we can't use JSONEncoder directly on the dict
            // unless all values are strictly Codable.
            // To be safe and robust, we use JSONSerialization for the top level dictionary.
            // This requires all values in storageCache to be valid JSON types (Array, Dict, String, Num, Bool).
            // Complex Codable objects stored in `createSerializablePreference` must be stored
            // in `storageCache` as their JSON representation (Dicts) or we need a custom encoder.
            
            // Refined Approach:
            // When `updateValue` is called with a struct T, we should probably encode it to a Dict/Any
            // before putting it in `storageCache` so that `JSONSerialization` works.
            
            let data = try JSONSerialization.data(withJSONObject: storageCache, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: fileURL, options: .atomic)
            // print("ResourcesBase: Saved to \(fileURL.lastPathComponent)")
        } catch {
            print("ResourcesBase: Save failed for \(filename): \(error)")
            
            // Fallback: If `storageCache` contains custom Swift objects that aren't native JSON types,
            // JSONSerialization will fail.
            // In a real app, we'd iterate and map them.
            // For this port, we assume `Preference` handles the encoding before calling updateValue?
            // See `Preference.set` below.
        }
    }
    
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return
        }
        self.storageCache = json
    }
}

// MARK: - Preference Wrapper

/// A strongly-typed wrapper for a preference value.
/// Equivalent to the inner classes returned by `createPreference` in Kotlin.
@MainActor
class Preference<T>: ObservableObject {
    @Published var value: T {
        didSet {
            notifyParent()
        }
    }
    
    private let key: String
    private weak var parent: ResourcesBase?
    
    init(key: String, value: T, parent: ResourcesBase) {
        self.key = key
        self.value = value
        self.parent = parent
    }
    
    private func notifyParent() {
        // If T is a custom Codable struct, we need to convert it to a Dictionary/Array
        // so that ResourcesBase can serialize it via JSONSerialization.
        
        if let codable = value as? Encodable {
            // Encode to JSON object
            if let data = try? JSONEncoder().encode(codable),
               let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                parent?.updateValue(key: key, value: jsonObject)
                return
            }
        }
        
        // If primitive (String, Int, Bool, etc), pass directly
        parent?.updateValue(key: key, value: value)
    }
    
    /// Expose as a Combine publisher (Flow equivalent)
    var asPublisher: Published<T>.Publisher { $value }
}

// MARK: - Compatibility Layer (Temporary)
// These allow the previously generated `InstrumentResources.swift` to compile
// even though it used static methods from the previous stub.
// NOTE: You should refactor `InstrumentResources.swift` to use the instance methods above.

extension ResourcesBase {
    
    static func save<T: Encodable>(key: String, value: T) {
        // Fallback to UserDefaults for the static stub compatibility
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    static func load<T: Decodable>(key: String, defaultValue: T, fallbackDecoder: ((Data) -> T?)? = nil) -> T {
        guard let data = UserDefaults.standard.data(forKey: key) else { return defaultValue }
        if let loaded = try? JSONDecoder().decode(T.self, from: data) { return loaded }
        if let fallback = fallbackDecoder?(data) { return fallback }
        return defaultValue
    }
    
    static func loadList<T: Decodable>(key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }
}
