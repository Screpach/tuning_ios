import Foundation
import Combine

/// ViewModel for the Reference Note Dialog.
/// Equivalent to `ReferenceNoteDialogViewModel.kt`.
@MainActor
class ReferenceNoteDialogViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let pref: PreferenceResources
    private let applicationScope: ApplicationScope
    
    // MARK: - State
    @Published var detectedFrequency: Float = 0.0
    
    private var frequencyDetector: SimpleFrequencyDetector?
    
    // MARK: - Initialization
    
    init(pref: PreferenceResources = DependencyContainerKey.defaultValue.preferences,
         applicationScope: ApplicationScope = DependencyContainerKey.defaultValue.applicationScope) {
        self.pref = pref
        self.applicationScope = applicationScope
        
        // Setup Detector
        // Note: SimpleFrequencyDetector requires a config snapshot.
        // In a real app we might need to observe pref changes, but for a dialog this is usually static.
        let config = SimpleDetectorPreferences(
            numMovingAverage: pref.numMovingAverage,
            pitchHistoryNumFaultyValues: pref.pitchHistoryNumFaultyValues,
            maxNoise: pref.maxNoise,
            minHarmonicEnergyContent: pref.minHarmonicEnergyContent,
            sensitivity: Float(pref.sensitivity),
            windowType: "Hann" // Default or from pref
        )
        
        self.frequencyDetector = SimpleFrequencyDetector(preferences: config) { [weak self] frequency in
            if frequency > 0 {
                self?.detectedFrequency = frequency
            }
        }
    }
    
    // MARK: - Actions
    
    func startFrequencyDetection() {
        frequencyDetector?.connect()
    }
    
    func stopFrequencyDetection() {
        frequencyDetector?.disconnect()
    }
}
