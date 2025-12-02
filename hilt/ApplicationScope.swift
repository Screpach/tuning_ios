import SwiftUI

// MARK: - Definition
// Equivalent to the Qualifier @ApplicationScope and the return type CoroutineScope.

/// A wrapper around a global async context.
///
/// In Kotlin, this maps to `CoroutineScope(SupervisorJob() + Dispatchers.Main)`.
/// In Swift, we use a `@MainActor` class to ensure tasks launched here run on the
/// main thread and share the application's lifecycle.
@MainActor
final class ApplicationScope: ObservableObject {
    
    /// Launches a fire-and-forget task on the main thread.
    ///
    /// - Parameter operation: The async work to perform.
    ///
    /// usage:
    /// ```swift
    /// appScope.launch {
    ///     await doSomething()
    /// }
    /// ```
    func launch(_ operation: @escaping @Sendable () async -> Void) {
        Task {
            await operation()
        }
    }
}

// MARK: - Dependency Injection Module
// Equivalent to `CoroutinesScopeModule` object in Kotlin.
// We extend the container we created in TunerApp.swift.

extension DependencyContainer {
    
    /// Provides the application-wide scope.
    /// Equivalent to:
    /// `@Provides @ApplicationScope fun providesCoroutineContext()`
    ///
    /// We use a lazy var or computed property to ensure it's a Singleton
    /// within the container.
    var applicationScope: ApplicationScope {
        if _applicationScope == nil {
            _applicationScope = ApplicationScope()
        }
        return _applicationScope!
    }
}

// Internal storage for the singleton (add this to DependencyContainer in a real app,
// but for this file-by-file port, we simulate the storage via extension using associated objects
// or just static logic if we were merging.
//
// Since we can't add stored properties in extensions, and we are in Phase 1 (Porting),
// we will assume `DependencyContainer` in `TunerApp.swift` will eventually be updated
// to hold this property directly.
//
// For now, to make this specific file strictly valid and runnable as requested:

private var _globalApplicationScopeStorage: ApplicationScope?

extension DependencyContainer {
    // A temporary backing store for this specific file's dependency
    // to ensure the property above works without modifying TunerApp.swift yet.
    private var _applicationScope: ApplicationScope? {
        get { _globalApplicationScopeStorage }
        set { _globalApplicationScopeStorage = newValue }
    }
}
