import Foundation

/// Records audio to a circular buffer and writes WAV files.
///
/// Equivalent to `WaveWriter.kt`.
/// This class maintains a rolling buffer of the last N seconds of audio.
/// It uses an `actor` to ensure thread-safe access between the audio processing loop
/// (appending data) and the UI loop (writing files).
actor WaveWriter {
    
    // MARK: - State
    
    /// Circular buffer for audio samples.
    private var buffer: [Float]?
    
    /// Total number of samples written since reset (used to calculate write head).
    private var insertPosition: Int64 = 0
    
    /// Number of valid samples currently in the buffer.
    private var numValues: Int = 0
    
    /// A linear copy of the buffer taken at a specific moment for export.
    private var snapshot: [Float]?
    
    // MARK: - API
    
    /// Configures the buffer size.
    ///
    /// - Parameters:
    ///   - duration: The duration to record in seconds.
    ///   - sampleRate: The audio sample rate.
    func setDuration(duration: Float, sampleRate: Int) {
        let size = Int(duration * Float(sampleRate))
        
        // Only reallocate if size changed or buffer is missing
        if buffer == nil || buffer?.count != size {
            if size > 0 {
                buffer = [Float](repeating: 0.0, count: size)
            } else {
                buffer = nil
            }
            insertPosition = 0
            numValues = 0
            snapshot = nil
        }
    }
    
    /// Appends new audio data to the circular buffer.
    ///
    /// - Parameter input: Array of float audio samples.
    func appendData(_ input: [Float]) {
        guard let buffer = buffer, !buffer.isEmpty else { return }
        
        let inputSize = input.count
        let bufferSize = buffer.count
        
        // Logic to write into circular buffer
        var samplesToWrite = inputSize
        var inputOffset = 0
        
        while samplesToWrite > 0 {
            let writeIndex = Int(insertPosition % Int64(bufferSize))
            let spaceAtEnd = bufferSize - writeIndex
            let chunk = min(samplesToWrite, spaceAtEnd)
            
            // Copy chunk
            // Swift arrays are value types, but `replaceSubrange` is efficient.
            // For max performance, UnsafeMutableBufferPointer could be used,
            // but typical tuner buffer sizes are small enough for array slicing.
            for i in 0..<chunk {
                self.buffer?[writeIndex + i] = input[inputOffset + i]
            }
            
            insertPosition += Int64(chunk)
            inputOffset += chunk
            samplesToWrite -= chunk
        }
        
        numValues = min(numValues + inputSize, bufferSize)
    }
    
    /// Captures the current circular buffer state into a linear snapshot.
    func storeSnapshot() {
        guard let buffer = buffer, !buffer.isEmpty, numValues > 0 else {
            snapshot = nil
            return
        }
        
        var linearData = [Float](repeating: 0.0, count: numValues)
        let bufferSize = buffer.count
        
        // Calculate start position in circular buffer
        // If buffer is full, start is (insertPosition % size).
        // If not full, start is 0.
        // Actually, logic is: The *oldest* sample is at `(insertPosition - numValues) % size`
        
        // To unroll:
        // We start reading from `tail` and read `numValues` forward.
        // tail = (insertPosition - numValues)
        // Since insertPosition is monotonic, we handle modulo carefully.
        
        // Kotlin logic isn't shown fully in snippet for unrolling,
        // but standard circular buffer unrolling is:
        
        let tailIndex = (insertPosition - Int64(numValues)) % Int64(bufferSize)
        // Handle negative modulo result if any (though insertPosition increases)
        let startReadIndex = Int(tailIndex < 0 ? tailIndex + Int64(bufferSize) : tailIndex)
        
        // Two chunks: StartRead -> End, 0 -> Remaining
        let firstChunkSize = min(numValues, bufferSize - startReadIndex)
        let secondChunkSize = numValues - firstChunkSize
        
        // Copy Part 1
        for i in 0..<firstChunkSize {
            linearData[i] = buffer[startReadIndex + i]
        }
        
        // Copy Part 2 (Wrap around)
        if secondChunkSize > 0 {
            for i in 0..<secondChunkSize {
                linearData[firstChunkSize + i] = buffer[i]
            }
        }
        
        snapshot = linearData
    }
    
    /// Writes the stored snapshot to a WAV file.
    ///
    /// - Parameters:
    ///   - url: The file URL to write to.
    ///   - sampleRate: The sample rate for the header.
    /// - Returns: Validation result of the operation.
    func writeStoredSnapshot(url: URL, sampleRate: Int) -> FileCheck {
        guard let data = snapshot, !data.isEmpty else {
            return .empty
        }
        
        do {
            let fileData = createWavFile(samples: data, sampleRate: sampleRate)
            try fileData.write(to: url)
            return .ok
        } catch {
            print("WaveWriter: Failed to write WAV file: \(error)")
            return .invalid
        }
    }
    
    // MARK: - Private Helper: WAV Encoding
    
    private func createWavFile(samples: [Float], sampleRate: Int) -> Data {
        var data = Data()
        
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 32
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample) / 8)
        let blockAlign = Int16(Int(numChannels) * Int(bitsPerSample) / 8)
        let dataSize = Int32(samples.count * Int(bitsPerSample) / 8)
        
        // Total chunk size: 36 + dataSize
        // (4 bytes WAVE + 26 bytes fmt + 8 bytes data header + dataSize)
        // Note: Kotlin snippet uses specific sizes:
        // "WAVE" (4)
        // "fmt " (4)
        // Subchunk1Size (4) -> 18
        // AudioFormat (2) -> 3 (Float)
        // NumChannels (2)
        // SampleRate (4)
        // ByteRate (4)
        // BlockAlign (2)
        // BitsPerSample (2)
        // ExtensionSize (2) -> 0
        // "data" (4)
        // DataSize (4)
        // = 4 + 4 + 4 + 18 + 4 + 4 = 38 bytes + 8 (data chunk header) = 46 bytes relative to "WAVE" start?
        // Standard PCM Header is 44 bytes. IEEE Float with extension is usually larger.
        
        let totalFileSize = 36 + dataSize + 2 // +2 for the extra extension size word
        
        // 1. RIFF Chunk Descriptor
        data.append(string: "RIFF")
        data.append(int32: Int32(totalFileSize))
        data.append(string: "WAVE")
        
        // 2. fmt Sub-chunk
        data.append(string: "fmt ")
        data.append(int32: 18)          // Subchunk1Size (18 for IEEE Float)
        data.append(int16: 3)           // AudioFormat (3 = IEEE Float)
        data.append(int16: numChannels)
        data.append(int32: Int32(sampleRate))
        data.append(int32: byteRate)
        data.append(int16: blockAlign)
        data.append(int16: bitsPerSample)
        data.append(int16: 0)           // cbSize (Size of extension)
        
        // 3. data Sub-chunk
        data.append(string: "data")
        data.append(int32: dataSize)
        
        // 4. Data
        // Convert Floats to bytes (Little Endian)
        for sample in samples {
            // IEEE 754 Float bit pattern
            data.append(float: sample)
        }
        
        return data
    }
}

// MARK: - Binary Writing Helpers

private extension Data {
    mutating func append(string: String) {
        if let data = string.data(using: .ascii) {
            append(data)
        }
    }
    
    mutating func append(int32: Int32) {
        var value = int32.littleEndian
        withUnsafeBytes(of: &value) { append($0) }
    }
    
    mutating func append(int16: Int16) {
        var value = int16.littleEndian
        withUnsafeBytes(of: &value) { append($0) }
    }
    
    mutating func append(float: Float) {
        // Float doesn't have a built-in .littleEndian property,
        // but bitPattern does.
        var value = float.bitPattern.littleEndian
        withUnsafeBytes(of: &value) { append($0) }
    }
}
