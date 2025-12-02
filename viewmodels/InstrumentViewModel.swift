import Foundation
import Combine

/// ViewModel for the Instruments list screen.
/// Equivalent to `InstrumentViewModel.kt`.
@MainActor
class InstrumentViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let instruments: InstrumentResources
    private let applicationScope: ApplicationScope
    
    // MARK: - State
    
    // Predefined
    var predefinedInstruments: [Instrument] { instruments.predefinedInstruments }
    @Published var predefinedExpanded: Bool = false
    
    // Custom
    @Published var customInstruments: [Instrument] = []
    @Published var customExpanded: Bool = true
    
    // Active
    @Published var currentInstrument: Instrument
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(instruments: InstrumentResources = DependencyContainerKey.defaultValue.instruments,
         applicationScope: ApplicationScope = DependencyContainerKey.defaultValue.applicationScope) {
        self.instruments = instruments
        self.applicationScope = applicationScope
        self.currentInstrument = instruments.currentInstrument
        
        // Bindings
        instruments.$customInstruments
            .assign(to: \.customInstruments, on: self)
            .store(in: &cancellables)
            
        instruments.$currentInstrument
            .assign(to: \.currentInstrument, on: self)
            .store(in: &cancellables)
            
        // Assuming resources has published properties for expansion state
        // If not, we manage local state or add them to resources stub
    }
    
    // MARK: - Actions
    
    func setCurrentInstrument(_ instrument: Instrument) {
        instruments.setInstrument(instrument)
    }
    
    func deleteCustomInstrument(_ instrument: Instrument) {
        instruments.remove(instrumentId: instrument.stableId)
    }
    
    func saveInstruments(to url: URL, instrumentsList: [Instrument]) {
        applicationScope.launch {
            let content = InstrumentIO.instrumentsListToString(instruments: instrumentsList)
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to save instruments: \(error)")
            }
        }
    }
}
