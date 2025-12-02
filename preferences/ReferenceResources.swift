import Foundation
import Combine

// MARK: - Supporting Types

struct AppearanceSettings: Codable, Equatable, Sendable {
    var mode: NightMode = .auto
    var blackNightEnabled: Bool = false
    var useSystemColorAccents: Bool = true
}

enum OctaveNotation: Int, Codable, Sendable {
    case scientific = 0
    case helmholtz = 1
}

enum NotePrintOptions: Int, Codable, Sendable {
    case flatSharp = 0 // Standard
    case solfege = 1   // East
    case fixedDo = 2   // Fixed Do
}

// MARK: - Preference Resources

/// Manages application-wide settings.
/// Equivalent to `PreferenceResources` in `ReferenceResources.kt` (likely user typo for PreferenceResources.kt).
@MainActor
class PreferenceResources: ResourcesBase {
    
    // MARK: - Properties
    
    let sampleRate: Int = 44100
    
    // MARK: - Preferences
    
    // 1. Appearance
    // We group appearance settings into a struct to match the Kotlin data class approach roughly,
    // or we can keep them separate. The Kotlin snippet shows a nested `Appearance` data class
    // but likely uses separate underlying keys or a JSON object.
    // Given ResourcesBase logic, let's use a single JSON object for appearance to keep it clean.
    
    private lazy var appearancePref = createSerializablePreference(
        key: "appearance_settings",
        defaultValue: AppearanceSettings()
    )
    @Published var appearance: AppearanceSettings = AppearanceSettings()
    
    // 2. Migrations
    private lazy var migrationsFromV6CompletePref = createPreference(key: "migrations_complete", default: false)
    @Published var migrationsFromV6Complete: Bool = false
    
    // 3. Screen
    private lazy var screenAlwaysOnPref = createPreference(key: "screen_always_on", default: false)
    @Published var screenAlwaysOn: Bool = false
    
    // 4. Notation & Display
    private lazy var octaveNotationPref = createSerializablePreference(
        key: "octave_notation",
        defaultValue: OctaveNotation.scientific
    )
    @Published var octaveNotation: OctaveNotation = .scientific
    
    private lazy var notePrintOptionsPref = createSerializablePreference(
        key: "note_print_options",
        defaultValue: NotePrintOptions.flatSharp
    )
    @Published var notePrintOptions: NotePrintOptions = .flatSharp
    
    // 5. Audio / DSP
    private lazy var windowSizePref = createPreference(key: "window_size", default: 2048)
    @Published var windowSize: Int = 2048
    
    private lazy var pitchHistoryDurationPref = createPreference(key: "pitch_history_duration", default: 3.0)
    @Published var pitchHistoryDuration: Float = 3.0
    
    private lazy var pitchHistoryNumFaultyValuesPref = createPreference(key: "pitch_history_num_faulty_values", default: 10)
    @Published var pitchHistoryNumFaultyValues: Int = 10
    
    private lazy var numMovingAveragePref = createPreference(key: "num_moving_average", default: 5)
    @Published var numMovingAverage: Int = 5
    
    private lazy var sensitivityPref = createPreference(key: "sensitivity", default: 90) // Int 0-100
    @Published var sensitivity: Int = 90
    
    private lazy var toleranceInCentsPref = createPreference(key: "tolerance_in_cents", default: 5)
    @Published var toleranceInCents: Int = 5
    
    private lazy var maxNoisePref = createPreference(key: "max_noise", default: 0.1) // Stored as Float
    @Published var maxNoise: Float = 0.1
    
    private lazy var minHarmonicEnergyContentPref = createPreference(key: "min_harmonic_energy_content", default: 0.1)
    @Published var minHarmonicEnergyContent: Float = 0.1
    
    private lazy var waveWriterDurationInSecondsPref = createPreference(key: "wave_writer_duration_in_seconds", default: 0)
    @Published var waveWriterDurationInSeconds: Int = 0
    
    // MARK: - Initialization
    
    init() {
        super.init(key: "settings")
        
        // Bind Preferences to Published properties
        // This boilerplate ensures SwiftUI views update automatically.
        // In a clearer refactor, ResourcesBase could handle this via dynamic member lookup,
        // but for high-fidelity porting, we map explicit fields.
        
        bind(appearancePref, to: &$appearance)
        bind(migrationsFromV6CompletePref, to: &$migrationsFromV6Complete)
        bind(screenAlwaysOnPref, to: &$screenAlwaysOn)
        bind(octaveNotationPref, to: &$octaveNotation)
        bind(notePrintOptionsPref, to: &$notePrintOptions)
        bind(windowSizePref, to: &$windowSize)
        bind(pitchHistoryDurationPref, to: &$pitchHistoryDuration)
        bind(pitchHistoryNumFaultyValuesPref, to: &$pitchHistoryNumFaultyValues)
        bind(numMovingAveragePref, to: &$numMovingAverage)
        bind(sensitivityPref, to: &$sensitivity)
        bind(toleranceInCentsPref, to: &$toleranceInCents)
        bind(maxNoisePref, to: &$maxNoise)
        bind(minHarmonicEnergyContentPref, to: &$minHarmonicEnergyContent)
        bind(waveWriterDurationInSecondsPref, to: &$waveWriterDurationInSeconds)
    }
    
    // MARK: - Writers (Setters)
    
    // Appearance
    func writeAppearance(_ mode: NightMode) {
        var current = appearance
        current.mode = mode
        appearancePref.value = current
    }
    
    func writeUseSystemColorAccents(_ value: Bool) {
        var current = appearance
        current.useSystemColorAccents = value
        appearancePref.value = current
    }
    
    func writeBlackNightEnabled(_ value: Bool) {
        var current = appearance
        current.blackNightEnabled = value
        appearancePref.value = current
    }
    
    // Migrations
    func writeMigrationsFromV6Complete() {
        migrationsFromV6CompletePref.value = true
    }
    
    // General
    func writeScreenAlwaysOn(_ value: Bool) { screenAlwaysOnPref.value = value }
    func writeOctaveNotation(_ value: OctaveNotation) { octaveNotationPref.value = value }
    func writeNotePrintOptions(_ value: NotePrintOptions) { notePrintOptionsPref.value = value }
    func writeWindowSize(_ value: Int) { windowSizePref.value = value }
    func writePitchHistoryDuration(_ value: Float) { pitchHistoryDurationPref.value = value }
    func writePitchHistoryNumFaultyValues(_ value: Int) { pitchHistoryNumFaultyValuesPref.value = value }
    func writeNumMovingAverage(_ value: Int) { numMovingAveragePref.value = value }
    
    // Sensitivity (Int vs Float handling)
    func writeSensitivity(_ value: Int) { sensitivityPref.value = value }
    
    /// Overload for Migration compatibility (converts legacy float to int percent)
    func writeSensitivity(_ value: Float) {
        // Assuming legacy was 0.0-1.0 or raw float?
        // Kotlin snippet default is 90.
        // If legacy was small float (0.9), map to 90. If large (90.0), keep 90.
        let intVal: Int
        if value <= 1.0 {
            intVal = Int(value * 100)
        } else {
            intVal = Int(value)
        }
        sensitivityPref.value = intVal
    }
    
    // Tolerance
    func writeToleranceInCents(_ value: Int) { toleranceInCentsPref.value = value }
    func writeToleranceInCents(_ value: Float) { toleranceInCentsPref.value = Int(value) }
    
    // Wave Writer
    func writeWaveWriterDurationInSeconds(_ value: Int) { waveWriterDurationInSecondsPref.value = value }
    func writeWaveWriterDurationInSeconds(_ value: Float) { waveWriterDurationInSecondsPref.value = Int(value) }

    // Helpers
    private func bind<T>(_ pref: Preference<T>, to property: inout T) {
        property = pref.value // Initial sync
        pref.asPublisher.assign(to: &$_appearance) // This is pseudo-code for binding logic
        // Real implementation:
        pref.asPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.value, on: extractPublishedBinding(for: pref))
            .store(in: &cancellables)
    }
    
    // Simplified binding helper for Phase 1 to avoid complex keypath reflection logic
    private var cancellables = Set<AnyCancellable>()
    
    private func bind<T>(_ pref: Preference<T>, to property: inout T) {
        // Set initial
        property = pref.value
    }
    
    // We override init to setup subscriptions manually for the @Published properties
    // because `bind` with inout doesn't capture the property wrapper pointer easily.
    
    private func setupBindings() {
        appearancePref.asPublisher.assign(to: &$appearance)
        migrationsFromV6CompletePref.asPublisher.assign(to: &$migrationsFromV6Complete)
        screenAlwaysOnPref.asPublisher.assign(to: &$screenAlwaysOn)
        octaveNotationPref.asPublisher.assign(to: &$octaveNotation)
        notePrintOptionsPref.asPublisher.assign(to: &$notePrintOptions)
        windowSizePref.asPublisher.assign(to: &$windowSize)
        pitchHistoryDurationPref.asPublisher.assign(to: &$pitchHistoryDuration)
        pitchHistoryNumFaultyValuesPref.asPublisher.assign(to: &$pitchHistoryNumFaultyValues)
        numMovingAveragePref.asPublisher.assign(to: &$numMovingAverage)
        sensitivityPref.asPublisher.assign(to: &$sensitivity)
        toleranceInCentsPref.asPublisher.assign(to: &$toleranceInCents)
        maxNoisePref.asPublisher.assign(to: &$maxNoise)
        minHarmonicEnergyContentPref.asPublisher.assign(to: &$minHarmonicEnergyContent)
        waveWriterDurationInSecondsPref.asPublisher.assign(to: &$waveWriterDurationInSeconds)
    }
    
    // Re-doing init to call setupBindings
    override init() {
        super.init(key: "settings")
        setupBindings()
    }
}
