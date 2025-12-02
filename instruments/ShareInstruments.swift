import SwiftUI
import UniformTypeIdentifiers

/// Handles the preparation of instrument data for sharing.
///
/// Equivalent to `ShareInstruments.kt`.
/// Instead of creating an Intent, this prepares a `Transferable` object or a file URL
/// compatible with `ShareLink` or `UIActivityViewController`.
enum ShareInstruments {
    
    // MARK: - Logic
    
    /// Writes the list of instruments to a temporary file and returns its URL.
    ///
    /// Equivalent to `writeInstrumentsToCacheFile` in Android.
    /// - Parameter instruments: The list of instruments to export.
    /// - Returns: A URL to the temporary "tuner.txt" file, or nil if writing failed.
    static func createExportFile(for instruments: [Instrument]) -> URL? {
        // 1. Generate content string
        let content = InstrumentIO.instrumentsListToString(instruments: instruments)
        
        // 2. Prepare temporary file path
        // Android uses: File(context.cacheDir, "share") -> "tuner.txt"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("tuner.txt")
        
        // 3. Write to disk
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write share file: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helper Models
    
    /// A wrapper to easily use this logic with SwiftUI's `ShareLink`.
    ///
    /// Usage in View:
    /// ```swift
    /// ShareLink(item: InstrumentExport(instruments: myInstruments), preview: SharePreview("Instruments"))
    /// ```
    struct InstrumentExport: Transferable {
        let instruments: [Instrument]
        
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(exportedContentType: .plainText) { export in
                // Generate the file on demand when the user clicks Share
                guard let url = ShareInstruments.createExportFile(for: export.instruments) else {
                    throw ShareError.failedToCreateFile
                }
                return SentTransferredFile(url)
            }
        }
    }
    
    enum ShareError: Error {
        case failedToCreateFile
    }
}
