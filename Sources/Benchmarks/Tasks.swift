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
//  private var clock = 0

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
    let t = clock
//    clock += 1
//    print("(\(t)) => \(pthread_self())")
    let r = r.getOrCreate(x) {
      Task.detached {
//        print("Starting task for \(x) on thread \(pthread_self())")
        let result = x < 2 ? 1 :
          await self.fib(x - 1).value + self.fib(x - 2).value
//        print("Finishing task for \(x) = \(result)")
        return result
      }
    }
//    print("(\(t)) <= \(pthread_self())")
    return r
  }
}

/*
for kv in (await Comp([2, 10, 15, 6, 20, 91, 4, 5]).result.sorted() { $0.key < $1.key }) {
  print ("\(kv.key): \(kv.value)")
}
*/
