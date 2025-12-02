import Foundation

enum TemperamentValidityChecks {
    
    enum ValueOrdering {
        case increasing
        case unordered
        case undefined
    }
    
    enum NoteNameError {
        case none
        case undefined
        case duplicates
    }
    
    static func checkCentOrdering(numberOfNotes: Int, obtainCent: (Int) -> Double?) -> ValueOrdering {
        var lastVal = -Double.greatestFiniteMagnitude
        for i in 0..<numberOfNotes {
            guard let val = obtainCent(i) else { return .undefined }
            if val < lastVal { return .unordered }
            lastVal = val
        }
        return .increasing
    }
    
    static func checkNoteNameErrors(
        numberOfNotes: Int,
        obtainNote: (Int) -> MusicalNote?,
        duplicateNoteCallback: ((Int, Bool) -> Void)?
    ) -> NoteNameError {
        var error: NoteNameError = .none
        var isDuplicate = [Bool](repeating: false, count: numberOfNotes)
        
        // Don't check last note (octave)
        let count = max(0, numberOfNotes - 1)
        
        for i in 0..<count {
            guard let note = obtainNote(i) else {
                error = .undefined
                continue
            }
            
            for j in (i+1)..<count {
                guard let nextNote = obtainNote(j) else { continue }
                if note.match(nextNote, ignoreOctave: true) {
                    isDuplicate[i] = true
                    isDuplicate[j] = true
                    if error != .undefined { error = .duplicates }
                }
            }
        }
        
        if let callback = duplicateNoteCallback {
            for i in 0..<count {
                callback(i, isDuplicate[i])
            }
        }
        
        return error
    }
}
