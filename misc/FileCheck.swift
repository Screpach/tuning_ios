import Foundation

/// Result of a file validation check.
///
/// Equivalent to `FileCheck.kt`.
enum FileCheck: Sendable {
    case ok
    case empty
    case invalid
}

extension FileCheck {
    
    /// Displays feedback if the file check resulted in an error.
    ///
    /// Equivalent to `toastPotentialFileCheckError` in Android.
    /// - Note: Since iOS lacks native "Toasts", this currently logs to the console.
    ///   In a full UI implementation, this should trigger an Alert or Banner.
    ///
    /// - Parameter url: The file URL to extract the filename from.
    @MainActor
    func toastPotentialFileCheckError(for url: URL) {
        switch self {
        case .empty:
            let filename = getFilenameFromUrl(url) ?? String(localized: "Unknown file", defaultValue: "Unknown file")
            // Android: R.string.file_empty
            print("⚠️ Toast: The file '\(filename)' is empty.")
            
        case .invalid:
            let filename = getFilenameFromUrl(url) ?? String(localized: "Unknown file", defaultValue: "Unknown file")
            // Android: R.string.file_invalid
            print("⚠️ Toast: The file '\(filename)' is invalid.")
            
        case .ok:
            break
        }
    }
}
