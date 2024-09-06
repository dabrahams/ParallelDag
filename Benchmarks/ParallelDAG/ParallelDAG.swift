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
    for x in input { await q.addOperation(Op(x, in: self)) }
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
    var r: [Int: Int] = [:]

    func update(key: Int, with value: Int) {
        self.r[key] = value
    }
}

func compute(_ input: [Int]) async -> [Int: Int] {
    let cache = Cache()

    @discardableResult
    func fib(_ x: Int, cache: Cache) async -> Int {
        if let y = await cache.r[x] { return y }
        let y = await x < 2 ? 1 : fib(x - 1, cache: cache) + fib(x - 2, cache: cache)
        await cache.update(key: x, with: y)
        return y
    }

    return await withTaskGroup(of: Void.self, returning: [Int: Int].self) { group in
        for z in input {
            group.addTask {
                await fib(z, cache: cache)
            }
        }
        await group.waitForAll()
        return await cache.r
    }
}

let benchmarks = {

  /* A hack to validate that both are computing the result.
   Benchmark("Nothing") { benchmark in
   let x0 = await Tasks([2, 10, 15, 6, 20, 91, 4, 5]).result.sorted {$0.key < $1.key}
   let x1 = await Operations([2, 10, 15, 6, 20, 91, 4, 5]).result.sorted {$0.key < $1.key}
   assert(x0.elementsEqual(x1, by: ==))
   }
   */

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

    Benchmark("Jaleel") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(await compute([2, 10, 15, 6, 20, 91, 4, 5]))
      }
    }
}
