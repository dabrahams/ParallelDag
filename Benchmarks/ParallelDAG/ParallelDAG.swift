#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Windows)
import ucrt
import WinSDK
#else
import Glibc
#endif

// SHAMELESSLY LIFTED FROM SwiftNIO
// https://github.com/apple/swift-nio/blob/0467886d0b21599fdf011cd9a89c5c593dd650a7/Sources/NIOConcurrencyHelpers/lock.swift#L30-L53

/// A threading lock based on `libpthread` instead of `libdispatch`.
///
/// This object provides a lock on top of a single `pthread_mutex_t`. This kind
/// of lock is safe to use with `libpthread`-based threading models, such as the
/// one used by NIO. On Windows, the lock is based on the substantially similar
/// `SRWLOCK` type.
public final class Lock: @unchecked Sendable {
#if os(Windows)
    fileprivate let mutex: UnsafeMutablePointer<SRWLOCK> =
        UnsafeMutablePointer.allocate(capacity: 1)
#else
    fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t> =
        UnsafeMutablePointer.allocate(capacity: 1)
#endif

    /// Create a new lock.
    public init() {
#if os(Windows)
        InitializeSRWLock(self.mutex)
#else
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
//        debugOnly {
//            pthread_mutexattr_settype(&attr, .init(PTHREAD_MUTEX_ERRORCHECK))
//        }

        let err = pthread_mutex_init(self.mutex, &attr)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
#endif
    }

    deinit {
#if os(Windows)
        // SRWLOCK does not need to be free'd
#else
        let err = pthread_mutex_destroy(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
#endif
        mutex.deallocate()
    }

    /// Acquire the lock.
    ///
    /// Whenever possible, consider using `withLock` instead of this method and
    /// `unlock`, to simplify lock handling.
    public func lock() {
#if os(Windows)
        AcquireSRWLockExclusive(self.mutex)
#else
        let err = pthread_mutex_lock(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
#endif
    }

    /// Release the lock.
    ///
    /// Whenver possible, consider using `withLock` instead of this method and
    /// `lock`, to simplify lock handling.
    public func unlock() {
#if os(Windows)
        ReleaseSRWLockExclusive(self.mutex)
#else
        let err = pthread_mutex_unlock(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
#endif
    }
}

extension Lock {
    /// Acquire the lock for the duration of the given block.
    ///
    /// This convenience method should be preferred to `lock` and `unlock` in
    /// most situations, as it ensures that the lock will be released regardless
    /// of how `body` exits.
    ///
    /// - Parameter body: The block to execute while holding the lock.
    /// - Returns: The value returned by the block.
    @inlinable
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }

    // specialise Void return (for performance)
    @inlinable
    public func withLockVoid(_ body: () throws -> Void) rethrows -> Void {
        try self.withLock(body)
    }
}

import Benchmark
import Foundation

extension Dictionary {
  func mapValuesAsync<R>(_ transform: @Sendable (Value) async -> R) async -> [Key: R] {
    var result = Dictionary<Key, R>(minimumCapacity: capacity)
    for (key, value) in self {
      result[key] = await transform(value)
    }
    return result
  }

  mutating func getOrCreate(_ key: Key, factory: () -> Value) -> Value {
    return { (x: inout Value)->Value in x }(
      &self[key, default: factory()]
    )
  }
}

actor Tasks {
  private var r: [Int: Task<Int, Never>] = [:]

  var result: [Int: Int] {
    get async {
      await r.mapValuesAsync { task in
        await task.value
      }
    }
  }

  init(_ input: [Int]) async {
    let initialTasks = input.map(fib)
    for task in initialTasks {
      // wait for the requested inputs
      _ = await task.value
    }
    // at this point all additional computations are done
  }

  private func fib(_ x: Int) -> Task<Int, Never> {
    let r1 = r.getOrCreate(x) {
      Task.detached {
        let result = x < 2 ? 1 :
          await self.fib(x - 1).value + self.fib(x - 2).value
        return result
      }
    }
    return r1
  }
}

class Op: Operation {
  let x: Int
  var result = 0
  var d1: Op!
  var d2: Op!

  init(_ x: Int, in ops: Operations) async {
    self.x = x
    super.init()
    if x >= 2 {
      d1 = await ops.fib(x - 1)
      d2 = await ops.fib(x - 2)
      self.addDependency(d1)
      self.addDependency(d2)
    }
  }

  override func main() {
    result = x < 2 ? 1 : d1.result + d2.result
  }
}

actor Operations {
  private var r: [Int: Op] = [:]
  private let q = OperationQueue()

  var result: [Int: Int] {
    get {
      return r.mapValues { op in
        op.waitUntilFinished()
        return op.result
      }
    }
  }

  init(_ input: [Int]) async {
    for x in input {
      let op = await Op(x, in: self)
      r[x] = op
      q.addOperation(op)
    }
  }

  func fib(_ x: Int) async -> Op {
    if let o = r[x] { return o }
    let r1 = await Op(x, in: self)
    r[x] = r1
    q.addOperation(r1)
    return r1
  }
}

actor Cache {
  var r: [Int: Task<Int, Never>] = [:]

  func update(key: Int, with value: Task<Int, Never>) {
    self.r[key] = value
  }

  func getOrCreate(_ x: Int, factory: @escaping () async->Int) -> Task<Int, Never> {
    r.getOrCreate(x) {
      Task.detached {
        await factory()
      }
    }
  }
}

func compute(_ input: [Int]) async -> [Int: Int] {
    let cache = Cache()

    @Sendable
    @discardableResult
    func fib(_ x: Int, cache: Cache) async -> Task<Int, Never> {
      await cache.getOrCreate(x) {
        x < 2 ? 1 : await fib(x - 1, cache: cache).value + fib(x - 2, cache: cache).value
      }
    }

    for x in input { _ = await fib(x, cache: cache) }
    return await cache.r.mapValuesAsync { await $0.value }
}


final class MutexCache: @unchecked Sendable {

  private let mutex = Lock()

  private var _r: [Int: Task<Int,Never>] = [:]

  func getOrCreate(_ x: Int, factory: @escaping () async->Int) -> Task<Int, Never> {
    mutex.withLock {
      _r.getOrCreate(x, factory: { Task.detached { await factory() } })
    }
  }

  func read() -> [Int: Task<Int,Never>] {
    mutex.withLock { _r }
  }
}

func mutexCompute(_ input: [Int]) async -> [Int: Int] {
    let cache = MutexCache()

    @Sendable
    @discardableResult
    func fib(_ x: Int) async -> Task<Int,Never> {
      cache.getOrCreate(x) {
        x < 2 ? 1 : await fib(x - 1).value + fib(x - 2).value
      }
    }

    for x in input { _ = await fib(x) }
    return await cache.read().mapValuesAsync { await $0.value }
}

import os

func osAllocatedUnfairLockCompute(_ input: [Int]) async -> [Int: Int] {
  let cache = os.OSAllocatedUnfairLock(uncheckedState: [Int: Task<Int, Never>]())

    @Sendable
    @discardableResult
    func fib(_ x: Int) async -> Task<Int,Never> {
      cache.withLock {
        $0.getOrCreate(x) {
          Task.detached {
            x < 2 ? 1 : await fib(x - 1).value + fib(x - 2).value
          }
        }
      }
    }

    for x in input { _ = await fib(x) }
    return await cache.withLock { $0 }.mapValuesAsync { await $0.value }
}





let benchmarks = {

  #if false
  // A hack to validate that all are computing the same result.
  Benchmark("assertions") { b in
    let tasks = await Tasks([2, 10, 15, 6, 20, 91, 4, 5]).result.sorted(by: <)
    let operations = await Operations([2, 10, 15, 6, 20, 91, 4, 5]).result.sorted(by: <)
    let jaleel = await compute([2, 10, 15, 6, 20, 91, 4, 5]).sorted(by: <)

    if (!tasks.elementsEqual(operations, by: ==)) { fatalError("mismatch")}
    if (!operations.elementsEqual(jaleel, by: ==))  { fatalError("mismatch")}
  }
  #endif

  Benchmark("Tasks") { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(await Tasks([2, 10, 15, 6, 20, 91, 4, 5]).result)
    }
  }

  Benchmark("Operations") { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(await Operations([2, 10, 15, 6, 20, 91, 4, 5]).result)
    }
  }

  Benchmark("ActorBasedTaskCache") { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(await compute([2, 10, 15, 6, 20, 91, 4, 5]))
    }
  }

  Benchmark("MutexBasedTaskCache") { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(await mutexCompute([2, 10, 15, 6, 20, 91, 4, 5]))
    }
  }

  Benchmark("OSAllocatedUnfairLockBasedTaskCache") { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(await osAllocatedUnfairLockCompute([2, 10, 15, 6, 20, 91, 4, 5]))
    }
  }
}
