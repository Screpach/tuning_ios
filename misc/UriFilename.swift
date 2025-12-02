import Foundation

/// Helper to extract a filename from a URL.
///
/// Equivalent to `UriFilename.kt`.
/// On iOS, we typically deal with `file://` URLs (even if security scoped),
/// so the filename is derived directly from the path component.
///
/// - Parameter url: The file URL.
/// - Returns: The display name (filename with extension), or nil if the URL is empty/invalid.
func getFilenameFromUrl(_ url: URL) -> String? {
    // Android logic:
    // Queries ContentResolver for OpenableColumns.DISPLAY_NAME.
    
    // iOS logic:
    // 1. URL provides the name directly via lastPathComponent.
    // 2. We check if it's empty to return nil, matching the optional return type.
    
    let name = url.lastPathComponent
    
    // Handle root path or empty strings
    if name.isEmpty || name == "/" {
        return nil
    }
    
    return name
}
