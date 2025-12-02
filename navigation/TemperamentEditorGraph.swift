import SwiftUI

// MARK: - Routes
// Equivalent to the Kotlin Serializable route classes.

struct TemperamentEditorGraphRoute: Hashable, Codable, Sendable {
    let temperament: EditableTemperament
}

// MARK: - Flow / Graph View

/// The entry point for the Temperament Editor flow.
///
/// Equivalent to `temperamentEditorGraph` in Kotlin.
/// This View acts as the "Graph Scoping" container. It initializes the ViewModel
/// so that it is shared between the main editor screen and any dialogs presented from it.
struct TemperamentEditorFlowView: View {
    
    // The input argument (from MainView navigation)
    let route: TemperamentEditorGraphRoute
    
    // The "Scoped" ViewModel
    // In Android: hiltViewModel(parentEntry)
    // In Swift: Created here, owned by this flow view.
    @StateObject private var viewModel: TemperamentEditorViewModel
    
    // Navigation controller equivalent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var deps // Access global resources
    
    init(route: TemperamentEditorGraphRoute) {
        self.route = route
        // Initialize the ViewModel with the passed temperament
        _viewModel = StateObject(wrappedValue: TemperamentEditorViewModel(temperament: route.temperament))
    }
    
    var body: some View {
        // Main Screen: TemperamentEditorRoute
        TemperamentEditor(
            viewModel: viewModel,
            onAbortClicked: {
                dismiss() // controller.navigateUp()
            },
            onSaveClicked: {
                viewModel.saveTemperament()
                dismiss() // controller.navigateUp()
            },
            onNumberOfNotesClicked: {
                // Navigate to dialog
                viewModel.showNumberOfNotesDialog = true
            }
        )
        // Dialog Route: NumberOfNotesDialogRoute
        // In SwiftUI, dialogs are modifiers on the view hierarchy.
        .sheet(isPresented: $viewModel.showNumberOfNotesDialog) {
            NumberOfNotesDialog(
                initialNumberOfNotes: viewModel.numberOfValues,
                onDismiss: {
                    viewModel.showNumberOfNotesDialog = false
                },
                onDoneClicked: { numberOfNotes in
                    viewModel.changeNumberOfValues(numberOfNotes)
                    viewModel.showNumberOfNotesDialog = false
                }
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Stubs (Dependencies)
// These components (ViewModel, UI) will be replaced by their actual files later.

@MainActor
class TemperamentEditorViewModel: ObservableObject {
    @Published var numberOfValues: Int = 12
    @Published var showNumberOfNotesDialog: Bool = false
    
    let temperament: EditableTemperament
    
    init(temperament: EditableTemperament) {
        self.temperament = temperament
    }
    
    func saveTemperament() {
        print("Saving temperament...")
    }
    
    func changeNumberOfValues(_ newCount: Int) {
        self.numberOfValues = newCount
        print("Changed number of notes to \(newCount)")
    }
}

// UI Stub: The main editor screen
struct TemperamentEditor: View {
    @ObservedObject var viewModel: TemperamentEditorViewModel
    var onAbortClicked: () -> Void
    var onSaveClicked: () -> Void
    var onNumberOfNotesClicked: () -> Void
    
    // Preference observation mock
    // In real app: @EnvironmentObject or passed param for NotePrintOptions
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Temperament Editor")
                .font(.title)
            
            Text("Editing: \(viewModel.temperament.id)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Change # of Notes") {
                onNumberOfNotesClicked()
            }
            
            Spacer()
            
            HStack {
                Button("Abort", role: .cancel, action: onAbortClicked)
                Spacer()
                Button("Save", action: onSaveClicked)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// UI Stub: The dialog
struct NumberOfNotesDialog: View {
    let initialNumberOfNotes: Int
    let onDismiss: () -> Void
    let onDoneClicked: (Int) -> Void
    
    @State private var value: Int
    
    init(initialNumberOfNotes: Int, onDismiss: @escaping () -> Void, onDoneClicked: @escaping (Int) -> Void) {
        self.initialNumberOfNotes = initialNumberOfNotes
        self.onDismiss = onDismiss
        self.onDoneClicked = onDoneClicked
        _value = State(initialValue: initialNumberOfNotes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Notes: \(value)", value: $value, in: 1...100)
                }
            }
            .navigationTitle("Number of Notes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDoneClicked(value)
                    }
                }
            }
        }
    }
}
