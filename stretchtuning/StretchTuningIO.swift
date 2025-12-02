import Foundation

/// Handles the Import/Export of stretch tunings.
///
/// Equivalent to `StretchTuningIO.kt`.
enum StretchTuningIO {
    
    // MARK: - Public API
    
    /// Serializes a list of stretch tunings to a string.
    static func stretchTuningsToString(_ stretchTunings: [StretchTuning]) -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        var output = "Version=\(version)\n\n"
        
        let tuningStrings = stretchTunings.map { getSingleStretchTuningString($0) }
        output += tuningStrings.joined(separator: "\n\n")
        
        return output
    }
    
    /// Parses stretch tunings from a text file/content.
    static func readFromContent(_ content: String) -> [StretchTuning] {
        // 1. Try Simple Format (Single line copy-paste style)
        // e.g. "MyPiano: A0 0.5 1.2 ..."
        if let simple = parseSingleLineSimpleFormat(content) {
            return [simple]
        }
        
        // 2. Try Standard Format
        let stream = SimpleStream(string: content)
        var tunings = [StretchTuning]()
        
        skipWhitespace(stream)
        if readKeyword(stream) == .version {
            consumeLine(stream)
        } else {
            stream.pos = 0
        }
        
        while stream.pos < stream.length {
            skipWhitespace(stream)
            if stream.pos >= stream.length { break }
            
            let keyword = readKeyword(stream)
            if keyword == .stretchTuning {
                if let tuning = readStretchTuning(stream) {
                    tunings.append(tuning)
                }
            } else {
                // Skip unknown garbage
                if stream.pos < stream.length { stream.pos += 1 }
            }
        }
        
        return tunings
    }
    
    static func read(from url: URL) -> [StretchTuning] {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return readFromContent(content)
        } catch {
            print("Failed to read stretch tuning file: \(error)")
            return []
        }
    }
    
    // MARK: - Private Parsing Logic (Standard Format)
    
    private static func getSingleStretchTuningString(_ tuning: StretchTuning) -> String {
        var sb = "StretchTuning\n"
        sb += "Name=\(tuning.name)\n"
        if !tuning.description.isEmpty {
            sb += "Description=\(tuning.description)\n"
        }
        
        // Unstretched Frequencies
        sb += "UnstretchedFrequencies=["
        sb += tuning.unstretchedFrequencies.map { String(format: "%.4f", $0) }.joined(separator: "; ")
        sb += "]\n"
        
        // Stretch Values
        sb += "StretchInCents=["
        sb += tuning.stretchInCents.map { String(format: "%.4f", $0) }.joined(separator: "; ")
        sb += "]"
        
        return sb
    }
    
    private static func readStretchTuning(_ stream: SimpleStream) -> StretchTuning? {
        var name = ""
        var description = ""
        var unstretchedFrequencies: [Double] = []
        var stretchInCents: [Double] = []
        
        while stream.pos < stream.length {
            skipWhitespace(stream)
            
            // Peek for next block
            if stream.startsWith("StretchTuning", at: stream.pos) {
                break
            }
            
            let keyword = readKeyword(stream)
            if keyword == .invalid {
                if stream.pos >= stream.length { break }
                break // Stop if we hit something unknown inside a block
            }
            
            switch keyword {
            case .name:
                if let val = readString(stream) { name = val }
            case .description:
                if let val = readString(stream) { description = val }
            case .unstretchedFrequencies:
                if let vals = readDoubleArray(stream) { unstretchedFrequencies = vals }
            case .stretchInCents:
                if let vals = readDoubleArray(stream) { stretchInCents = vals }
            default:
                break
            }
        }
        
        if !name.isEmpty && !unstretchedFrequencies.isEmpty && !stretchInCents.isEmpty {
            return StretchTuning(
                name: name,
                description: description,
                unstretchedFrequencies: unstretchedFrequencies,
                stretchInCents: stretchInCents,
                keys: nil,
                stableId: StretchTuning.NO_STABLE_ID
            )
        }
        return nil
    }
    
    // MARK: - Simple Format Parsing
    
    /// Parses a single line format: "Name: StartNote val1 val2 val3..."
    /// Example: "My Setting: A0 0.1 0.2 0.3"
    private static func parseSingleLineSimpleFormat(_ line: String) -> StretchTuning? {
        // Must contain colon
        let parts = line.split(separator: ":", maxSplits: 1).map { String($0) }
        guard parts.count == 2 else { return nil }
        
        let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let dataString = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Data should be space separated: "A0 0.0 0.1..."
        // Or comma separated? Kotlin replaces ',' with '.' and splits by whitespace.
        // Kotlin logic: values = line.substring(...).trim().split("\\s+".toRegex())
        
        let values = dataString.split(separator: " ").map { String($0) }
        guard !values.isEmpty else { return nil }
        
        // 1. Parse Start Note (e.g. "A0")
        guard let startNote = MusicalNote.fromString(values[0]) else { return nil }
        
        // 2. Setup 12-EDO Scale to calculate frequencies
        // We need a temporary 12-EDO scale to calculate the expected unstretched frequencies
        // starting from the startNote.
        let edo12Temperament = predefinedTemperamentEDO(12, 1)
        let edo12Scale = MusicalScale2(
            temperament: edo12Temperament,
            rootNote: nil,
            referenceNote: nil,
            referenceFrequency: DefaultValues.REFERENCE_FREQUENCY,
            frequencyMin: DefaultValues.FREQUENCY_MIN,
            frequencyMax: DefaultValues.FREQUENCY_MAX,
            stretchTuning: nil
        )
        
        // 3. Find index of start note in 12-EDO
        let startNoteIndex = edo12Scale.getNoteIndex2(note: startNote)
        if startNoteIndex == Int.max { return nil }
        
        // 4. Parse Cents and build arrays
        var frequencies = [Double]()
        var cents = [Double]()
        
        // Skip the note name (index 0), process rest
        for (i, valStr) in values.dropFirst().enumerated() {
            // Calculate frequency for this step
            let noteIndex = startNoteIndex + i
            let freq = Double(edo12Scale.getNoteFrequency(noteIndex: noteIndex))
            
            // Parse cent value (handle comma/dot)
            let sanitizedVal = valStr.replacingOccurrences(of: ",", with: ".")
            guard let centVal = Double(sanitizedVal) else { return nil }
            
            frequencies.append(freq)
            cents.append(centVal)
        }
        
        guard !frequencies.isEmpty else { return nil }
        
        return StretchTuning(
            name: name,
            description: "",
            unstretchedFrequencies: frequencies,
            stretchInCents: cents,
            keys: nil,
            stableId: StretchTuning.NO_STABLE_ID
        )
    }
    
    // MARK: - Helper Classes & Enums
    
    private enum Keyword {
        case version, stretchTuning, name, description, unstretchedFrequencies, stretchInCents, invalid
    }
    
    /// Helper for character stream parsing (Local copy of logic in InstrumentIO)
    private class SimpleStream {
        let chars: [Character]
        let length: Int
        var pos: Int = 0
        
        init(string: String) {
            self.chars = Array(string)
            self.length = self.chars.count
        }
        
        func startsWith(_ prefix: String, at index: Int) -> Bool {
            let prefixChars = Array(prefix)
            if index + prefixChars.count > length { return false }
            for i in 0..<prefixChars.count {
                if chars[index + i] != prefixChars[i] { return false }
            }
            return true
        }
        
        func substring(start: Int, end: Int) -> String? {
            guard start >= 0, end <= length, start <= end else { return nil }
            return String(chars[start..<end])
        }
    }
    
    // MARK: - Parser Helpers
    
    private static func readKeyword(_ stream: SimpleStream) -> Keyword {
        let map: [(String, Keyword)] = [
            ("Version=", .version),
            ("StretchTuning", .stretchTuning),
            ("Name=", .name),
            ("Description=", .description),
            ("UnstretchedFrequencies=", .unstretchedFrequencies),
            ("StretchInCents=", .stretchInCents)
        ]
        
        for (key, type) in map {
            if stream.startsWith(key, at: stream.pos) {
                stream.pos += key.count
                return type
            }
        }
        return .invalid
    }
    
    private static func skipWhitespace(_ stream: SimpleStream) {
        while stream.pos < stream.length {
            let c = stream.chars[stream.pos]
            if c.isWhitespace || c.isNewline {
                stream.pos += 1
            } else {
                break
            }
        }
    }
    
    private static func consumeLine(_ stream: SimpleStream) {
        while stream.pos < stream.length {
            if stream.chars[stream.pos].isNewline {
                stream.pos += 1
                break
            }
            stream.pos += 1
        }
    }
    
    private static func readString(_ stream: SimpleStream) -> String? {
        let start = stream.pos
        while stream.pos < stream.length && !stream.chars[stream.pos].isNewline {
            stream.pos += 1
        }
        guard let raw = stream.substring(start: start, end: stream.pos) else { return nil }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func readDoubleArray(_ stream: SimpleStream) -> [Double]? {
        skipWhitespace(stream)
        if stream.pos >= stream.length || stream.chars[stream.pos] != "[" { return nil }
        stream.pos += 1 // Eat '['
        
        let start = stream.pos
        while stream.pos < stream.length && stream.chars[stream.pos] != "]" && !stream.chars[stream.pos].isNewline {
            stream.pos += 1
        }
        
        if stream.pos >= stream.length || stream.chars[stream.pos] != "]" { return nil }
        
        guard let content = stream.substring(start: start, end: stream.pos) else { return nil }
        stream.pos += 1 // Eat ']'
        
        if content.trimmingCharacters(in: .whitespaces).isEmpty { return [] }
        
        let parts = content.split(separator: ";")
        return parts.compactMap { Double(String($0).trimmingCharacters(in: .whitespaces)) }
    }
}

// MARK: - Default Values Stub
// Replicating `misc/DefaultValues.kt` locally for this file's dependencies.

enum DefaultValues {
    static let REFERENCE_FREQUENCY: Float = 440.0
    static let FREQUENCY_MIN: Float = 10.0
    static let FREQUENCY_MAX: Float = 24000.0
}
