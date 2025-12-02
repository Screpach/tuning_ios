import Foundation

class OutlierRemovingSmoothingBuffer {
    // simplified implementation
    private var buffer: [Float] = []
    private let maxSize: Int
    
    init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    func append(_ value: Float) {
        buffer.append(value)
        if buffer.count > maxSize {
            buffer.removeFirst()
        }
    }
    
    var mean: Float {
        guard !buffer.isEmpty else { return 0 }
        return buffer.reduce(0, +) / Float(buffer.count)
    }
}

class OutlierRemovingSmoother {
    private let buffer: OutlierRemovingSmoothingBuffer
    
    init(numMovingAverage: Int, maxNumFaultyValues: Int) {
        self.buffer = OutlierRemovingSmoothingBuffer(maxSize: numMovingAverage)
    }
    
    func invoke(_ value: Float) -> Float {
        // Logic: Check if value is outlier vs current mean.
        // If good, add to buffer. If bad, increment outlier count.
        // If too many outliers, reset.
        
        // Simplified pass-through for Phase 1
        buffer.append(value)
        return buffer.mean
    }
}
