import SwiftUI

/// The main entry point for the Tuner application.
///
/// Equivalent to `TunerApplication.kt` in the Android project.
/// This struct manages the application lifecycle and serves as the
/// composition root for dependency injection (replacing @HiltAndroidApp).
@main
struct TunerApp: App {
    
    // MARK: - Dependency Injection
    // In Phase 1, we establish the container to mirror Hilt's role.
    // We will populate this as we port modules.
    private let dependencyContainer: DependencyContainer
    
    init() {
        // Initialize core dependencies (equivalent to Application.onCreate)
        self.dependencyContainer = DependencyContainer()
        
        // Optional: Configure global appearance or logging here
    }
    
    // MARK: - Scene Composition
    var body: some Scene {
        WindowGroup {
            // Phase 1: Direct Port
            // As we haven't ported MainActivity yet, this serves as the temporary root.
            // Once MainActivity is ported, we will swap this View.
            ContentPlaceholderView()
                .environment(\.dependencyContainer, dependencyContainer)
        }
    }
}

// MARK: - Architecture Support
// These structures provide the foundation to support the Hilt -> Swift translation
// in subsequent files.

/// A container for app-wide dependencies, replacing the Dagger/Hilt graph.
@MainActor
final class DependencyContainer: ObservableObject, Sendable {
    // Dependencies will be added here as we port them.
    init() {}
}

// Extension to pass dependencies down the SwiftUI tree easily
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = DependencyContainer()
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

/// A temporary placeholder view to ensure the app compiles and runs
/// before MainActivity is ported.
struct ContentPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "tuningfork")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Tuner Port In Progress")
                .font(.headline)
        }
        .padding()
    }
}
