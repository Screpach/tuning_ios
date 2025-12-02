import Foundation

/// Handles the Import/Export of instruments to a custom text format.
///
/// Equivalent to `InstrumentIO.kt`.
enum InstrumentIO {
    
    // MARK: - Public API
    
    /// Serializes a list of instruments to a string.
    static func instrumentsListToString(instruments: [Instrument]) -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        
        var output = "Version=\(version)\n\n"
        
        let instrumentStrings = instruments.map { getSingleInstrumentString($0) }
        output += instrumentStrings.joined(separator: "\n\n")
        
        return output
    }
    
    /// Parses instruments from a text file/content.
    ///
    /// - Parameter content: The raw string content of the file.
    /// - Returns: A list of parsed instruments.
    static func readFromContent(_ content: String) -> [Instrument] {
        let stream = SimpleStream(string: content)
        var instruments = [Instrument]()
        
        // Check version (logic ported from Kotlin)
        skipWhitespace(stream)
        if readKeyword(stream) == .version {
            // We just read "Version", now skip the value (e.g. "=1.0")
            // The original code reads the line or just continues.
            // Based on Kotlin logic: `readString(stream)` isn't called for version value here,
            // it seems it just skips the keyword and parses freely?
            // Let's look closely at Kotlin:
            // It calls `readKeyword`, if Version, it continues loop.
            // It actually relies on `readString` or similar to skip the value if it was a property.
            // However, `Version=` is just a header. Let's consume until newline to be safe.
            consumeLine(stream)
        } else {
            // Reset if no version found (optional, Kotlin didn't explicitly reset, just continued)
            stream.pos = 0
        }
        
        while stream.pos < stream.length {
            skipWhitespace(stream)
            if stream.pos >= stream.length { break }
            
            let keyword = readKeyword(stream)
            if keyword == .instrument {
                if let instrument = readInstrument(stream) {
                    instruments.append(instrument)
                }
            } else {
                // If we hit unknown text, skip to next likely start or just stop to avoid infinite loop
                if stream.pos < stream.length {
                   stream.pos += 1
                }
            }
        }
        
        return instruments
    }
    
    /// Helper to read from a URL (e.g., file import).
    static func read(from url: URL) -> [Instrument] {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return readFromContent(content)
        } catch {
            print("Failed to read instrument file: \(error)")
            return []
        }
    }
    
    // MARK: - Private Serialization Logic
    
    private static func getSingleInstrumentString(_ instrument: Instrument) -> String {
        var sb = "Instrument\n"
        
        // Name
        // In export, we prefer the resolved name or raw name.
        // Android used `instrument.getNameString(context)`.
        let exportedName = instrument.getNameString()
        sb += "Name=\(exportedName)\n"
        
        // Icon
        sb += "Icon=\(instrument.icon.rawValue)\n"
        
        // Strings
        sb += "Strings=["
        let noteStrings = instrument.strings.map { note in
            // Reconstruct string format: "A4", "A#4"
            // Assuming MusicalNote stub has simple properties.
            // We need a specific format for the parser: Base + Modifier + Octave
            let modStr = (note.modifier == .sharp) ? "#" : (note.modifier == .flat ? "b" : "")
            return "\(note.base.rawValue)\(modStr)\(note.octave)"
        }
        sb += noteStrings.joined(separator: "; ")
        sb += "]"
        
        return sb
    }
    
    // MARK: - Private Parsing Logic
    
    private enum Keyword {
        case version, instrument, nameLength, name, icon, strings, invalid
    }
    
    /// A helper class to track parsing position.
    /// Uses [Character] array for efficient random access (Swift String indices are opaque).
    private class SimpleStream {
        let chars: [Character]
        let length: Int
        var pos: Int = 0
        
        init(string: String) {
            self.chars = Array(string)
            self.length = self.chars.count
        }
        
        // Helper to get string slice from current context
        func substring(start: Int, end: Int) -> String? {
            guard start >= 0, end <= length, start <= end else { return nil }
            return String(chars[start..<end])
        }
        
        func startsWith(_ prefix: String, at index: Int) -> Bool {
            let prefixChars = Array(prefix)
            if index + prefixChars.count > length { return false }
            for i in 0..<prefixChars.count {
                if chars[index + i] != prefixChars[i] { return false }
            }
            return true
        }
    }
    
    private static func readInstrument(_ stream: SimpleStream) -> Instrument? {
        var name: String = ""
        var icon: InstrumentIcon = .guitar // Default
        var strings: [MusicalNote] = []
        var stableId: Int64 = -1 // Will be generated later or unused
        
        // Loop until we hit end or start of next instrument
        while stream.pos < stream.length {
            skipWhitespace(stream)
            
            // Peek for next Instrument keyword to break early
            if stream.startsWith("Instrument", at: stream.pos) {
                // If we are already inside readInstrument and see "Instrument",
                // it means we finished the current one.
                break
            }
            
            let keyword = readKeyword(stream)
            if keyword == .invalid {
                // Determine if we are done or just hitting garbage
                if stream.pos >= stream.length { break }
                // If we didn't match a keyword, maybe we should break?
                // The Kotlin code continues loop inside readInstrument until properties are done.
                // If readKeyword returns invalid, it didn't advance stream?
                // Actually Kotlin `readKeyword` advances if match found.
                // If no match, we must ensure we don't infinite loop.
                break
            }
            
            switch keyword {
            case .name:
                if let val = readString(stream) { name = val }
            case .nameLength:
                // Deprecated format support
                if let len = readInt(stream), let val = readString(stream, length: len) {
                    name = val
                }
            case .icon:
                if let val = readString(stream) {
                    // Parse Enum
                    if let parsedIcon = InstrumentIcon(rawValue: val) {
                        icon = parsedIcon
                    }
                }
            case .strings:
                if let notes = readMusicalNoteArray(stream) {
                    strings = notes
                }
            default:
                break
            }
        }
        
        if !name.isEmpty && !strings.isEmpty {
            // Note: Imported instruments don't have a resource ID.
            return Instrument(
                name: name,
                nameResource: nil,
                strings: strings,
                icon: icon,
                stableId: Instrument.NO_STABLE_ID
            )
        }
        
        return nil
    }
    
    private static func readKeyword(_ stream: SimpleStream) -> Keyword {
        // Kotlin: checks prefixes like "Version=", "Name="
        // and advances stream if matched.
        
        let map: [(String, Keyword)] = [
            ("Version=", .version),
            ("Instrument", .instrument),
            ("Length of name=", .nameLength),
            ("Name=", .name),
            ("Icon=", .icon),
            ("Strings=", .strings)
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
            // Kotlin: string[pos] <= ' '
            if c.isWhitespace || c.isNewline || c.asciiValue ?? 255 <= 32 {
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
    
    private static func readInt(_ stream: SimpleStream) -> Int? {
        skipWhitespace(stream)
        let start = stream.pos
        var end = start
        
        // Consume digits and optional sign
        if end < stream.length && (stream.chars[end] == "+" || stream.chars[end] == "-") {
            end += 1
        }
        while end < stream.length && stream.chars[end].isNumber {
            end += 1
        }
        
        if start == end { return nil }
        
        guard let sub = stream.substring(start: start, end: end),
              let value = Int(sub) else {
            return nil
        }
        
        stream.pos = end
        return value
    }
    
    /// Read string until newline
    private static func readString(_ stream: SimpleStream) -> String? {
        // Kotlin logic: reads until newline.
        // Trim whitespace? Kotlin: `string.substring(...).trim()`
        
        // Logic: Skip leading whitespace? Kotlin `readInt` does, but `readString`?
        // Kotlin implementation:
        // val posStart = pos
        // while(pos < length && string[pos] != '\n') ++pos
        // return string.substring(posStart, pos).trim()
        
        let start = stream.pos
        while stream.pos < stream.length && !stream.chars[stream.pos].isNewline {
            stream.pos += 1
        }
        
        guard let raw = stream.substring(start: start, end: stream.pos) else { return nil }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Read string of fixed length (Legacy format)
    private static func readString(_ stream: SimpleStream, length: Int) -> String? {
        skipWhitespace(stream) // Usually there is a space after "Length of name=5 "
        
        if stream.pos + length > stream.length { return nil }
        let str = stream.substring(start: stream.pos, end: stream.pos + length)
        stream.pos += length
        return str
    }
    
    private static func readMusicalNoteArray(_ stream: SimpleStream) -> [MusicalNote]? {
        skipWhitespace(stream)
        
        // Expect '['
        if stream.pos >= stream.length || stream.chars[stream.pos] != "[" {
            return nil
        }
        stream.pos += 1 // Eat '['
        
        let start = stream.pos
        // Find ']'
        while stream.pos < stream.length && stream.chars[stream.pos] != "]" && !stream.chars[stream.pos].isNewline {
            stream.pos += 1
        }
        
        if stream.pos >= stream.length || stream.chars[stream.pos] != "]" {
            return nil // Malformed, no closing bracket
        }
        
        guard let content = stream.substring(start: start, end: stream.pos) else { return nil }
        
        stream.pos += 1 // Eat ']'
        
        if content.trimmingCharacters(in: .whitespaces).isEmpty {
            return []
        }
        
        // Split by ';' and parse
        let parts = content.split(separator: ";")
        let notes = parts.compactMap { parseMusicalNote(String($0).trimmingCharacters(in: .whitespaces)) }
        
        return notes
    }
    
    // MARK: - Musical Note Parser Helper
    // Since MusicalNote.kt hasn't been provided yet, we implement the parser logic here
    // to match the format: "A#4", "Cb5", "E2"
    
    private static func parseMusicalNote(_ raw: String) -> MusicalNote? {
        // Simple regex-less parser
        // Format: [Base][Modifier][Octave]
        // Examples: C4, C#4, Db4
        
        guard !raw.isEmpty else { return nil }
        let chars = Array(raw)
        
        // 1. Base Note
        let baseStr = String(chars[0])
        guard let base = BaseNote(rawValue: baseStr) else { return nil }
        
        var index = 1
        var modifier: NoteModifier = .none
        
        // 2. Modifier (Optional)
        if index < chars.count {
            let c = chars[index]
            if c == "#" {
                modifier = .sharp
                index += 1
            } else if c == "b" {
                modifier = .flat
                index += 1
            }
        }
        
        // 3. Octave
        if index < chars.count {
            let octaveStr = String(chars[index..<chars.count])
            if let octave = Int(octaveStr) {
                return MusicalNote(base, modifier, octave)
            }
        }
        
        // If parsing octave failed or missing
        return nil
    }
}
