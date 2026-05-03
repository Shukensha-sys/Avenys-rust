# Fair Benchmark: Mire vs Rust

- Date: 2026-05-01 10:25:21 UTC
- Warmup: 3
- Repeat: 11
- Timer: wall-clock nanoseconds via date +%s%N (reported as median ms)
- Mire build: ./target/release/mire build (release defaults)
- Rust build flags: -O -C target-cpu=native -C codegen-units=1 -C lto=fat

| Workload | Mire median (ms) | Rust median (ms) | Rust/Mire |
|---|---:|---:|---:|
| sum_loop | 1.941 | 2.110 | 1.087x |
| map_lookup | 20.773 | 37.072 | 1.785x |
| vector_growth_sum | 4.148 | 3.815 | 0.920x |
