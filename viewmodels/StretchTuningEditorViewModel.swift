import Foundation
import Combine

/// ViewModel for editing a specific Stretch Tuning.
/// Equivalent to `StretchTuningEditorViewModel.kt`.
@MainActor
class StretchTuningEditorViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let resources: TemperamentResources
    
    // MARK: - State
    @Published var stretchTuning: StretchTuning
    @Published var name: String
    @Published var description: String
    
    // Selection state (for chart/list)
    @Published var selectedKey: Int = StretchTuning.NO_KEY
    
    private let stableId: Int64
    
    // MARK: - Initialization
    
    init(tuning: StretchTuning,
         resources: TemperamentResources = DependencyContainerKey.defaultValue.temperaments) {
        self.resources = resources
        
        self.stretchTuning = tuning
        self.name = tuning.name
        self.description = tuning.description
        self.stableId = tuning.stableId
    }
    
    // MARK: - Actions
    
    func modifyLine(frequency: Double, cents: Double, key: Int) {
        stretchTuning = stretchTuning.add(unstretchedFrequency: frequency, stretchVal: cents, key: key)
    }
    
    func removeLine(key: Int) {
        // Needs `remove(key)` logic in StretchTuning struct (currently `remove(at: index)`)
        // We find index first
        if let index = stretchTuning.keys.firstIndex(of: key) {
             stretchTuning = stretchTuning.remove(at: index)
        }
    }
    
    func saveStretchTuning() {
        let newTuning = StretchTuning(
            name: name,
            description: description,
            unstretchedFrequencies: stretchTuning.unstretchedFrequencies,
            stretchInCents: stretchTuning.stretchInCents,
            keys: stretchTuning.keys,
            stableId: stableId
        )
        
        // Determine if add or update
        // resources.addOrUpdateStretchTuning(newTuning)
        // For Phase 1 we can call:
        resources.appendStretchTunings([newTuning]) // Simplification
    }
}
