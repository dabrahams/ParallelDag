# Parallel DAG computation methods

Here are the results from one run of `swift package benchmark --grouping metric`:

```
Instructions
╒═══════════════════════════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╕
│ Test                          │      p0 │     p25 │     p50 │     p75 │     p90 │     p99 │    p100 │ Samples │
╞═══════════════════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ ParallelDAG:Jaleel (K) *      │     448 │     504 │     522 │     759 │     890 │    1154 │    1528 │    6032 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Operations (K) *  │    3149 │    3889 │    4198 │    4542 │    4915 │    5591 │    6211 │    1809 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Tasks (K) *       │    1576 │    2359 │    2515 │    2654 │    2771 │    2970 │    3258 │    2877 │
╘═══════════════════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╛

Malloc (total)
╒═══════════════════════════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╕
│ Test                          │      p0 │     p25 │     p50 │     p75 │     p90 │     p99 │    p100 │ Samples │
╞═══════════════════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ ParallelDAG:Jaleel *          │      20 │      78 │      92 │     107 │     123 │     177 │     348 │    6032 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Operations *      │     998 │    1033 │    1100 │    1174 │    1206 │    1298 │    1381 │    1809 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Tasks *           │     124 │     427 │     529 │     672 │     835 │    1292 │   18762 │    2877 │
╘═══════════════════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╛

Memory (resident peak)
╒═══════════════════════════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╕
│ Test                          │      p0 │     p25 │     p50 │     p75 │     p90 │     p99 │    p100 │ Samples │
╞═══════════════════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ ParallelDAG:Jaleel (M)        │      10 │      13 │      13 │      13 │      13 │      13 │      13 │    6032 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Operations (M)    │      11 │      19 │      21 │      23 │      26 │      26 │      26 │    1809 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Tasks (M)         │      10 │      14 │      14 │      15 │      15 │      15 │      15 │    2877 │
╘═══════════════════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╛

Throughput (# / s)
╒═══════════════════════════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╕
│ Test                          │      p0 │     p25 │     p50 │     p75 │     p90 │     p99 │    p100 │ Samples │
╞═══════════════════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ ParallelDAG:Jaleel (K)        │      16 │      15 │      15 │      12 │      11 │       7 │       3 │    6032 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Operations (#)    │    4237 │    3205 │    2831 │    2467 │    2099 │    1560 │     339 │    1809 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Tasks (#)         │    5961 │    4351 │    4175 │    3991 │    3783 │    3035 │     392 │    2877 │
╘═══════════════════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╛

Time (total CPU)
╒═══════════════════════════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╕
│ Test                          │      p0 │     p25 │     p50 │     p75 │     p90 │     p99 │    p100 │ Samples │
╞═══════════════════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ ParallelDAG:Jaleel (μs) *     │      68 │      79 │      84 │     118 │     132 │     195 │     411 │    6032 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Operations (μs) * │     340 │     556 │     636 │     757 │     895 │    1241 │    2066 │    1809 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Tasks (μs) *      │     237 │     349 │     374 │     399 │     428 │     526 │     691 │    2877 │
╘═══════════════════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╛

Time (wall clock)
╒═══════════════════════════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╤═════════╕
│ Test                          │      p0 │     p25 │     p50 │     p75 │     p90 │     p99 │    p100 │ Samples │
╞═══════════════════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ ParallelDAG:Jaleel (μs) *     │      62 │      65 │      67 │      86 │      94 │     137 │     294 │    6032 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Operations (μs) * │     236 │     312 │     353 │     406 │     476 │     641 │    2952 │    1809 │
├───────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ParallelDAG:Tasks (μs) *      │     168 │     230 │     240 │     251 │     264 │     329 │    2549 │    2877 │
╘═══════════════════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╛
```
