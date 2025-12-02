import Foundation
import AVFoundation

/// Generates sound samples from the microphone.
///
/// Replaces Kotlin's `launchSoundSourceJob`.
/// Uses `AVAudioEngine` to tap the microphone node.
class SoundSource: ObservableObject {
    
    private let audioEngine = AVAudioEngine()
    private let outputStream: AsyncStream<SampleData>
    private let outputContinuation: AsyncStream<SampleData>.Continuation
    
    // Buffer configuration
    private let windowSize: Int
    private let overlap: Float
    
    init(windowSize: Int = 4096, overlap: Float = 0.25) {
        self.windowSize = windowSize
        self.overlap = overlap
        
        var continuation: AsyncStream<SampleData>.Continuation!
        self.outputStream = AsyncStream { continuation = $0 }
        self.outputContinuation = continuation
    }
    
    func start() throws -> AsyncStream<SampleData> {
        let inputNode = audioEngine.inputNode
        let bus = 0
        let format = inputNode.outputFormat(forBus: bus)
        let sampleRate = Int(format.sampleRate)
        
        // Install Tap
        // Note: bufferSize in installTap is a hint. We must handle arbitrary sizes.
        inputNode.installTap(onBus: bus, bufferSize: AVAudioFrameCount(windowSize), format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Convert AudioBuffer to [Float]
            // buffer.floatChannelData?[0] gives UnsafePointer<Float>
            guard let floatData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            let array = Array(UnsafeBufferPointer(start: floatData, count: frameCount))
            
            // Create SampleData wrapper
            // In a real impl, we'd slice this based on windowSize/overlap logic similar to Kotlin
            // For Phase 1, we yield raw chunks.
            
            let sampleData = SampleData(size: frameCount, sampleRate: sampleRate, framePosition: Int(time.sampleTime))
            sampleData.addData(inputFramePosition: Int(time.sampleTime), input: array)
            
            self.outputContinuation.yield(sampleData)
        }
        
        try audioEngine.start()
        return outputStream
    }
    
    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        outputContinuation.finish()
    }
}
