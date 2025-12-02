import Foundation

/// Legacy enum for temperament types.
/// Equivalent to `TemperamentType.kt`.
enum TemperamentTypeOld: String, Codable {
    case EDO12
    case Pythagorean
    case Pure
    case QuarterCommaMeanTone
    case ExtendedQuarterCommaMeanTone
    case ThirdCommaMeanTone
    case FifthCommaMeanTone
    case WerckmeisterIII
    case WerckmeisterIV
    case WerckmeisterV
    case WerckmeisterVI
    case Kirnberger1
    case Kirnberger2
    case Kirnberger3
    case Neidhardt1
    case Neidhardt2
    case Neidhardt3
    case Valotti
    case Young2
    // Add EDOs if needed (EDO17, etc)
}
