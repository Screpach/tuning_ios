import Foundation

// MARK: - Protocol

/// Interface for retrieving text.
///
/// Equivalent to `GetText.kt`.
/// Allows for deferred resolution of strings, which is useful when data models
/// (like Tunings) refer to localized resources that should only be resolved
/// at display time.
protocol GetText: Codable, Sendable {
    /// Resolves the string value.
    ///
    /// - Returns: The final string (localized if applicable).
    func getString() -> String
}

// MARK: - Implementations

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
    /// The key in Localizable.xcstrings (equivalent to R.string.id).
    let resourceKey: String
    
    init(resourceKey: String) {
        self.resourceKey = resourceKey
    }
    
    func getString() -> String {
        return String(localized: LocalizedStringResource(stringLiteral: resourceKey))
    }
}

/// Helper for localized resource content with a single integer argument.
///
/// Equivalent to `GetTextFromResIdWithIntArg`.
struct GetTextFromResIdWithIntArg: GetText {
    /// The key in Localizable.xcstrings.
    /// The localized value should contain a format specifier (e.g., "Value: %d").
    let resourceKey: String
    let arg: Int
    
    init(resourceKey: String, arg: Int) {
        self.resourceKey = resourceKey
        self.arg = arg
    }
    
    func getString() -> String {
        // 1. Resolve the format string
        let format = String(localized: LocalizedStringResource(stringLiteral: resourceKey))
        
        // 2. Format with argument
        return String(format: format, arg)
    }
}
