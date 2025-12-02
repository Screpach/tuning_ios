import Foundation

/// A generic memory pool for managing reusable objects.
///
/// Equivalent to `MemoryPool.kt`.
/// This is particularly useful for audio buffers where frequent allocation/deallocation
/// would cause performance hitches (GC pauses in Kotlin, or malloc overhead in Swift).
class MemoryPool<T>: Sendable {
    
    // MARK: - Configuration
    
    private let capacity: Int
    
    // MARK: - State
    
    // Thread-safe storage for recycled objects.
    // We use a simple array protected by a lock because access must be synchronous and fast.
    private let lock = NSLock()
    private var availableItems: [T] = []
    
    // MARK: - Initialization
    
    /// Creates a new memory pool.
    /// - Parameter capacity: The maximum number of recycled items to hold. Defaults to 20.
    init(capacity: Int = 20) {
        self.capacity = capacity
        // Pre-reserve capacity to avoid array resizing overhead
        self.availableItems.reserveCapacity(capacity)
    }
    
    // MARK: - API
    
    /// Obtain a ref-counted memory object.
    ///
    /// - Parameters:
    ///   - factory: Closure to create a new instance if the pool is empty or no item matches criteria.
    ///   - checker: Closure to validate if a recycled item is suitable (e.g., correct buffer size).
    /// - Returns: A `RefCountedMemory` wrapper containing the object.
    func get(factory: () -> T, checker: (T) -> BooleanLiteralType) -> RefCountedMemory<T> {
        var validItem: T? = nil
        
        lock.lock()
        // Iterate backwards to find a match (LIFO-ish, or just linear scan)
        // Kotlin implementation uses a Channel which acts like a Queue,
        // but it checks *one* item. If it fails, it discards it?
        // Kotlin `get`:
        // while(true) { memory = channel.tryReceive(); if(memory == null || checker(memory)) break }
        // This implies if checker fails, the item is DROPPED (not put back).
        
        // We replicate that behavior: pop items until one passes check or empty.
        while let item = availableItems.popLast() {
            if checker(item) {
                validItem = item
                break
            }
            // If check fails, 'item' is dropped (deallocated)
        }
        lock.unlock()
        
        if let reused = validItem {
            // Log.v("Tuner", "Recycling memory")
            return RefCountedMemory(memory: reused, pool: self)
        } else {
            // Log.v("Tuner", "Allocating new memory")
            return RefCountedMemory(memory: factory(), pool: self)
        }
    }
    
    // MARK: - Internal
    
    fileprivate func recycle(_ item: T) {
        lock.lock()
        defer { lock.unlock() }
        
        if availableItems.count < capacity {
            availableItems.append(item)
        }
        // If full, the item is implicitly deallocated when this scope ends
    }
}

/// A wrapper around a pooled object that supports manual reference counting.
///
/// Equivalent to `MemoryPool.RefCountedMemory`.
class RefCountedMemory<T>: Sendable {
    
    // MARK: - Properties
    
    /// The underlying pooled object.
    let memory: T
    
    private let pool: MemoryPool<T>
    
    // Atomic reference counter
    // Using simple lock for thread safety on the counter.
    private let refLock = NSLock()
    private var refCount: Int = 1
    
    // MARK: - Initialization
    
    fileprivate init(memory: T, pool: MemoryPool<T>) {
        self.memory = memory
        self.pool = pool
    }
    
    // MARK: - Reference Counting
    
    /// Increment the reference count.
    func incRef() {
        refLock.lock()
        refCount += 1
        refLock.unlock()
    }
    
    /// Decrement the reference count.
    /// If the count reaches zero, the underlying memory is returned to the pool.
    func decRef() {
        var shouldRecycle = false
        
        refLock.lock()
        refCount -= 1
        if refCount <= 0 {
            shouldRecycle = true
            // Reset to 0 just in case
            refCount = 0
        }
        refLock.unlock()
        
        if shouldRecycle {
            pool.recycle(memory)
        }
    }
}
