import SwiftUI

// MARK: - Root Flow View

/// The main navigation graph of the application.
///
/// Equivalent to `MainGraph.kt`.
/// This view holds the root `NavigationStack` and routes to all major features
/// including Tuner, Instruments, and the various Editors.
struct MainFlowView: View {
    
    // MARK: - State
    
    // Controls the navigation stack
    @State private var navigationPath = NavigationPath()
    
    // Controls modal sheets (Dialogs)
    @State private var activeSheet: MainSheetRoute?
    
    // Environment
    @Environment(\.dependencyContainer) private var deps
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // 1. Start Destination: Tuner Screen
            TunerScreen(
                onInstrumentClicked: {
                    navigationPath.append(MainRoute.instruments)
                },
                onSettingsClicked: {
                    navigationPath.append(MainRoute.preferences)
                },
                onReferenceFrequencyClicked: {
                    // In real app, get current scale from resources
                    // Mocking scale for now
                    let mockScale = MusicalScale2.createTestEdo12()
                    activeSheet = .referenceFrequency(scale: mockScale, warning: nil)
                },
                onTemperamentClicked: {
                    activeSheet = .temperamentDialog
                },
                onRootNoteClicked: {
                    let mockTemp = predefinedTemperamentEDO(12, 1) // Mock
                    let mockRoot = MusicalNote(.C, .none, 4) // Mock
                    activeSheet = .rootNote(temperament: mockTemp, root: mockRoot)
                }
            )
            .navigationTitle("Tuner")
            .navigationDestination(for: MainRoute.self) { route in
                switch route {
                case .instruments:
                    InstrumentsScreen(
                        onInstrumentClicked: { instrument in
                            // Logic to select instrument (via Resources)
                            deps.instruments.setInstrument(instrument)
                            navigationPath.removeLast() // Go back to Tuner
                        },
                        onEditIconClicked: { instrument in
                            navigationPath.append(MainRoute.instrumentEditor(instrument))
                        },
                        onNewInstrumentClicked: {
                            // Pass a "New" template or handle in Editor
                            // For simplicity, we create a basic template
                            let template = Instrument(name: "", nameResource: nil, strings: [], icon: .guitar, stableId: Instrument.NO_STABLE_ID)
                            navigationPath.append(MainRoute.instrumentEditor(template))
                        }
                    )
                    
                case .preferences:
                    PreferencesFlowView()
                    
                case .instrumentEditor(let instrument):
                    InstrumentEditorFlowView(
                        route: InstrumentEditorGraphRoute(instrument: instrument)
                    )
                    
                case .temperamentEditor(let temperament):
                    TemperamentEditorFlowView(
                        route: TemperamentEditorGraphRoute(temperament: temperament)
                    )
                    
                case .stretchTuningEditor(let tuning):
                    StretchTuningEditorFlowView(
                        route: StretchTuningEditorGraphRoute(stretchTuning: tuning)
                    )
                    
                case .stretchTuningOverview:
                    StretchTuningOverviewScreen(
                        onEditClicked: { tuning in
                            navigationPath.append(MainRoute.stretchTuningEditor(tuning))
                        }
                    )
                }
            }
        }
        // MARK: - Global Dialogs (Sheets)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .referenceFrequency(let scale, let warning):
                ReferenceFrequencyDialog(
                    musicalScale: scale,
                    warning: warning,
                    onDismiss: { activeSheet = nil }
                )
                .presentationDetents([.medium])
                
            case .temperamentDialog:
                TemperamentDialog(
                    onInfoClicked: { temp in
                        // Swap sheet to info
                        activeSheet = .temperamentInfo(temp)
                    },
                    onEditClicked: { temp in
                        activeSheet = nil
                        // Need to convert Temperament to EditableTemperament
                        let editable = EditableTemperament() // Stub conversion
                        navigationPath.append(MainRoute.temperamentEditor(editable))
                    },
                    onDismiss: { activeSheet = nil }
                )
                .presentationDetents([.medium, .large])
                
            case .temperamentInfo(let temp):
                TemperamentInfoDialog(
                    temperament: temp,
                    onDismiss: { activeSheet = nil }
                )
                .presentationDetents([.medium])
                
            case .rootNote(let temp, let root):
                RootNoteDialog(
                    temperament: temp,
                    currentRoot: root,
                    onDismiss: { activeSheet = nil }
                )
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Routes

/// Stack Navigation Destinations
enum MainRoute: Hashable, Codable, Sendable {
    case instruments
    case preferences
    case stretchTuningOverview
    case instrumentEditor(Instrument)
    case temperamentEditor(EditableTemperament)
    case stretchTuningEditor(StretchTuning)
}

/// Modal Sheet Destinations
enum MainSheetRoute: Identifiable {
    case referenceFrequency(scale: MusicalScale2, warning: String?)
    case temperamentDialog
    case temperamentInfo(Temperament)
    case rootNote(temperament: Temperament, root: MusicalNote)
    
    var id: String {
        switch self {
        case .referenceFrequency: return "refFreq"
        case .temperamentDialog: return "tempDialog"
        case .temperamentInfo: return "tempInfo"
        case .rootNote: return "rootNote"
        }
    }
}

// MARK: - Stubs (Screens & Dialogs)
// These components need to be fully implemented in Phase 2 (UI Redesign).
// For now, they serve as placeholders to make the navigation graph functional.

struct TunerScreen: View {
    var onInstrumentClicked: () -> Void
    var onSettingsClicked: () -> Void
    var onReferenceFrequencyClicked: () -> Void
    var onTemperamentClicked: () -> Void
    var onRootNoteClicked: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tuner Screen").font(.largeTitle)
            
            HStack {
                Button("Instrument", action: onInstrumentClicked)
                Button("Ref Freq", action: onReferenceFrequencyClicked)
            }
            HStack {
                Button("Temperament", action: onTemperamentClicked)
                Button("Root Note", action: onRootNoteClicked)
            }
            
            Spacer()
            
            Button("Settings", action: onSettingsClicked)
        }
        .padding()
    }
}

struct InstrumentsScreen: View {
    var onInstrumentClicked: (Instrument) -> Void
    var onEditIconClicked: (Instrument) -> Void
    var onNewInstrumentClicked: () -> Void
    
    @Environment(\.dependencyContainer) var deps
    
    var body: some View {
        List {
            Section("Instruments") {
                ForEach(deps.instruments.predefinedInstruments) { inst in
                    HStack {
                        Button(inst.getNameString()) {
                            onInstrumentClicked(inst)
                        }
                        Spacer()
                        Button(action: { onEditIconClicked(inst) }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .navigationTitle("Instruments")
        .toolbar {
            Button("Add", action: onNewInstrumentClicked)
        }
    }
}

struct StretchTuningOverviewScreen: View {
    var onEditClicked: (StretchTuning) -> Void
    
    var body: some View {
        Text("Stretch Tuning Overview")
    }
}

// Dialogs

struct ReferenceFrequencyDialog: View {
    let musicalScale: MusicalScale2
    let warning: String?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Reference Frequency").font(.headline)
            if let warning = warning {
                Text(warning).foregroundStyle(.red)
            }
            Button("Close", action: onDismiss)
        }
        .padding()
    }
}

struct TemperamentDialog: View {
    var onInfoClicked: (Temperament) -> Void
    var onEditClicked: (Temperament) -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Temperament Selection").font(.headline)
            // Mock list
            Button("Edit Current") {
                // Mock
                onEditClicked(predefinedTemperamentEDO(12, 1))
            }
            Button("Info") {
                onInfoClicked(predefinedTemperamentEDO(12, 1))
            }
            Button("Close", action: onDismiss)
        }
        .padding()
    }
}

struct TemperamentInfoDialog: View {
    let temperament: Temperament
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Temperament Info").font(.headline)
            Button("Close", action: onDismiss)
        }
        .padding()
    }
}

struct RootNoteDialog: View {
    let temperament: Temperament
    let currentRoot: MusicalNote
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Root Note").font(.headline)
            Text("Current: \(currentRoot.base.rawValue)")
            Button("Close", action: onDismiss)
        }
        .padding()
    }
}
