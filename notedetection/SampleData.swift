import Foundation

/// Class which collects sample data.
/// Equivalent to `SampleData.kt`.
class SampleData: Sendable {
    let size: Int
    let sampleRate: Int
    var framePosition: Int
    
    var data: [Float]
    var minLevel: Int = Int.max
    var maxLevel: Int = 0
    
    // Back-ref for pooling
    var memory: MemoryPool<SampleData>?
    
    init(size: Int, sampleRate: Int, framePosition: Int) {
        self.size = size
        self.sampleRate = sampleRate
        self.framePosition = framePosition
        self.data = [Float](repeating: 0.0, count: size)
    }
    
    var isFull: Bool {
        return minLevel == 0 && maxLevel == size
    }
    
    func addData(inputFramePosition: Int, input: [Float]) {
        let startIndexData = max(0, inputFramePosition - framePosition)
        let startIndexInput = max(0, framePosition - inputFramePosition)
        
        let numCopy = min(size - startIndexData, input.count - startIndexInput)
        
        if numCopy > 0 {
            for i in 0..<numCopy {
                data[startIndexData + i] = input[startIndexInput + i]
            }
            maxLevel = max(maxLevel, startIndexData + numCopy)
            minLevel = min(minLevel, startIndexData)
        }
    }
    
    func decRef() {
        // memory?.recycle(self)
    }
}
