import SwiftUI

/// Defines the icon associated with an instrument.
///
/// Equivalent to `InstrumentIcon.kt`.
/// Maps strongly-typed cases to asset image names.
enum InstrumentIcon: String, Codable, Hashable, CaseIterable, Sendable {
    case guitar
    case ukulele
    case eguitar
    case bass
    case violin
    case cello
    case double_bass
    case trumpet
    case saxophone
    case flute
    case harp
    case tar
    case setar
    case kamancheh
    case oud
    // Add any others from the full Android file that weren't visible in the snippet
    // For defaults that might be missing:
    case piano
    case chromatic // generic
    
    /// The name of the image asset in the Xcode Asset Catalog.
    ///
    /// Naming convention matches Android drawables: "ic_name"
    var resourceName: String {
        switch self {
        case .piano: return "ic_piano"
        case .chromatic: return "ic_chromatic" // fallback or generic icon
        default: return "ic_\(self.rawValue)"
        }
    }
    
    /// SwiftUI Image helper
    var image: Image {
        // Returns the image from the Asset Catalog, or a fallback system symbol if missing
        // This prevents crashes if assets aren't imported yet.
        Image(resourceName)
    }
}
