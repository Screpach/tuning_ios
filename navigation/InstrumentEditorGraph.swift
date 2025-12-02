import SwiftUI

// MARK: - Routes

struct InstrumentEditorGraphRoute: Hashable, Codable, Sendable {
    let instrument: Instrument
}

// MARK: - Flow / Graph View

/// The entry point for the Instrument Editor flow.
///
/// Equivalent to `InstrumentEditorGraph.kt`.
/// Handles the navigation scope for editing an instrument, including the main editor
/// and the icon picker dialog.
struct InstrumentEditorFlowView: View {
    
    // Arguments
    let route: InstrumentEditorGraphRoute
    
    // Scoped ViewModel
    @StateObject private var viewModel: InstrumentEditorViewModel
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var deps
    
    init(route: InstrumentEditorGraphRoute) {
        self.route = route
        _viewModel = StateObject(wrappedValue: InstrumentEditorViewModel(instrument: route.instrument))
    }
    
    var body: some View {
        InstrumentEditor(
            viewModel: viewModel,
            onIconButtonClicked: {
                viewModel.showIconPicker = true
            },
            onNavigateUpClicked: {
                dismiss()
            },
            onSaveNewInstrumentClicked: {
                viewModel.saveInstrument(resources: deps.instruments)
                dismiss()
            }
        )
        // Dialog: Icon Picker
        .sheet(isPresented: $viewModel.showIconPicker) {
            InstrumentIconPicker(
                onDismiss: {
                    viewModel.showIconPicker = false
                },
                onIconSelected: { icon in
                    viewModel.icon = icon
                    viewModel.showIconPicker = false
                }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - ViewModel

@MainActor
class InstrumentEditorViewModel: ObservableObject {
    
    // MARK: State
    @Published var name: String
    @Published var icon: InstrumentIcon
    @Published var strings: [MusicalNote]
    @Published var isChromatic: Bool
    @Published var showIconPicker: Bool = false
    
    // MARK: Internal
    private let originalId: Int64
    private let originalNameResource: String?
    
    init(instrument: Instrument) {
        // Initialize draft state from the passed instrument
        self.name = instrument.name // For custom instruments, this is the user name
        self.icon = instrument.icon
        self.strings = instrument.strings
        self.isChromatic = instrument.isChromatic
        
        self.originalId = instrument.stableId
        self.originalNameResource = instrument.nameResource
    }
    
    func saveInstrument(resources: InstrumentResources) {
        // Logic to determine Update vs Create
        // Note: In the Kotlin code `addNewOrReplaceInstrument` handles this.
        
        if originalId == Instrument.NO_STABLE_ID {
            // Create New
            let newInstrument = Instrument(
                name: name,
                nameResource: nil, // Custom instruments usually don't have resources
                strings: strings,
                icon: icon,
                stableId: Instrument.NO_STABLE_ID, // Resources will assign ID
                isChromatic: isChromatic
            )
            resources.add(newInstrument)
        } else {
            // Update Existing
            // We use the `update` method ported in InstrumentResources.swift
            resources.update(
                id: originalId,
                name: name,
                icon: icon,
                strings: strings,
                isChromatic: isChromatic
            )
        }
    }
}

// MARK: - Stubs (UI Components)

struct InstrumentEditor: View {
    @ObservedObject var viewModel: InstrumentEditorViewModel
    var onIconButtonClicked: () -> Void
    var onNavigateUpClicked: () -> Void
    var onSaveNewInstrumentClicked: () -> Void
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $viewModel.name)
                
                HStack {
                    Text("Icon")
                    Spacer()
                    viewModel.icon.image // Using the helper from InstrumentIcons.swift
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .onTapGesture {
                            onIconButtonClicked()
                        }
                }
            }
            
            Section("Strings") {
                ForEach(viewModel.strings.indices, id: \.self) { index in
                    Text("String \(index + 1): \(viewModel.strings[index].base.rawValue)\(viewModel.strings[index].octave)")
                }
                // Editor for strings would go here
            }
        }
        .navigationTitle(viewModel.name.isEmpty ? "New Instrument" : viewModel.name)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onNavigateUpClicked)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: onSaveNewInstrumentClicked)
            }
        }
    }
}

struct InstrumentIconPicker: View {
    var onDismiss: () -> Void
    var onIconSelected: (InstrumentIcon) -> Void
    
    let icons = InstrumentIcon.allCases
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                    ForEach(icons, id: \.self) { icon in
                        VStack {
                            icon.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                            Text(icon.rawValue)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .padding()
                        .onTapGesture {
                            onIconSelected(icon)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Icon")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
    }
}
