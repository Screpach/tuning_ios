import Foundation

/// Defines the application's appearance mode.
///
/// Equivalent to `NightMode.kt`.
enum NightMode: String, Codable, CaseIterable, Sendable {
    case on = "On"
    case off = "Off"
    case auto = "Auto"
    
    /// Helper to determine the user-facing label (optional).
    var label: String {
        switch self {
        case .on: return String(localized: "On", comment: "Night mode setting: On")
        case .off: return String(localized: "Off", comment: "Night mode setting: Off")
        case .auto: return String(localized: "Auto", comment: "Night mode setting: Auto")
        }
    }
}
