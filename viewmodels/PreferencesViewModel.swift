import Foundation
import Combine

/// ViewModel for the Preferences screen.
/// Equivalent to `PreferencesViewModel.kt`.
@MainActor
class PreferencesViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    let pref: PreferenceResources
    let temperaments: TemperamentResources
    
    // MARK: - State
    
    // Expose musicalScale flow from temperaments (used for reference frequency summaries etc)
    // In Swift, we can access it directly via `temperaments.musicalScale`
    
    init(pref: PreferenceResources = DependencyContainerKey.defaultValue.preferences,
         temperaments: TemperamentResources = DependencyContainerKey.defaultValue.temperaments) {
        self.pref = pref
        self.temperaments = temperaments
    }
}
