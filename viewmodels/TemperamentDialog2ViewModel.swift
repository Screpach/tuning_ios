import Foundation
import Combine

/// ViewModel for the Temperament Selection Dialog.
/// Equivalent to `TemperamentDialog2ViewModel.kt`.
@MainActor
class TemperamentDialog2ViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let resources: TemperamentResources
    private let applicationScope: ApplicationScope
    
    // MARK: - State
    
    // Predefined Section
    var predefinedTemperaments: [Temperament] { resources.predefinedTemperaments }
    @Published var predefinedExpanded: Bool = false
    
    // Custom Section
    @Published var customTemperaments: [Temperament] = []
    @Published var customExpanded: Bool = true
    
    // Active Selection
    @Published var activeTemperament: Temperament
    
    // Default (fallback)
    var defaultTemperament: Temperament { resources.defaultTemperament }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(resources: TemperamentResources = DependencyContainerKey.defaultValue.temperaments,
         applicationScope: ApplicationScope = DependencyContainerKey.defaultValue.applicationScope) {
        self.resources = resources
        self.applicationScope = applicationScope
        
        // Initialize active temperament from the current musical scale
        self.activeTemperament = resources.musicalScale.value.temperament
        
        // Bind Custom List and Expansion States
        resources.$customTemperaments
            .assign(to: \.customTemperaments, on: self)
            .store(in: &cancellables)
            
        resources.$customTemperamentsExpanded
            .assign(to: \.customExpanded, on: self)
            .store(in: &cancellables)
            
        resources.$predefinedTemperamentsExpanded
            .assign(to: \.predefinedExpanded, on: self)
            .store(in: &cancellables)
        
        // Keep active selection in sync if it changes externally
        resources.musicalScale
            .map { $0.temperament }
            .assign(to: \.activeTemperament, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func setActiveTemperament(_ temperament: Temperament) {
        resources.setTemperament(temperament)
    }
    
    func togglePredefinedExpanded(_ expanded: Bool) {
        resources.writePredefinedTemperamentsExpanded(expanded)
    }
    
    func toggleCustomExpanded(_ expanded: Bool) {
        resources.writeCustomTemperamentsExpanded(expanded)
    }
    
    func deleteCustomTemperament(_ temperament: Temperament) {
        resources.removeCustomTemperament(temperament)
    }
    
    /// Logic to determine a valid root note when switching temperaments.
    /// Some temperaments (like unequal ones) restrict valid root notes.
    func proposeRootNote(for temperament: Temperament) -> MusicalNote {
        let currentRoot = resources.musicalScale.value.rootNote
        
        // Get valid roots for the new temperament
        let possibleRoots = temperament.possibleRootNotes()
        
        // Logic ported to match standard iOS behavior:
        // If current root is valid in new temperament, keep it.
        if let current = currentRoot, possibleRoots.contains(where: { $0.base == current.base && $0.modifier == current.modifier }) {
            return current
        }
        
        // Otherwise return the first valid root (usually C)
        return possibleRoots.first ?? MusicalNote(.C, .none, 4)
    }
    
    func saveTemperaments(to url: URL, temperaments: [Temperament]) {
        applicationScope.launch {
            // Stub: TemperamentIO has not been ported yet.
            // In Phase 2, this calls: TemperamentIO.writeTemperaments(...)
            print("Saving temperaments to \(url) (Not implemented in Phase 1)")
        }
    }
}
