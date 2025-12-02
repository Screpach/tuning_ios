import Foundation
import Combine

/// ViewModel for the Instrument Editor.
/// Equivalent to `InstrumentEditorViewModel.kt`.
@MainActor
class InstrumentEditorViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let pref: PreferenceResources
    private let musicalScale: MusicalScale2
    // Note: Kotlin uses `instrumentChromatic` flow. We can mock or use a chromatic scale/instrument.
    
    // MARK: - State
    
    @Published var name: String
    @Published var icon: InstrumentIcon
    @Published var strings: [MusicalNote]
    @Published var isChromatic: Bool
    
    private let originalId: Int64
    
    // Tuner for detecting notes when setting up strings
    private var tuner: Tuner?
    
    // MARK: - Initialization
    
    init(instrument: Instrument,
         pref: PreferenceResources = DependencyContainerKey.defaultValue.preferences,
         musicalScale: MusicalScale2 = MusicalScale2.createTestEdo12()) { // Mock scale for now
        
        self.pref = pref
        self.musicalScale = musicalScale
        
        self.name = instrument.name
        self.icon = instrument.icon
        self.strings = instrument.strings
        self.isChromatic = instrument.isChromatic
        self.originalId = instrument.stableId
        
        setupTuner()
    }
    
    // MARK: - Tuner Logic
    
    private func setupTuner() {
        // In Kotlin, this creates a Tuner instance that feeds into `noteDetectorState`.
        // For Phase 1, we stub the connection.
        // self.tuner = Tuner(...)
    }
    
    func startTuner() {
        tuner?.start()
    }
    
    func stopTuner() {
        tuner?.stop()
    }
    
    // MARK: - Result
    
    func getInstrument() -> Instrument {
        return Instrument(
            name: name,
            nameResource: nil,
            strings: strings,
            icon: icon,
            stableId: originalId,
            isChromatic: isChromatic
        )
    }
    
    // Actions
    func setIcon(_ icon: InstrumentIcon) {
        self.icon = icon
    }
    
    func setName(_ name: String) {
        self.name = name
    }
}
