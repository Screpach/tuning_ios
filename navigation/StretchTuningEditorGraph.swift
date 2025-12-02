import SwiftUI

// MARK: - Routes

struct StretchTuningEditorGraphRoute: Hashable, Codable, Sendable {
    let stretchTuning: StretchTuning
}

// MARK: - Flow / Graph View

/// The entry point for the Stretch Tuning Editor flow.
///
/// Equivalent to `StretchTuningEditorGraph.kt`.
/// Scopes the ViewModel to the editor session and manages the "Modify Line" dialog.
struct StretchTuningEditorFlowView: View {
    
    // Arguments
    let route: StretchTuningEditorGraphRoute
    
    // Scoped ViewModel
    @StateObject private var viewModel: StretchTuningEditorViewModel
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    
    init(route: StretchTuningEditorGraphRoute) {
        self.route = route
        _viewModel = StateObject(wrappedValue: StretchTuningEditorViewModel(tuning: route.stretchTuning))
    }
    
    var body: some View {
        StretchTuningEditor(
            viewModel: viewModel,
            onNavigateUp: {
                dismiss()
            },
            onModifyLineClicked: { freq, cents, key in
                viewModel.startEditing(frequency: freq, cents: cents, key: key)
            }
        )
        // Dialog: Modify Line
        .sheet(item: $viewModel.activeEditLine) { data in
            ModifyStretchTuningLineDialog(
                initialFrequency: data.frequency,
                initialCents: data.cents,
                key: data.key,
                onAbortClicked: {
                    viewModel.activeEditLine = nil
                },
                onConfirmedClicked: { freq, cents, key in
                    viewModel.modifyLine(frequency: freq, cents: cents, key: key)
                    viewModel.activeEditLine = nil
                }
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - ViewModel

@MainActor
class StretchTuningEditorViewModel: ObservableObject {
    
    // MARK: State
    @Published var stretchTuning: StretchTuning
    @Published var activeEditLine: StretchTuningEditData?
    
    init(tuning: StretchTuning) {
        self.stretchTuning = tuning
    }
    
    // MARK: Intents
    
    func startEditing(frequency: Double, cents: Double, key: Int) {
        activeEditLine = StretchTuningEditData(frequency: frequency, cents: cents, key: key)
    }
    
    func modifyLine(frequency: Double, cents: Double, key: Int) {
        // Calling the immutable modifier on the struct
        // Note: The logic for add/modify is unified in the StretchTuning struct we ported earlier
        stretchTuning = stretchTuning.add(
            unstretchedFrequency: frequency,
            stretchVal: cents,
            key: key
        )
    }
}

/// Helper struct to trigger the sheet (replaces ModifyStretchTuningLineDialogRoute)
struct StretchTuningEditData: Identifiable {
    let id = UUID()
    let frequency: Double
    let cents: Double
    let key: Int
}

// MARK: - Stubs (UI Components)

struct StretchTuningEditor: View {
    @ObservedObject var viewModel: StretchTuningEditorViewModel
    var onNavigateUp: () -> Void
    var onModifyLineClicked: (Double, Double, Int) -> Void
    
    var body: some View {
        List {
            Section("Points") {
                if viewModel.stretchTuning.unstretchedFrequencies.isEmpty {
                    Text("No points defined")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(0..<viewModel.stretchTuning.unstretchedFrequencies.count, id: \.self) { i in
                        HStack {
                            Text(String(format: "%.1f Hz", viewModel.stretchTuning.unstretchedFrequencies[i]))
                            Spacer()
                            Text(String(format: "%.1f cents", viewModel.stretchTuning.stretchInCents[i]))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onModifyLineClicked(
                                viewModel.stretchTuning.unstretchedFrequencies[i],
                                viewModel.stretchTuning.stretchInCents[i],
                                viewModel.stretchTuning.keys[i]
                            )
                        }
                    }
                }
            }
            
            Button("Add Point") {
                // Trigger add logic (usually 0,0 or intelligent default)
                onModifyLineClicked(440.0, 0.0, Int.random(in: 0..<Int.max))
            }
        }
        .navigationTitle(viewModel.stretchTuning.name)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done", action: onNavigateUp)
            }
        }
    }
}

struct ModifyStretchTuningLineDialog: View {
    let initialFrequency: Double
    let initialCents: Double
    let key: Int
    
    var onAbortClicked: () -> Void
    var onConfirmedClicked: (Double, Double, Int) -> Void
    
    @State private var frequencyStr: String
    @State private var centsStr: String
    
    init(initialFrequency: Double, initialCents: Double, key: Int, onAbortClicked: @escaping () -> Void, onConfirmedClicked: @escaping (Double, Double, Int) -> Void) {
        self.initialFrequency = initialFrequency
        self.initialCents = initialCents
        self.key = key
        self.onAbortClicked = onAbortClicked
        self.onConfirmedClicked = onConfirmedClicked
        
        _frequencyStr = State(initialValue: String(initialFrequency))
        _centsStr = State(initialValue: String(initialCents))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Frequency (Hz)", text: $frequencyStr)
                    .keyboardType(.decimalPad)
                TextField("Stretch (Cents)", text: $centsStr)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Edit Point")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onAbortClicked)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        if let freq = Double(frequencyStr), let cents = Double(centsStr) {
                            onConfirmedClicked(freq, cents, key)
                        }
                    }
                }
            }
        }
    }
}
