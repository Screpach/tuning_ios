import SwiftUI
import UniformTypeIdentifiers

/// Utilities for sharing generic data as files.
///
/// Equivalent to `ShareData.kt`.
/// Handles the creation of temporary files and provides `Transferable` wrappers
/// for use with SwiftUI's `ShareLink`.
enum ShareData {
    
    // MARK: - Logic
    
    /// Writes string data to a temporary file and returns its URL.
    ///
    /// Equivalent to `writeDataToCacheFile` in Android.
    /// - Parameters:
    ///   - filename: The name of the file (e.g., "tuner_settings.txt").
    ///   - content: The string data to write.
    /// - Returns: A URL to the temporary file, or nil if writing failed.
    static func createTemporaryFile(filename: String, content: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("ShareData: Failed to write file '\(filename)': \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Generic Transferable
    
    /// A generic wrapper to share any string content as a file via `ShareLink`.
    ///
    /// Usage:
    /// ```swift
    /// ShareLink(
    ///     item: ShareData.GenericExport(filename: "my_data.txt", content: "Hello World"),
    ///     preview: SharePreview("Export Data")
    /// )
    /// ```
    struct GenericExport: Transferable {
        let filename: String
        let content: String
        let mimeType: UTType
        
        init(filename: String, content: String, mimeType: UTType = .plainText) {
            self.filename = filename
            self.content = content
            self.mimeType = mimeType
        }
        
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(exportedContentType: .plainText) { export in
                guard let url = ShareData.createTemporaryFile(filename: export.filename, content: export.content) else {
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
