import Foundation

enum TemperamentIO {
    
    struct TemperamentsAndFileCheckResult {
        let fileCheck: FileCheck
        let temperaments: [EditableTemperament]
    }
    
    static func temperamentsListToString(_ temperaments: [EditableTemperament]) -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        var output = "Version=\(version)\n\n"
        
        for t in temperaments {
            output += getSingleTemperamentString(t) + "\n\n"
        }
        return output
    }
    
    private static func getSingleTemperamentString(_ t: EditableTemperament) -> String {
        var sb = "Temperament\n"
        sb += "Name=\(t.name)\n"
        if !t.abbreviation.isEmpty { sb += "Abbreviation=\(t.abbreviation)\n" }
        if !t.description.isEmpty { sb += "Description=\(t.description)\n" }
        
        sb += "Values={\n"
        for line in t.noteLines {
            guard let l = line else { continue }
            // Format: "Cent=100.0 Ratio=16/15 Note=C#4"
            var parts = [String]()
            if let c = l.cent { parts.append("Cent=\(c)") }
            if let r = l.ratio { parts.append("Ratio=\(r.numerator)/\(r.denominator)") }
            if let n = l.note { parts.append("Note=\(formatNote(n))") }
            sb += "  " + parts.joined(separator: " ") + "\n"
        }
        sb += "}"
        return sb
    }
    
    private static func formatNote(_ n: MusicalNote) -> String {
        // Needs robust serializer. Simple placeholder:
        return "\(n.base.rawValue)\(n.modifier.rawValue)\(n.octave)"
    }
    
    // readFromContent logic omitted for brevity in Phase 1, similar to InstrumentIO
}
