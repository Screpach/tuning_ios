import SwiftUI

// MARK: - Routes

struct PreferencesGraphRoute: Hashable, Codable, Sendable {}

// MARK: - Flow / Graph View

/// The entry point for the Preferences flow.
///
/// Equivalent to `PreferenceGraph.kt`.
/// Manages the presentation of the main settings screen and all setting-related dialogs.
struct PreferencesFlowView: View {
    
    // Arguments (None for this graph, but good for consistency)
    let route: PreferencesGraphRoute
    
    // Scoped ViewModel
    @StateObject private var viewModel = PreferencesViewModel()
    
    // Environment / Dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var deps
    
    init(route: PreferencesGraphRoute = PreferencesGraphRoute()) {
        self.route = route
    }
    
    var body: some View {
        PreferencesScreen(
            viewModel: viewModel,
            onAppearanceClicked: { viewModel.activeDialog = .appearance },
            onNotationClicked: { viewModel.activeDialog = .notation },
            onWindowingClicked: { viewModel.activeDialog = .windowing },
            onResetClicked: { viewModel.activeDialog = .reset },
            onAboutClicked: { viewModel.activeDialog = .about },
            onNavigateUp: { dismiss() }
        )
        // Global Sheet Manager for this Flow
        .sheet(item: $viewModel.activeDialog) { dialogType in
            switch dialogType {
            case .appearance:
                AppearanceDialog(
                    currentSettings: deps.preferences.appearance, // Accessing @Published via deps
                    onAppearanceChanged: { newSettings in
                        // Reconstruct/Update specific fields or whole object
                        if newSettings.mode != deps.preferences.appearance.mode {
                            deps.preferences.writeAppearance(newSettings.mode)
                        }
                        deps.preferences.writeUseSystemColorAccents(newSettings.useSystemColorAccents)
                        deps.preferences.writeBlackNightEnabled(newSettings.blackNightEnabled)
                        
                        viewModel.activeDialog = nil
                    },
                    onDismiss: { viewModel.activeDialog = nil }
                )
                .presentationDetents([.medium])
                
            case .notation:
                NotationDialog(
                    currentNotation: deps.preferences.octaveNotation,
                    currentPrintOptions: deps.preferences.notePrintOptions,
                    onSettingsChanged: { notation, printOptions in
                        deps.preferences.writeOctaveNotation(notation)
                        deps.preferences.writeNotePrintOptions(printOptions)
                        viewModel.activeDialog = nil
                    },
                    onDismiss: { viewModel.activeDialog = nil }
                )
                .presentationDetents([.medium])
                
            case .windowing:
                // Note: In a real app we'd bind this to the preference.
                // For Phase 1 we use a placeholder or read the current value.
                WindowingFunctionDialog(
                    // We assume deps.preferences has a windowing read method or property
                    // Since it wasn't in ReferenceResources.kt, we use a default here.
                    initialFunction: .hamming,
                    onChanged: { newFunction in
                        // deps.preferences.writeWindowing(newFunction)
                        print("New windowing function: \(newFunction)")
                        viewModel.activeDialog = nil
                    },
                    onDismiss: { viewModel.activeDialog = nil }
                )
                .presentationDetents([.medium])
                
            case .reset:
                ResetDialog(
                    onReset: {
                        // Reset all settings logic
                        // deps.preferences.resetAllSettings()
                        // deps.temperaments.resetAllSettings()
                        print("Resetting all settings...")
                        viewModel.activeDialog = nil
                    },
                    onDismiss: { viewModel.activeDialog = nil }
                )
                .presentationDetents([.fraction(0.3)])
                
            case .about:
                AboutDialog(
                    onDismiss: { viewModel.activeDialog = nil }
                )
                .presentationDetents([.large])
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class PreferencesViewModel: ObservableObject {
    @Published var activeDialog: PreferenceDialogType?
}

enum PreferenceDialogType: Identifiable {
    case appearance
    case notation
    case windowing
    case reset
    case about
    
    var id: Self { self }
}

// MARK: - Supporting Enums (Missing Definitions)

enum WindowingFunction: String, CaseIterable, Identifiable, Sendable {
    case topHat = "Top Hat"
    case hamming = "Hamming"
    case hann = "Hann"
    // Add others from source...
    
    var id: String { rawValue }
}

// MARK: - Stubs (UI Components)

struct PreferencesScreen: View {
    @ObservedObject var viewModel: PreferencesViewModel
    var onAppearanceClicked: () -> Void
    var onNotationClicked: () -> Void
    var onWindowingClicked: () -> Void
    var onResetClicked: () -> Void
    var onAboutClicked: () -> Void
    var onNavigateUp: () -> Void
    
    var body: some View {
        List {
            Section("Display") {
                Button("Appearance") { onAppearanceClicked() }
                Button("Notation") { onNotationClicked() }
            }
            
            Section("Audio Processing") {
                Button("Windowing Function") { onWindowingClicked() }
            }
            
            Section("App") {
                Button("Reset Settings", role: .destructive) { onResetClicked() }
                Button("About") { onAboutClicked() }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done", action: onNavigateUp)
            }
        }
    }
}

// Dialog Stubs

struct AppearanceDialog: View {
    let currentSettings: AppearanceSettings
    let onAppearanceChanged: (AppearanceSettings) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Appearance Settings").font(.headline)
            // Mock controls
            Button("Save & Close") {
                onAppearanceChanged(currentSettings) // Just passing back current for stub
            }
        }
        .padding()
    }
}

struct NotationDialog: View {
    let currentNotation: OctaveNotation
    let currentPrintOptions: NotePrintOptions
    let onSettingsChanged: (OctaveNotation, NotePrintOptions) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Notation Settings").font(.headline)
            Button("Save & Close") {
                onSettingsChanged(currentNotation, currentPrintOptions)
            }
        }
        .padding()
    }
}

struct WindowingFunctionDialog: View {
    let initialFunction: WindowingFunction
    let onChanged: (WindowingFunction) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Windowing Function").font(.headline)
            Button("Set Hamming") { onChanged(.hamming) }
        }
        .padding()
    }
}

struct ResetDialog: View {
    let onReset: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Reset All Settings?").font(.headline)
            Text("This cannot be undone.").font(.caption)
            HStack {
                Button("Cancel", action: onDismiss)
                Button("Reset", role: .destructive, action: onReset)
            }
        }
        .padding()
    }
}

struct AboutDialog: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("About Tuner").font(.title)
            Text("Version 1.0").foregroundStyle(.secondary)
            Spacer()
            Button("Close", action: onDismiss)
        }
        .padding()
    }
}
