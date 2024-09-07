// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "parallel_dag",
  platforms: [
    .macOS(.v14)
  ],

    dependencies: [
      .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
    ]
 )

// Benchmark of ParallelDAG
package.targets += [
    .executableTarget(
        name: "ParallelDAG",
        dependencies: [
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Benchmarks/ParallelDAG",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]
