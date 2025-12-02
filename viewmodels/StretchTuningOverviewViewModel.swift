import Foundation
import Combine

/// ViewModel for the Stretch Tuning Overview screen.
/// Equivalent to `StretchTuningOverviewViewModel.kt`.
@MainActor
class StretchTuningOverviewViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let resources: TemperamentResources // Kotlin file calls this 'pref' but type is TemperamentResources
    private let applicationScope: ApplicationScope
    
    // MARK: - State
    
    // Predefined Section
    var predefinedStretchTunings: [StretchTuning] { resources.predefinedStretchTunings }
    @Published var predefinedExpanded: Bool = false
    
    // Custom Section
    @Published var customStretchTunings: [StretchTuning] = []
    @Published var customExpanded: Bool = true
    
    // Active Selection
    @Published var activeStretchTuning: StretchTuning?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(resources: TemperamentResources = DependencyContainerKey.defaultValue.temperaments,
         applicationScope: ApplicationScope = DependencyContainerKey.defaultValue.applicationScope) {
        self.resources = resources
        self.applicationScope = applicationScope
        
        // Bind Custom List
        resources.$customStretchTunings
            .assign(to: \.customStretchTunings, on: self)
            .store(in: &cancellables)
            
        resources.$customStretchTuningsExpanded
            .assign(to: \.customExpanded, on: self)
            .store(in: &cancellables)
            
        resources.$predefinedStretchTuningsExpanded
            .assign(to: \.predefinedExpanded, on: self)
            .store(in: &cancellables)
        
        // Bind Active Tuning (from Musical Scale)
        resources.musicalScale
            .map { $0.stretchTuning }
            .assign(to: \.activeStretchTuning, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func togglePredefinedExpanded(_ expanded: Bool) {
        resources.writePredefinedStretchTuningsExpanded(expanded)
    }
    
    func toggleCustomExpanded(_ expanded: Bool) {
        resources.writeCustomStretchTuningsExpanded(expanded)
    }
    
    func selectStretchTuning(_ tuning: StretchTuning) {
        // We need to set this on the musical scale
        // In Phase 1, we assume resources has a helper or we modify the scale directly via resources
        resources.setStretchTuning(tuning)
    }
    
    func deleteCustomStretchTuning(_ tuning: StretchTuning) {
        resources.removeStretchTuning(tuning)
    }
    
    func saveStretchTunings(to url: URL, tunings: [StretchTuning]) {
        applicationScope.launch {
            let content = StretchTuningIO.stretchTuningsToString(tunings)
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to save stretch tunings: \(error)")
            }
        }
    }
}
