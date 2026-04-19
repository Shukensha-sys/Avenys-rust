# Mire vs Python Baseline Comparison

This baseline is meant to track runtime and memory work while Mire is still evolving.

## Scope

The comparison is intentionally simple:

- integer loops
- string-heavy output-free work
- collection-heavy state updates
- runtime memory snapshots
- CPU time and estimated cycles
- optional GPU snapshot when supported by the host

It is not a marketing benchmark. It is a repeatable baseline for compiler and runtime work.

## CLI Notes

The practical entrypoint is now `mire` directly.

For normal work, the basic commands are:

- `mire run [file] [options]`
- `mire build [file]`
- `mire new [name]`
- `mire debug [file] [options]`

Benchmark comparisons still live under `mire bench`.

`--compare-python` is only a benchmark helper:

- it runs the compiled `.mire` benchmark
- it runs the matching Python benchmark with `python3`
- it prints both results side by side

It is not a different Python execution mode. Running a Python file normally is still just:

```bash
python3 benchmarks/string_build.py
```

## Benchmarks

Files:

- `benchmarks/sum_loop.mire`
- `benchmarks/sum_loop.py`
- `benchmarks/string_build.mire`
- `benchmarks/string_build.py`
- `benchmarks/collections_stress.mire`
- `benchmarks/collections_stress.py`
- `benchmarks/branchy_workload.mire`
- `benchmarks/branchy_workload.py`
- `benchmarks/map_stress.mire`
- `benchmarks/map_stress.py`
- `benchmarks/vector_stress.mire`
- `benchmarks/vector_stress.py`
- `benchmarks/nested_array_stress.mire`
- `benchmarks/nested_array_stress.py`
- `benchmarks/nested_vector_stress.mire`
- `benchmarks/nested_vector_stress.py`
- `benchmarks/nested_map_stress.mire`
- `benchmarks/nested_map_stress.py`
- `benchmarks/map_vector_stress.mire`
- `benchmarks/map_vector_stress.py`
- `benchmarks/map_lookup_stress.mire`
- `benchmarks/map_lookup_stress.py`
- `benchmarks/map_wide_lookup_stress.mire`
- `benchmarks/map_wide_lookup_stress.py`
- `benchmarks/typed_map_scalar_stress.mire`
- `benchmarks/typed_map_scalar_stress.py`
- `benchmarks/typed_map_mixed_stress.mire`
- `benchmarks/typed_map_mixed_stress.py`
- `benchmarks/typed_vector_bool_stress.mire`
- `benchmarks/typed_vector_bool_stress.py`
- `benchmarks/array_index_stress.mire`
- `benchmarks/array_index_stress.py`

Recommended commands:

```bash
mire run benchmarks/sum_loop.mire
python3 benchmarks/sum_loop.py

mire run benchmarks/string_build.mire
python3 benchmarks/string_build.py

mire run benchmarks/collections_stress.mire
python3 benchmarks/collections_stress.py

mire run benchmarks/branchy_workload.mire
python3 benchmarks/branchy_workload.py

mire run benchmarks/map_stress.mire
python3 benchmarks/map_stress.py

mire run benchmarks/vector_stress.mire
python3 benchmarks/vector_stress.py

mire run benchmarks/nested_array_stress.mire
python3 benchmarks/nested_array_stress.py

mire run benchmarks/nested_vector_stress.mire
python3 benchmarks/nested_vector_stress.py

mire run benchmarks/nested_map_stress.mire
python3 benchmarks/nested_map_stress.py

mire run benchmarks/map_vector_stress.mire
python3 benchmarks/map_vector_stress.py

mire run benchmarks/map_lookup_stress.mire
python3 benchmarks/map_lookup_stress.py

mire run benchmarks/map_wide_lookup_stress.mire
python3 benchmarks/map_wide_lookup_stress.py

mire run benchmarks/typed_map_scalar_stress.mire
python3 benchmarks/typed_map_scalar_stress.py

mire run benchmarks/typed_map_mixed_stress.mire
python3 benchmarks/typed_map_mixed_stress.py

mire run benchmarks/typed_vector_bool_stress.mire
python3 benchmarks/typed_vector_bool_stress.py

mire run benchmarks/array_index_stress.mire
python3 benchmarks/array_index_stress.py
```

Or using the built-in comparison mode:

```bash
mire bench --filter string_build
mire bench --filter string_pipeline_stress
```

## What To Compare

For each benchmark, compare:

- wall-clock time
- process CPU time
- estimated CPU cycles
- final result correctness
- Mire process memory via `mem.process()`
- GPU availability / GPU snapshot when available

## Current Expectation

- Mire should beat Python in tight numeric loops once codegen/runtime dispatch is tightened further.
- The old string-heavy gap is no longer the main blocker after the managed-string append pass.
- `time.mark()` + `time.elapsed_ms()` should be the default timing path inside Mire benchmarks.
- `mem.process()` and `mem.snapshot()` are the default runtime memory probes.
- Collection benchmarks are now split by shape:
  - `map_stress` for `map[str i64]`
  - `vector_stress` for `vec[i64]`
  - `nested_array_stress` for `arr[arr[i64 4] 3]`

## Baseline On 2026-04-09

Measured locally with the compiler binary:

```bash
mire run benchmarks/sum_loop.mire
python3 benchmarks/sum_loop.py

mire run benchmarks/string_build.mire
python3 benchmarks/string_build.py
```

Results after the current runtime/string pass:

- `sum_loop`: Mire `0.033 ms` / `1.83 MB`, Python `132.905 ms` / `11.87 MB`
- `string_build`: Mire `0.504 ms`, Python `15.412 ms`, `30.58x` faster in Mire via `mire bench --filter string_build --repeat 3 --warmup 1`
- `string_pipeline_stress`: Mire `10.564 ms`, Python `40.926 ms`, `3.87x` faster in Mire via `mire bench --filter string_pipeline_stress --repeat 5 --warmup 1`
- `collections_stress`: Mire `1.850 ms wall` / `1.839 ms cpu` / `7,713,009 est cycles` / `1.97 MB`, Python `5.352 ms wall` / `5.298 ms cpu` / `22,459,528 est cycles` / `15.77 MB`
- `map_stress`: Mire `1.224 ms` / `2.29 MB`, Python `3.185 ms` / `60.78 MB`
- `vector_stress`: Mire `0.113 ms` / `2.03 MB`, Python `1.338 ms` / `60.78 MB`
- `nested_array_stress`: Mire `0.032 ms` / `1.84 MB`, Python `0.016 ms` / `60.78 MB`
- `nested_vector_stress`: Mire `0.050 ms` / `1.90 MB`, Python `0.018 ms` / `60.78 MB`
- `nested_map_stress`: Mire `0.039 ms` / `1.77 MB`, Python `0.012 ms` / `60.78 MB`
- `map_vector_stress`: Mire `0.058 ms` / `1.78 MB`, Python `0.013 ms` / `60.78 MB`
- `map_lookup_stress`: Mire `1.202 ms` / `1.77 MB`, Python `18.221 ms` / `60.78 MB`
- `map_wide_lookup_stress`: Mire `2.184 ms` / `1.90 MB`, Python `30.146 ms` / `60.78 MB`
- `typed_map_scalar_stress`: Mire `1.646 ms` / `1.84 MB`, Python `6.162 ms` / `60.78 MB`
- `typed_map_mixed_stress`: Mire `3.047 ms` / `4.29 MB`, Python `16.722 ms` / `60.78 MB`
- `typed_vector_bool_stress`: Mire `0.102 ms` / `1.86 MB`, Python `8.625 ms` / `60.78 MB`
- `typed_vector_i32_stress`: Mire `0.171 ms` / `2.02 MB`, Python `4.334 ms` / `60.78 MB`
- `array_index_stress`: Mire `0.030 ms` / `1.79 MB`, Python `15.285 ms` / `60.78 MB`

Interpretation:

- Mire is now consistently using much less resident memory than Python in the current baseline set.
- Mire is already ahead in `sum_loop`, `collections_stress`, `map_stress`, and `vector_stress`.
- `string_build` is no longer near parity; it is now substantially ahead.
- `string_pipeline_stress` now shows a more visible separation instead of landing near Python.
- `nested_array_stress` is functionally correct and cheap, though Python is still slightly faster in that tiny case.
- `map_lookup_stress` and `array_index_stress` show that the current specialized paths for repeated lookup/index access are already very competitive.
- `map_wide_lookup_stress` is a better stress case for the current hash-backed `map` runtime, and Mire is already substantially ahead there.
- Scalar maps now store keys and values with per-kind stride information, so `map_stress`/`typed_map_*` no longer pad bools/i32s to 8 bytes per slot.
- The benchmark suite is now good enough to expose compiler gaps in indexing, nested containers, and container reassignment as they appear.

## Next Optimization Targets

- reduce cloning in runtime expression evaluation
- reduce repeated hash lookups during member access and builtin dispatch
- avoid eager standard-module initialization
- keep memory/system refresh calls on demand only
- preserve richer element typing for nested `vec[...]`
- continue moving trivial collection/string work from runtime helpers into lowering
- keep shrinking compile time, which is still much larger than runtime on tiny benchmarks
