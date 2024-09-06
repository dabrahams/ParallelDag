import Benchmark

let benchmarks = {
    Benchmark("Tasks") { benchmark in
      _ = await Tasks([2, 10, 15, 6, 20, 91, 4, 5]).result
    }

    Benchmark("All metrics, full concurrency, async",
              configuration: .init(metrics: BenchmarkMetric.all,
                                   maxDuration: .seconds(10)) { benchmark in
        let _ = await withTaskGroup(of: Void.self, returning: Void.self, body: { taskGroup in
            for _ in 0..<80  {
                taskGroup.addTask {
                    dummyCounter(defaultCounter()*1000)
                }
            }
            for await _ in taskGroup {
            }
        })
    }
}
