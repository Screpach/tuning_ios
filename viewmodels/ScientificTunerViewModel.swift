import Foundation
import Combine

/// ViewModel for the Scientific Tuner screen.
/// Equivalent to `ScientificTunerViewModel.kt`.
@MainActor
class ScientificTunerViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let tuner: Tuner
    private let pref: PreferenceResources
    private let applicationScope: ApplicationScope
    
    // MARK: - State
    // Pitch History (Spectrogram data) would be managed here.
    // For Phase 1, we stub the connection.
    
    // MARK: - Initialization
    
    init(tuner: Tuner, // Injected
         pref: PreferenceResources = DependencyContainerKey.defaultValue.preferences,
         applicationScope: ApplicationScope = DependencyContainerKey.defaultValue.applicationScope) {
        self.tuner = tuner
        self.pref = pref
        self.applicationScope = applicationScope
        
        // Observe preferences to resize history if needed
    }
    
    // MARK: - Control
    
    func startTuner() {
        tuner.start()
    }
    
    func stopTuner() {
        tuner.stop()
    }
    
    // MARK: - Wave Writer
    
    func storeCurrentWaveWriterSnapshot() {
        tuner.storeCurrentWaveWriterSnapshot()
    }
    
    func writeStoredWaveWriterSnapshot(to url: URL, sampleRate: Int) {
        tuner.writeStoredWaveWriterSnapshot(url: url, sampleRate: sampleRate)
    }
}
