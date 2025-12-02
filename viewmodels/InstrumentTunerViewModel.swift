import Foundation
import Combine

/// ViewModel for the Instrument Tuner screen.
/// Equivalent to `InstrumentTunerViewModel.kt`.
/// Manages target note detection, needle damping, and deviation calculation.
@MainActor
class InstrumentTunerViewModel: ObservableObject, TunerDelegate {
    
    // MARK: - Dependencies
    private let tuner: Tuner
    private let pref: PreferenceResources
    private let instruments: InstrumentResources
    
    // MARK: - State
    @Published var currentInstrument: Instrument
    @Published var tuningState: TuningState = .unknown
    
    // Smoothed Frequency for UI
    @Published var currentFrequency: Float = 0.0
    
    // Target Note (Auto or Manual)
    @Published var targetNote: MusicalNote?
    @Published var isAutoDetect: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(tuner: Tuner,
         pref: PreferenceResources = DependencyContainerKey.defaultValue.preferences,
         instruments: InstrumentResources = DependencyContainerKey.defaultValue.instruments) {
        self.tuner = tuner
        self.pref = pref
        self.instruments = instruments
        self.currentInstrument = instruments.currentInstrument
        
        // Bind instrument changes
        instruments.$currentInstrument
            .assign(to: \.currentInstrument, on: self)
            .store(in: &cancellables)
        
        // Set self as delegate to receive updates
        self.tuner.delegate = self
    }
    
    // MARK: - TunerDelegate
    
    func onFrequencyEvaluated(_ result: FrequencyEvaluationResult) {
        // Logic to update tuning state, target note, and smoothed frequency
        // ported from `resetTuningState` and flow collectors in Kotlin
        
        // Mock update for Phase 1
        self.currentFrequency = result.frequency
        if isAutoDetect {
            self.targetNote = result.note
        }
    }
    
    // MARK: - Control
    
    func startTuner() {
        tuner.start()
    }
    
    func stopTuner() {
        tuner.stop()
    }
    
    func setTargetNote(_ note: MusicalNote?) {
        // User manually selected a note
        self.targetNote = note
        self.isAutoDetect = (note == nil)
        tuner.userDefinedTargetNote.send(note)
    }
}

// MARK: - Stubs

enum TuningState: Sendable {
    case unknown
    case tuning(deviation: Float)
}
