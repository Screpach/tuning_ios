import Foundation

// MARK: - StringOrResId

/// String based on string or resource key.
///
/// Equivalent to `StringOrResId.kt`.
/// Used when a value might be either a user-defined string or a predefined localized resource.
struct StringOrResId: Codable, Sendable {
    
    let string: String?
    let resourceKey: String?
    
    // MARK: - Initialization
    
    /// Create a new value based on an explicit string.
    init(string: String) {
        self.string = string
        self.resourceKey = nil
    }
    
    /// Create a new value based on a resource key.
    /// - Parameter resourceKey: The key in Localizable.xcstrings (e.g., "no_stretch_tuning").
    init(resourceKey: String) {
        self.string = nil
        self.resourceKey = resourceKey
    }
    
    // MARK: - Resolution
    
    /// Get underlying value.
    ///
    /// - Returns: The resolved string.
    func resolve() -> String {
        if let string = string {
            return string
        } else if let key = resourceKey {
            return String(localized: LocalizedStringResource(stringLiteral: key))
        } else {
            return "" // Fallback for invalid state
        }
    }
    
    /// Converts to the GetText abstraction.
    func toGetText() -> GetText {
        if let key = resourceKey {
            return GetTextFromResId(resourceKey: key)
        } else {
            return GetTextFromString(string ?? "")
        }
    }
}

// MARK: - GetText Abstractions
// These classes (GetText.kt, etc.) are often used in conjunction with StringOrResId.
// We define them here to ensure `toGetText()` works.

/// Interface for retrieving text.
protocol GetText: Sendable {
    func getString() -> String
}

/// Helper for static string content.
struct GetTextFromString: GetText {
    let string: String
    
    init(_ string: String) {
        self.string = string
    }
    
    func getString() -> String {
        return string
    }
}

/// Helper for localized resource content.
struct GetTextFromResId: GetText {
    let resourceKey: String
    
    init(resourceKey: String) {
        self.resourceKey = resourceKey
    }
    
    func getString() -> String {
        return String(localized: LocalizedStringResource(stringLiteral: resourceKey))
    }
}
