import Foundation
import Combine

@MainActor
class TemperamentResources: ResourcesBase {
    
    // MARK: - Properties
    
    let predefinedTemperaments: [Temperament3] = de.moekadu.tuner.temperaments.predefinedTemperaments()
    
    var defaultTemperament: Temperament3 { predefinedTemperaments[0] } // 12-EDO
    
    // State
    @Published var customTemperaments: [Temperament3] = []
    @Published var musicalScale: MusicalScale2
    
    // Expansion State
    @Published var predefinedTemperamentsExpanded: Bool = false
    @Published var customTemperamentsExpanded: Bool = true
    
    // Defaults
    private let defaultRootNote = MusicalNote(.A, .None, 4)
    private let defaultRefNote = MusicalNote(.A, .None, 4)
    private let defaultRefFreq: Float = 440.0
    
    // MARK: - Initialization
    
    init() {
        // 1. Initialize Scale with default (12-EDO)
        let initialTemp = predefinedTemperaments[0]
        self.musicalScale = MusicalScale2(
            temperament: initialTemp,
            rootNote: defaultRootNote,
            referenceNote: defaultRefNote,
            referenceFrequency: defaultRefFreq,
            frequencyMin: DefaultValues.FREQUENCY_MIN,
            frequencyMax: DefaultValues.FREQUENCY_MAX,
            stretchTuning: nil
        )
        
        super.init(key: "temperaments")
        
        // 2. Load Custom Temperaments (Mock load)
        // self.customTemperaments = loadList(...)
        
        // 3. Load Saved Scale Settings (Mock load)
        // If saved, apply. If not, stick to default.
    }
    
    // MARK: - API
    
    func setTemperament(_ temperament: Temperament3) {
        // When changing temperament, we might need to adjust root note if invalid
        var newRoot = musicalScale.rootNote
        let validRoots = temperament.possibleRootNotes()
        
        if let current = newRoot {
            if !validRoots.contains(where: { $0.equalsIgnoreOctave(current) }) {
                newRoot = validRoots.first // Fallback
            }
        }
        
        updateMusicalScale(temperament: temperament, rootNote: newRoot)
    }
    
    func setStretchTuning(_ tuning: StretchTuning?) {
        updateMusicalScale(stretchTuning: tuning)
    }
    
    func removeCustomTemperament(_ t: Temperament) {
        // Remove logic
    }
    
    // MARK: - Internal
    
    private func updateMusicalScale(
        temperament: Temperament3? = nil,
        rootNote: MusicalNote? = nil,
        stretchTuning: StretchTuning? = nil
    ) {
        let current = musicalScale
        self.musicalScale = MusicalScale2(
            temperament: temperament ?? current.temperament,
            rootNote: rootNote ?? current.rootNote,
            referenceNote: current.referenceNote,
            referenceFrequency: current.referenceFrequency,
            frequencyMin: current.frequencyMin,
            frequencyMax: current.frequencyMax,
            stretchTuning: stretchTuning ?? current.stretchTuning
        )
        // Save state
    }
    
    // Writers for UI State
    func writePredefinedTemperamentsExpanded(_ val: Bool) { predefinedTemperamentsExpanded = val }
    func writeCustomTemperamentsExpanded(_ val: Bool) { customTemperamentsExpanded = val }
    
    // Helper for migrations
    func writeMusicalScale(temperament: Temperament?, referenceNote: MusicalNote?, rootNote: MusicalNote?, referenceFrequency: Float?) {
        // Convert legacy temperament
        let newTemp = temperament?.toNew()
        
        self.musicalScale = MusicalScale2(
            temperament: newTemp ?? musicalScale.temperament,
            rootNote: rootNote ?? musicalScale.rootNote,
            referenceNote: referenceNote ?? musicalScale.referenceNote,
            referenceFrequency: referenceFrequency ?? musicalScale.referenceFrequency,
            frequencyMin: musicalScale.frequencyMin,
            frequencyMax: musicalScale.frequencyMax,
            stretchTuning: musicalScale.stretchTuning
        )
    }
    
    // Phase 1 Shim for ViewModel access
    var defaultStretchTuning: StretchTuning {
        predefinedStretchTunings().first { $0.stableId == STRETCH_TUNING_ID_NO_STRETCH }!
    }
    
    var predefinedStretchTunings: [StretchTuning] {
        de.moekadu.tuner.stretchtuning.predefinedStretchTunings()
    }
    
    var customStretchTunings: [StretchTuning] = []
    var customStretchTuningsExpanded: Bool = true
    var predefinedStretchTuningsExpanded: Bool = false
    
    func writePredefinedStretchTuningsExpanded(_ val: Bool) { predefinedStretchTuningsExpanded = val }
    func writeCustomStretchTuningsExpanded(_ val: Bool) { customStretchTuningsExpanded = val }
    func writeCustomStretchTunings(_ items: [StretchTuning]) { customStretchTunings = items }
    
    func appendStretchTunings(_ list: [StretchTuning]) {
        customStretchTunings.append(contentsOf: list)
    }
    
    func removeStretchTuning(_ t: StretchTuning) {
        customStretchTunings.removeAll { $0.id == t.id }
    }
}
